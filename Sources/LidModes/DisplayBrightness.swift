import Foundation
import IOKit

/// Best-effort built-in display brightness via IOKit. No sudo.
enum DisplayBrightness {
    private static let savedKey = "lidmodes.savedBrightness"
    private static var saved: Float? = loadSaved()

    private static let brightnessKey = "brightness" as CFString

    static var isDimmed: Bool { saved != nil }

    static func dimToZeroSavingPrevious() {
        if saved == nil {
            guard let current = readBrightness() else { return }
            saved = current
            persist()
        }
        _ = writeBrightness(0)
    }

    static func restoreIfNeeded() {
        guard let value = saved else { return }
        if writeBrightness(value) {
            saved = nil
            persist()
        }
    }

    private static func loadSaved() -> Float? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: savedKey) != nil else { return nil }
        return defaults.float(forKey: savedKey)
    }

    private static func persist() {
        if let saved {
            UserDefaults.standard.set(saved, forKey: savedKey)
        } else {
            UserDefaults.standard.removeObject(forKey: savedKey)
        }
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
        let clamped = max(0, min(1, value))
        let wrote = withDisplayService { service -> Bool? in
            let err = IODisplaySetFloatParameter(service, 0, brightnessKey, clamped)
            // nil keeps walking displays; false would stop on the first failure.
            return err == KERN_SUCCESS ? true : nil
        }
        return wrote == true
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
