import Foundation

enum PmsetClient {
    static let installedPath = "/usr/local/libexec/lidmodes-pmset"
    static let snapshotPath = "/usr/local/var/lidmodes/battery-snapshot"
    private static let domain = "LidModes"

    static var isBinaryPresent: Bool {
        FileManager.default.isExecutableFile(atPath: installedPath)
    }

    /// True when the root-owned helper exists and `sudo -n` can run status.
    static func isPasswordlessReady() -> Bool {
        guard isBinaryPresent else { return false }
        return runSudo(verb: "status", capture: true).exitCode == 0
    }

    static func isSleepDisabled() -> Bool {
        let out = shellOutput("/usr/bin/pmset", ["-g"])
        return out.range(of: #"SleepDisabled\s+1"#, options: .regularExpression) != nil
    }

    /// Apply `on` / `off` / `restore`. Uses passwordless sudo when the helper
    /// is installed; otherwise one administrator prompt (Touch ID or password).
    /// `off` and `restore` still run when a battery snapshot is waiting, even
    /// if disablesleep is already 0.
    static func ensure(verb: String, wantSleepDisabled: Bool?) throws {
        switch verb {
        case "on", "off", "restore", "status":
            break
        default:
            throw err(2, "Unsupported pmset verb.")
        }
        let sleepMatches = wantSleepDisabled.map { isSleepDisabled() == $0 } ?? false
        let needsBatteryRestore = (verb == "off" || verb == "restore")
            && FileManager.default.fileExists(atPath: snapshotPath)
        if sleepMatches && !needsBatteryRestore {
            return
        }
        if isPasswordlessReady() {
            let result = runSudo(verb: verb, capture: true)
            if result.exitCode != 0 {
                let detail = result.stderr.isEmpty ? result.stdout : result.stderr
                throw err(
                    1,
                    detail.isEmpty
                        ? "sudo -n failed (turn passwordless sudo on again, or approve the administrator prompt)."
                        : detail
                )
            }
            return
        }
        try runAdminVerb(verb)
    }

    /// One admin password. Installs the helper the user agreed to in settings.
    static func runInstallScript() throws {
        let user = NSUserName()
        try validateUsername(user)
        let script = try bundledScript("scripts/install-nopasswd.sh")
        let command = "LIDMODES_USER=\(shellSingleQuoted(user)) /bin/bash \(shellSingleQuoted(script))"
        try runAdminShell(command)
        guard isPasswordlessReady() else {
            throw err(4, "Install ran but sudo -n is not ready.")
        }
    }

    static func runUninstallScript() throws {
        let script = try bundledScript("scripts/uninstall-nopasswd.sh")
        try runAdminShell("/bin/bash \(shellSingleQuoted(script))")
    }

    // MARK: - private

    private static func runAdminVerb(_ verb: String) throws {
        let command: String
        if isBinaryPresent {
            command = "\(shellSingleQuoted(installedPath)) \(verb)"
        } else {
            let src = try bundledScript("bin/lidmodes-pmset")
            command = "/bin/sh \(shellSingleQuoted(src)) \(verb)"
        }
        try runAdminShell(command)
    }

    private static func validateUsername(_ user: String) throws {
        let ok = user.range(
            of: #"^[A-Za-z_][A-Za-z0-9._-]*$"#,
            options: .regularExpression
        ) != nil
        if !ok {
            throw err(4, "This macOS username cannot be written into sudoers safely.")
        }
    }

    private static func shellSingleQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func bundledScript(_ relative: String) throws -> String {
        let path = projectRootGuess().appendingPathComponent(relative).path
        guard FileManager.default.fileExists(atPath: path) else {
            throw err(4, "\(relative) not found. Set LIDMODES_ROOT or launch with scripts/run.sh.")
        }
        return path
    }

    private static func runAdminShell(_ command: String) throws {
        let escaped = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let source = "do shell script \"\(escaped)\" with administrator privileges"
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw err(2, "Could not create the administrator prompt.")
        }
        script.executeAndReturnError(&error)
        if let error {
            let msg = error[NSAppleScript.errorMessage] as? String ?? "Administrator authorization failed"
            throw err(1, msg)
        }
    }

    private static func runSudo(verb: String, capture: Bool) -> (exitCode: Int32, stdout: String, stderr: String) {
        shellRun("/usr/bin/sudo", ["-n", installedPath, verb], capture: capture)
    }

    private static func projectRootGuess() -> URL {
        if let env = ProcessInfo.processInfo.environment["LIDMODES_ROOT"], !env.isEmpty {
            return URL(fileURLWithPath: env)
        }
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let marker = cwd.appendingPathComponent("bin/lidmodes-pmset")
        if FileManager.default.fileExists(atPath: marker.path) {
            return cwd
        }
        if let exe = Bundle.main.executableURL {
            var url = exe.deletingLastPathComponent()
            for _ in 0..<6 {
                if FileManager.default.fileExists(atPath: url.appendingPathComponent("bin/lidmodes-pmset").path) {
                    return url
                }
                url = url.deletingLastPathComponent()
            }
        }
        return cwd
    }

    private static func err(_ code: Int, _ message: String) -> NSError {
        NSError(domain: domain, code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private static func shellOutput(_ path: String, _ args: [String]) -> String {
        shellRun(path, args).stdout
    }

    /// `capture == false` must not read an unused Pipe. That read waits for
    /// EOF on a write-end the process never holds, so the app hangs forever.
    private static func shellRun(
        _ path: String,
        _ args: [String],
        capture: Bool = true
    ) -> (exitCode: Int32, stdout: String, stderr: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let out = capture ? Pipe() : nil
        let errPipe = capture ? Pipe() : nil
        p.standardOutput = out ?? FileHandle.nullDevice
        p.standardError = errPipe ?? FileHandle.nullDevice
        do {
            try p.run()
            p.waitUntilExit()
        } catch {
            return (127, "", error.localizedDescription)
        }
        guard capture, let out, let errPipe else {
            return (p.terminationStatus, "", "")
        }
        let stdout = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (p.terminationStatus, stdout, stderr)
    }
}
