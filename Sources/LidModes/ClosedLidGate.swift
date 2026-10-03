import Foundation
import LocalAuthentication
import Security

/// Confirms the person at the Mac before lid-closed mode turns on.
/// Touch ID uses LocalAuthentication. Keychain stores a random token
/// (never the account password) and reads it back under a passcode ACL.
enum ClosedLidGate {
    private static let service = "com.lidmodes.closed-lid"
    private static let account = "closed-lid"

    static func authorize(
        _ method: ClosedLidConfirm,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        switch method {
        case .off:
            completion(.success(()))
        case .touchID:
            authorizeTouchID(completion: completion)
        case .keychain:
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try authorizeKeychain()
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    private static func authorizeTouchID(completion: @escaping (Result<Void, Error>) -> Void) {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = ""
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            let message = error?.localizedDescription ?? "Touch ID is not available on this Mac."
            completion(.failure(GateError(message: message)))
            return
        }
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Enable Stay awake (lid closed)"
        ) { ok, evalError in
            if ok {
                completion(.success(()))
            } else {
                let message = evalError?.localizedDescription ?? "Touch ID failed."
                completion(.failure(GateError(message: message)))
            }
        }
    }

    /// Prompt by reading a passcode-protected keychain item.
    /// Creates the item on first use. The stored bytes are random.
    private static func authorizeKeychain() throws {
        let context = LAContext()
        context.localizedReason = "LidModes needs Keychain confirmation to enable lid-closed mode."
        context.interactionNotAllowed = false

        switch try copyToken(context: context) {
        case .confirmed:
            return
        case .missing:
            try addToken()
            switch try copyToken(context: context) {
            case .confirmed:
                return
            case .missing:
                throw GateError(message: "Keychain confirmation item could not be read.")
            }
        }
    }

    private enum CopyResult {
        case confirmed
        case missing
    }

    private static func copyToken(context: LAContext) throws -> CopyResult {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: context,
            kSecUseOperationPrompt as String: "LidModes needs Keychain confirmation to enable lid-closed mode.",
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess {
            return .confirmed
        }
        if status == errSecItemNotFound {
            return .missing
        }
        throw keychainError(status, action: "confirmation")
    }

    private static func addToken() throws {
        guard let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .devicePasscode,
            nil
        ) else {
            throw GateError(message: "Keychain confirmation is unavailable on this Mac.")
        }
        var bytes = [UInt8](repeating: 0, count: 32)
        let random = bytes.withUnsafeMutableBytes { buffer -> OSStatus in
            guard let base = buffer.baseAddress else { return errSecParam }
            return SecRandomCopyBytes(kSecRandomDefault, buffer.count, base)
        }
        guard random == errSecSuccess else {
            throw GateError(message: "Could not generate a Keychain token.")
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrLabel as String: "LidModes lid-closed",
            kSecAttrDescription as String: "Confirms enabling Stay awake (lid closed)",
            kSecAttrAccessControl as String: access,
            kSecValueData as String: Data(bytes),
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            return
        }
        if status != errSecSuccess {
            throw keychainError(status, action: "setup")
        }
    }

    private static func keychainError(_ status: OSStatus, action: String) -> GateError {
        if status == errSecUserCanceled || status == errSecAuthFailed {
            return GateError(message: "Keychain confirmation was canceled.")
        }
        if status == -34018 { // errSecMissingEntitlement
            return GateError(
                message: "Keychain confirmation needs a signed app. Launch with scripts/run.sh, or use Touch ID."
            )
        }
        let message = SecCopyErrorMessageString(status, nil) as String? ?? "OSStatus \(status)"
        return GateError(message: "Keychain \(action) failed: \(message)")
    }
}

struct GateError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
