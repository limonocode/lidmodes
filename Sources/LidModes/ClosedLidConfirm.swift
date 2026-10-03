import Foundation

/// Extra confirmation before Stay awake (lid closed) turns on.
/// Turning the mode off never asks, so sleep can be restored unattended.
enum ClosedLidConfirm: String, CaseIterable, Identifiable {
    case off
    case touchID
    case keychain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off: return "Click only"
        case .touchID: return "Touch ID"
        case .keychain: return "Keychain"
        }
    }

    var detail: String {
        switch self {
        case .off:
            return "No extra confirmation in LidModes."
        case .touchID:
            return "Fingerprint confirms it is you before lid-closed turns on."
        case .keychain:
            return "Keychain asks for your password before lid-closed turns on."
        }
    }
}
