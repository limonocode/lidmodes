import Foundation

enum PmsetClient {
    static let installedPath = "/usr/local/libexec/lidmodes-pmset"
    private static let domain = "LidModes"

    static var isBinaryPresent: Bool {
        FileManager.default.isExecutableFile(atPath: installedPath)
    }

    /// True when binary exists and `sudo -n` can run status.
    static func isPasswordlessReady() -> Bool {
        guard isBinaryPresent else { return false }
        return runSudo(verb: "status", capture: false).exitCode == 0
    }

    static func isSleepDisabled() -> Bool {
        let out = shellOutput("/usr/bin/pmset", ["-g"])
        return out.range(of: #"SleepDisabled\s+1"#, options: .regularExpression) != nil
    }

    /// Skip if already matching. `on` / `off` / `restore`.
    static func ensure(verb: String, wantSleepDisabled: Bool?) throws {
        if let want = wantSleepDisabled, isSleepDisabled() == want {
            return
        }
        guard isBinaryPresent else {
            throw err(3, "Passwordless sudo helper not installed. Use Install passwordless sudo.")
        }
        let result = runSudo(verb: verb, capture: true)
        if result.exitCode != 0 {
            let detail = result.stderr.isEmpty ? result.stdout : result.stderr
            throw err(
                1,
                detail.isEmpty
                    ? "sudo -n failed (install passwordless sudo or run scripts/install-nopasswd.sh)."
                    : detail
            )
        }
    }

    /// One-shot admin dialog; then app uses sudo -n only.
    static func runInstallScript() throws {
        let root = projectRootGuess()
        let src = root.appendingPathComponent("bin/lidmodes-pmset").path
        guard FileManager.default.fileExists(atPath: src) else {
            throw err(4, "bin/lidmodes-pmset not found. Set LIDMODES_ROOT or run from repo via scripts/run.sh.")
        }
        let user = NSUserName()
        let escapedSrc = src.replacingOccurrences(of: "'", with: "'\\''")
        let shell = """
        install -d /usr/local/libexec && \
        install -m 755 -o root -g wheel '\(escapedSrc)' \(installedPath) && \
        printf '%s\\n' '# LidModes — NOPASSWD only this binary' '\(user) ALL=(root) NOPASSWD: \(installedPath)' > /tmp/lidmodes-sudoers && \
        visudo -cf /tmp/lidmodes-sudoers && \
        install -m 440 -o root -g wheel /tmp/lidmodes-sudoers /etc/sudoers.d/lidmodes && \
        rm -f /tmp/lidmodes-sudoers
        """
        try runAdminShell(shell)
        guard isPasswordlessReady() else {
            throw err(4, "Install ran but sudo -n is not ready.")
        }
    }

    static func runUninstallScript() throws {
        let shell = """
        \(installedPath) restore 2>/dev/null || true; \
        rm -f /etc/sudoers.d/lidmodes \(installedPath)
        """
        try runAdminShell(shell)
    }

    private static func runAdminShell(_ command: String) throws {
        let escaped = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let source = "do shell script \"\(escaped)\" with administrator privileges"
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw err(2, "Could not create AppleScript for install.")
        }
        script.executeAndReturnError(&error)
        if let error {
            let msg = error[NSAppleScript.errorMessage] as? String ?? "Administrator install failed"
            throw err(1, msg)
        }
    }

    // MARK: - private

    private static func runSudo(verb: String, capture: Bool) -> (exitCode: Int32, stdout: String, stderr: String) {
        shellRun("/usr/bin/sudo", ["-n", installedPath, verb], capture: capture)
    }

    private static func projectRootGuess() -> URL {
        // Prefer env set by run.sh; else walk up from executable / cwd.
        if let env = ProcessInfo.processInfo.environment["LIDMODES_ROOT"], !env.isEmpty {
            return URL(fileURLWithPath: env)
        }
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let marker = cwd.appendingPathComponent("bin/lidmodes-pmset")
        if FileManager.default.fileExists(atPath: marker.path) {
            return cwd
        }
        // .build/release/LidModes → repo root
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

    private static func shellRun(
        _ path: String,
        _ args: [String],
        capture: Bool = true
    ) -> (exitCode: Int32, stdout: String, stderr: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let out = Pipe()
        let err = Pipe()
        if capture {
            p.standardOutput = out
            p.standardError = err
        } else {
            p.standardOutput = FileHandle.nullDevice
            p.standardError = FileHandle.nullDevice
        }
        do {
            try p.run()
            p.waitUntilExit()
        } catch {
            return (127, "", error.localizedDescription)
        }
        let stdout = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (p.terminationStatus, stdout, stderr)
    }
}
