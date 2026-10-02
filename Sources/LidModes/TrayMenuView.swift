import AppKit
import SwiftUI

struct TrayMenuView: View {
    @EnvironmentObject private var sleep: SleepController

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LidModes")
                .font(.headline)
            Text(sleep.statusLine.isEmpty ? "…" : sleep.statusLine)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

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

            Text(sleep.sudoReady ? "Passwordless sudo: ok" : "Passwordless sudo: missing")
                .font(.caption2)
                .foregroundStyle(sleep.sudoReady ? Color.secondary : Color.orange)

            HStack {
                if sleep.sudoReady {
                    Button("Uninstall passwordless sudo") { sleep.uninstallPasswordlessSudo() }
                } else {
                    Button("Install passwordless sudo") { sleep.installPasswordlessSudo() }
                }
            }

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
        .frame(width: 360)
        .onAppear { sleep.refreshStatus() }
    }
}
