import AppKit
import SwiftUI

@main
struct LidModesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var sleep = SleepController.shared

    var body: some Scene {
        MenuBarExtra {
            TrayMenuView()
                .environmentObject(sleep)
        } label: {
            Image(systemName: sleep.mode.symbolName)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        let sem = DispatchSemaphore(value: 0)
        Task { @MainActor in
            SleepController.shared.prepareForTermination()
            sem.signal()
        }
        _ = sem.wait(timeout: .now() + 2)
    }
}
