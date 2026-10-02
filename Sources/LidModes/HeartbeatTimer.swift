import AppKit
import Foundation

@MainActor
final class HeartbeatTimer {
    private var timer: Timer?
    var isActive: Bool { timer != nil }

    func start() {
        stop()
        let t = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            NSSound(named: NSSound.Name("Tink"))?.play()
        }
        // First fire after 5 minutes (scheduledTimer fires after interval when repeats).
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
