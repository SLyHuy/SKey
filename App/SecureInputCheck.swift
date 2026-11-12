import AppKit
import Carbon
import Foundation
import IOKit

/// Checks whether macOS Secure Keyboard Entry (SecureEventInput) is active.
///
/// When active (e.g. focused on a password field in Chrome, 1Password, or a secure terminal),
/// macOS stops delivering key events to any CGEventTap for security.
enum SecureInputCheck {
    struct Status: Equatable {
        let isEnabled: Bool
        let pid: pid_t?
        let appName: String?
    }

    static func current() -> Status {
        guard IsSecureEventInputEnabled() else {
            return Status(isEnabled: false, pid: nil, appName: nil)
        }

        var holderPID: pid_t?
        let entry = IORegistryGetRootEntry(kIOMainPortDefault)
        if entry != 0 {
            defer { IOObjectRelease(entry) }
            if let consoleUsers = IORegistryEntryCreateCFProperty(
                entry,
                "IOConsoleUsers" as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue() as? [[String: Any]] {
                for session in consoleUsers {
                    if let onConsole = session["kCGSSessionOnConsoleKey"] as? Bool, onConsole,
                       let pidVal = session["kCGSSessionSecureInputPID"] as? NSNumber {
                        holderPID = pid_t(pidVal.int32Value)
                        break
                    }
                }
            }
        }

        var appName: String?
        if let pid = holderPID {
            if let app = NSRunningApplication(processIdentifier: pid) {
                appName = app.localizedName ?? app.bundleIdentifier ?? "PID \(pid)"
            } else {
                appName = "PID \(pid)"
            }
        }

        return Status(isEnabled: true, pid: holderPID, appName: appName)
    }
}

