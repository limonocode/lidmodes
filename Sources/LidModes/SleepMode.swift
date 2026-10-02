import Foundation

enum SleepMode: String, CaseIterable, Identifiable {
    case `default`
    case openLid
    case closedLid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .default: return "Default"
        case .openLid: return "Stay awake"
        case .closedLid: return "Stay awake (lid closed)"
        }
    }

    var detail: String {
        switch self {
        case .default:
            return "Normal sleep (closing the lid sleeps the Mac)."
        case .openLid:
            return "Uses caffeinate while the lid is open."
        case .closedLid:
            return "Experimental. Uses pmset disablesleep. May still sleep; clock/network can glitch. Prefer AC. Not for use in a bag."
        }
    }

    var symbolName: String {
        switch self {
        case .default: return "moon.zzz"
        case .openLid: return "cup.and.saucer.fill"
        case .closedLid: return "laptopcomputer.and.arrow.down"
        }
    }
}
