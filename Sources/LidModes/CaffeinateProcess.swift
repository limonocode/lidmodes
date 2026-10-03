import Darwin
import Foundation

final class CaffeinateProcess {
    private var process: Process?

    var isRunning: Bool {
        process?.isRunning == true
    }

    func start() throws {
        stop()
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        p.arguments = ["-dims"]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try p.run()
        process = p
    }

    func stop() {
        guard let p = process else { return }
        defer { process = nil }
        guard p.isRunning else { return }
        p.terminate()
        let deadline = Date().addingTimeInterval(1)
        while p.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }
        if p.isRunning {
            kill(p.processIdentifier, SIGKILL)
            p.waitUntilExit()
        }
    }
}
