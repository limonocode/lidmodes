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
        // A semaphore here would block the main actor, so cleanup would never run.
        let cleanup = {
            MainActor.assumeIsolated {
                SleepController.shared.prepareForTermination()
            }
        }
        if Thread.isMainThread {
            cleanup()
        } else {
            DispatchQueue.main.sync(execute: cleanup)
        }
    }
}
