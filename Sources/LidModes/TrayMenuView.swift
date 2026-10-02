import AppKit
import SwiftUI

struct TrayMenuView: View {
    @EnvironmentObject private var sleep: SleepController

    private let passwordlessRules = """
    Checking this enters your password once. LidModes installs a root-owned helper at /usr/local/libexec/lidmodes-pmset and a sudoers rule for your user only. The helper accepts on, off, restore, and status — nothing else. Any program on this Mac can run that helper without a password. Uncheck to remove both files.
    """

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LidModes")
                .font(.headline)
            Text(sleep.statusLine.isEmpty ? "…" : sleep.statusLine)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            ForEach(SleepMode.allCases) { mode in
                Button {
                    sleep.select(mode)
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: mode == sleep.mode ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(mode == sleep.mode ? .orange : .secondary)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.title)
                                .foregroundStyle(.primary)
                            Text(mode.detail)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Divider()

            Toggle("AC Safety Lock", isOn: $sleep.acSafety)
            Toggle("Heartbeat click (5 min)", isOn: $sleep.heartbeatEnabled)

            Divider()

            Text("Turn on lid-closed")
                .font(.subheadline)
            ForEach(ClosedLidConfirm.allCases) { method in
                Button {
                    sleep.closedLidConfirm = method
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: method == sleep.closedLidConfirm ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(method == sleep.closedLidConfirm ? .orange : .secondary)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(method.title)
                                .foregroundStyle(.primary)
                            Text(method.detail)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            Text(confirmHint)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let confirmStatus = sleep.confirmStatus {
                Text(confirmStatus)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Divider()

            Text("Passwordless helper")
                .font(.subheadline)
            Text(passwordlessRules)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Toggle(isOn: Binding(
                get: { sleep.sudoReady },
                set: { sleep.setPasswordless($0) }
            )) {
                Text(sleep.sudoReady ? "Passwordless sudo is on" : "I agree — passwordless sudo")
            }
            .toggleStyle(.checkbox)
            Text(sleep.sudoReady ? "Passwordless sudo: ok" : "Passwordless sudo: missing")
                .font(.caption2)
                .foregroundStyle(sleep.sudoReady ? Color.secondary : Color.orange)

            if let err = sleep.lastError {
                Divider()
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            HStack {
                Button("Refresh") { sleep.refreshStatus() }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(12)
        .frame(width: 380)
        .onAppear { sleep.refreshStatus() }
    }

    private var confirmHint: String {
        switch sleep.closedLidConfirm {
        case .off:
            return sleep.sudoReady
                ? "Lid-closed switches as soon as you choose it."
                : "macOS asks for an administrator password or Touch ID whenever power settings change."
        case .touchID:
            return sleep.sudoReady
                ? "Touch ID confirms it is you, then the helper changes power settings."
                : "Touch ID confirms it is you. macOS then asks to change power settings."
        case .keychain:
            return sleep.sudoReady
                ? "Keychain confirms it is you, then the helper changes power settings."
                : "Keychain confirms it is you. macOS then asks to change power settings."
        }
    }
}
