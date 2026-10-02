import AppKit
import Foundation

@MainActor
final class SleepController: ObservableObject {
    static let shared = SleepController()

    @Published private(set) var mode: SleepMode = .default
    @Published private(set) var statusLine: String = ""
    @Published private(set) var lastError: String?
    @Published private(set) var confirmStatus: String?
    @Published var acSafety: Bool {
        didSet {
            guard didFinishInit else { return }
            UserDefaults.standard.set(acSafety, forKey: Keys.acSafety)
            if acSafety { checkACSafety() }
        }
    }
    @Published var heartbeatEnabled: Bool {
        didSet {
            guard didFinishInit else { return }
            UserDefaults.standard.set(heartbeatEnabled, forKey: Keys.heartbeat)
            syncHeartbeat()
        }
    }
    @Published var closedLidConfirm: ClosedLidConfirm {
        didSet {
            guard didFinishInit else { return }
            UserDefaults.standard.set(closedLidConfirm.rawValue, forKey: Keys.confirm)
        }
    }
    @Published private(set) var sudoReady: Bool = false

    private let caffeinate = CaffeinateProcess()
    private let heartbeat = HeartbeatTimer()
    private var powerTimer: Timer?
    private var didFinishInit = false
    private var authInFlight = false
    /// After the user dismisses an unattended restore prompt, don't ask every 5s.
    private var declinedInteractiveRestore = false

    private enum Keys {
        static let mode = "lidmodes.mode"
        static let legacyMode = "mac.tray.sleep.mode"
        static let acSafety = "lidmodes.acSafety"
        static let heartbeat = "lidmodes.heartbeat"
        static let confirm = "lidmodes.closedLidConfirm"
    }

    init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Keys.acSafety) == nil {
            defaults.set(true, forKey: Keys.acSafety)
        }
        if defaults.object(forKey: Keys.heartbeat) == nil {
            defaults.set(true, forKey: Keys.heartbeat)
        }
        acSafety = defaults.bool(forKey: Keys.acSafety)
        heartbeatEnabled = defaults.bool(forKey: Keys.heartbeat)
        let confirmRaw = defaults.string(forKey: Keys.confirm) ?? ClosedLidConfirm.off.rawValue
        closedLidConfirm = ClosedLidConfirm(rawValue: confirmRaw) ?? .off

        let raw = defaults.string(forKey: Keys.mode)
            ?? defaults.string(forKey: Keys.legacyMode)
            ?? SleepMode.default.rawValue
        mode = SleepMode(rawValue: raw) ?? .default
        didFinishInit = true

        sudoReady = PmsetClient.isPasswordlessReady()
        bootstrap()
        startPowerWatch()
        if mode == .closedLid, acSafety, !PowerMonitor.onAC {
            apply(.default, persist: true, notice: "Unplugged — restored Default (AC Safety).")
        }
    }

    func select(_ next: SleepMode) {
        declinedInteractiveRestore = false
        guard next == .closedLid, next != mode, closedLidConfirm != .off else {
            apply(next, persist: true)
            return
        }
        guard !authInFlight else { return }
        authInFlight = true
        confirmStatus = closedLidConfirm == .touchID ? "Waiting for Touch ID…" : "Waiting for Keychain…"
        let method = closedLidConfirm
        ClosedLidGate.authorize(method) { result in
            Task { @MainActor in
                self.authInFlight = false
                self.confirmStatus = nil
                switch result {
                case .success:
                    self.apply(next, persist: true)
                case .failure(let error):
                    self.lastError = error.localizedDescription
                    self.statusLine = self.livePowerSummary()
                }
            }
        }
    }

    func refreshStatus() {
        declinedInteractiveRestore = false
        sudoReady = PmsetClient.isPasswordlessReady()
        statusLine = livePowerSummary()
        checkACSafety()
    }

    /// Checkbox in the menu: on means the user agrees to the passwordless rules
    /// and enters an admin password once. Off removes the helper and sudoers.
    func setPasswordless(_ enabled: Bool) {
        guard enabled != sudoReady else { return }
        declinedInteractiveRestore = false
        if enabled {
            installPasswordlessSudo()
        } else {
            uninstallPasswordlessSudo()
        }
    }

    func installPasswordlessSudo() {
        lastError = nil
        do {
            try PmsetClient.runInstallScript()
            sudoReady = PmsetClient.isPasswordlessReady()
            statusLine = livePowerSummary()
            if !sudoReady {
                lastError = "Install finished but sudo -n is not ready."
            }
        } catch {
            sudoReady = PmsetClient.isPasswordlessReady()
            lastError = error.localizedDescription
            statusLine = livePowerSummary()
        }
    }

    func uninstallPasswordlessSudo() {
        lastError = nil
        do {
            if mode == .closedLid {
                try transition(to: .default)
                mode = .default
                syncHeartbeat()
                UserDefaults.standard.set(mode.rawValue, forKey: Keys.mode)
            }
            try PmsetClient.runUninstallScript()
            sudoReady = false
            statusLine = livePowerSummary()
        } catch {
            sudoReady = PmsetClient.isPasswordlessReady()
            lastError = error.localizedDescription
            statusLine = livePowerSummary()
        }
    }

    /// Call on app quit: leave the machine in a safe Default-like power state.
    /// Does not ask for Touch ID or Keychain, so a quit can still restore sleep.
    func prepareForTermination() {
        heartbeat.stop()
        DisplayBrightness.restoreIfNeeded()
        caffeinate.stop()
        if mode == .closedLid || PmsetClient.isSleepDisabled() {
            try? PmsetClient.ensure(verb: "restore", wantSleepDisabled: false)
        }
    }

    // MARK: - Apply

    private func bootstrap() {
        lastError = nil
        if mode != .closedLid {
            DisplayBrightness.restoreIfNeeded()
        }
        switch mode {
        case .openLid:
            do { try caffeinate.start() } catch { lastError = error.localizedDescription }
        case .closedLid:
            if !PmsetClient.isSleepDisabled() {
                lastError = "Lid-closed was saved but SleepDisabled=0. Select it again to turn it back on."
            } else {
                do {
                    try caffeinate.start()
                    DisplayBrightness.dimToZeroSavingPrevious()
                    syncHeartbeat()
                } catch {
                    lastError = error.localizedDescription
                }
            }
        case .default:
            caffeinate.stop()
        }
        statusLine = livePowerSummary()
    }

    private func apply(_ next: SleepMode, persist: Bool, notice: String? = nil) {
        lastError = nil
        do {
            try transition(to: next)
            mode = next
            syncHeartbeat()
            if persist {
                UserDefaults.standard.set(mode.rawValue, forKey: Keys.mode)
            }
            if let notice {
                lastError = notice
            }
            sudoReady = PmsetClient.isPasswordlessReady()
            statusLine = livePowerSummary()
        } catch {
            if mode == .closedLid {
                DisplayBrightness.dimToZeroSavingPrevious()
            }
            syncHeartbeat()
            lastError = error.localizedDescription
            statusLine = livePowerSummary()
        }
    }

    private func transition(to next: SleepMode) throws {
        switch next {
        case .closedLid:
            if acSafety && !PowerMonitor.onAC {
                throw NSError(
                    domain: "LidModes",
                    code: 10,
                    userInfo: [NSLocalizedDescriptionKey: "AC Safety: plug in power for lid-closed mode."]
                )
            }
            try PmsetClient.ensure(verb: "on", wantSleepDisabled: true)
            do {
                try caffeinate.start()
            } catch {
                try? PmsetClient.ensure(verb: "restore", wantSleepDisabled: false)
                throw error
            }
            DisplayBrightness.dimToZeroSavingPrevious()

        case .openLid:
            heartbeat.stop()
            DisplayBrightness.restoreIfNeeded()
            try PmsetClient.ensure(verb: "off", wantSleepDisabled: false)
            try caffeinate.start()

        case .default:
            heartbeat.stop()
            DisplayBrightness.restoreIfNeeded()
            caffeinate.stop()
            try PmsetClient.ensure(verb: "restore", wantSleepDisabled: false)
        }
    }

    private func syncHeartbeat() {
        if mode == .closedLid && heartbeatEnabled {
            heartbeat.start()
        } else {
            heartbeat.stop()
        }
    }

    private func startPowerWatch() {
        powerTimer?.invalidate()
        powerTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkACSafety()
            }
        }
        if let powerTimer {
            RunLoop.main.add(powerTimer, forMode: .common)
        }
    }

    private func checkACSafety() {
        if authInFlight { return }
        guard mode == .closedLid, acSafety, !PowerMonitor.onAC else { return }
        if declinedInteractiveRestore && !PmsetClient.isPasswordlessReady() {
            return
        }
        apply(.default, persist: true, notice: "Unplugged — restored Default (AC Safety).")
        if mode == .closedLid && !PmsetClient.isPasswordlessReady() {
            declinedInteractiveRestore = true
            if lastError == nil {
                lastError = "Unplugged. Choose Default and approve the prompt to turn sleep back on."
            }
        } else {
            declinedInteractiveRestore = false
        }
    }

    private func livePowerSummary() -> String {
        let sleepDisabled = PmsetClient.isSleepDisabled()
        let caffOn = caffeinate.isRunning
        let dim = DisplayBrightness.isDimmed ? "on" : "off"
        let beat = heartbeat.isActive ? "on" : "off"
        let sudo = sudoReady ? "ok" : "missing"
        return "SleepDisabled=\(sleepDisabled ? "1" : "0") · caffeinate=\(caffOn ? "on" : "off") · power=\(PowerMonitor.label) · dim=\(dim) · beat=\(beat) · sudo=\(sudo)"
    }
}
