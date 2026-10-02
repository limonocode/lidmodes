import Foundation
import IOKit

/// Best-effort built-in display brightness via IOKit. No sudo.
enum DisplayBrightness {
    private static var saved: Float?

    private static let brightnessKey = "brightness" as CFString

    static var isDimmed: Bool { saved != nil }

    static func dimToZeroSavingPrevious() {
        guard saved == nil else { return }
        guard let current = readBrightness() else { return }
        saved = current
        _ = writeBrightness(0)
    }

    static func restoreIfNeeded() {
        guard let value = saved else { return }
        _ = writeBrightness(value)
        saved = nil
    }

    // MARK: - IOKit

    private static func readBrightness() -> Float? {
        withDisplayService { service in
            var brightness: Float = 0
            let err = IODisplayGetFloatParameter(service, 0, brightnessKey, &brightness)
            return err == KERN_SUCCESS ? brightness : nil
        }
    }

    private static func writeBrightness(_ value: Float) -> Bool {
        withDisplayService { service in
            let clamped = max(0, min(1, value))
            let err = IODisplaySetFloatParameter(service, 0, brightnessKey, clamped)
            return err == KERN_SUCCESS
        } ?? false
    }

    private static func withDisplayService<T>(_ body: (io_service_t) -> T?) -> T? {
        var iterator: io_iterator_t = 0
        defer {
            if iterator != 0 { IOObjectRelease(iterator) }
        }
        let matching = IOServiceMatching("IODisplayConnect")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS
        else { return nil }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            if let result = body(service) {
                IOObjectRelease(service)
                return result
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
        return nil
    }
}
