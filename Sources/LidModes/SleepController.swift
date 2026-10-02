import AppKit
import Foundation

@MainActor
final class SleepController: ObservableObject {
    static let shared = SleepController()

    @Published private(set) var mode: SleepMode
    @Published private(set) var statusLine: String = ""
    @Published private(set) var lastError: String?
    @Published var acSafety: Bool {
        didSet { UserDefaults.standard.set(acSafety, forKey: Keys.acSafety) }
    }
    @Published var heartbeatEnabled: Bool {
        didSet {
            UserDefaults.standard.set(heartbeatEnabled, forKey: Keys.heartbeat)
            syncHeartbeat()
        }
    }
    @Published private(set) var sudoReady: Bool = false

    private let caffeinate = CaffeinateProcess()
    private let heartbeat = HeartbeatTimer()
    private var powerTimer: Timer?

    private enum Keys {
        static let mode = "lidmodes.mode"
        static let legacyMode = "mac.tray.sleep.mode"
        static let acSafety = "lidmodes.acSafety"
        static let heartbeat = "lidmodes.heartbeat"
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

        let raw = defaults.string(forKey: Keys.mode)
            ?? defaults.string(forKey: Keys.legacyMode)
            ?? SleepMode.default.rawValue
        mode = SleepMode(rawValue: raw) ?? .default

        sudoReady = PmsetClient.isPasswordlessReady()
        bootstrap()
        startPowerWatch()
    }

    func select(_ next: SleepMode) {
        apply(next, persist: true)
    }

    func refreshStatus() {
        sudoReady = PmsetClient.isPasswordlessReady()
        statusLine = livePowerSummary()
    }

    func installPasswordlessSudo() {
        lastError = nil
        do {
            try PmsetClient.runInstallScript()
            sudoReady = PmsetClient.isPasswordlessReady()
            statusLine = livePowerSummary()
            if !sudoReady {
                lastError = "Install finished but sudo -n is not ready. Check Terminal output."
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func uninstallPasswordlessSudo() {
        lastError = nil
        do {
            if mode == .closedLid {
                apply(.default, persist: true)
            }
            try PmsetClient.runUninstallScript()
            sudoReady = false
            statusLine = livePowerSummary()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Call on app quit: leave machine in a safe Default-like power state.
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
        switch mode {
        case .openLid:
            do { try caffeinate.start() } catch { lastError = error.localizedDescription }
        case .closedLid:
            if !PmsetClient.isSleepDisabled() {
                lastError = "Lid-closed was saved but SleepDisabled=0. Select it again after Install passwordless sudo."
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

    private func apply(_ next: SleepMode, persist: Bool) {
        lastError = nil
        do {
            switch next {
            case .closedLid:
                if acSafety && !PowerMonitor.onAC {
                    throw NSError(
                        domain: "LidModes",
                        code: 10,
                        userInfo: [NSLocalizedDescriptionKey: "AC Safety: plug in power for lid-closed mode."]
                    )
                }
                if !PmsetClient.isPasswordlessReady() {
                    throw NSError(
                        domain: "LidModes",
                        code: 11,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Passwordless sudo helper missing. Use Install passwordless sudo (one-time).",
                        ]
                    )
                }
                try PmsetClient.ensure(verb: "on", wantSleepDisabled: true)
                try caffeinate.start()
                DisplayBrightness.dimToZeroSavingPrevious()
                mode = next
                syncHeartbeat()

            case .openLid:
                heartbeat.stop()
                DisplayBrightness.restoreIfNeeded()
                try PmsetClient.ensure(verb: "off", wantSleepDisabled: false)
                try caffeinate.start()
                mode = next

            case .default:
                heartbeat.stop()
                DisplayBrightness.restoreIfNeeded()
                caffeinate.stop()
                try PmsetClient.ensure(verb: "restore", wantSleepDisabled: false)
                mode = next
            }

            if persist {
                UserDefaults.standard.set(mode.rawValue, forKey: Keys.mode)
            }
            sudoReady = PmsetClient.isPasswordlessReady()
            statusLine = livePowerSummary()
        } catch {
            lastError = error.localizedDescription
            statusLine = livePowerSummary()
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
        guard mode == .closedLid, acSafety, !PowerMonitor.onAC else {
            statusLine = livePowerSummary()
            return
        }
        lastError = "Unplugged — restored Default (AC Safety)."
        apply(.default, persist: true)
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
