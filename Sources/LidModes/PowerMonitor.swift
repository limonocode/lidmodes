import Foundation
import IOKit.ps

enum PowerMonitor {
    /// True when the Mac itself is on AC. Bluetooth mice and keyboards are
    /// ignored so a Magic Mouse does not look like the laptop is unplugged.
    static var onAC: Bool {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else {
            return false
        }

        var sawInternal = false
        var internalAC = false
        var anyAC = false
        for src in list {
            guard let desc = IOPSGetPowerSourceDescription(info, src)?.takeUnretainedValue() as? [String: Any]
            else { continue }
            let onAdapter = (desc[kIOPSPowerSourceStateKey] as? String) == (kIOPSACPowerValue as String)
            if onAdapter { anyAC = true }
            if isMachineSource(desc) {
                sawInternal = true
                if onAdapter { internalAC = true }
            }
        }
        if sawInternal { return internalAC }
        return anyAC
    }

    private static func isMachineSource(_ desc: [String: Any]) -> Bool {
        if let transport = desc[kIOPSTransportTypeKey] as? String {
            return transport == (kIOPSInternalType as String)
        }
        let type = desc[kIOPSTypeKey] as? String
        return type == (kIOPSInternalBatteryType as String)
    }

    static var label: String { onAC ? "AC" : "Battery" }
}
