import Carbon
import Foundation

/// SKey expects a plain keyboard layout (ABC, US…). When an input method such as Apple's
/// Vietnamese Telex or a Japanese IME is selected, SKey steps aside to avoid double input.
enum InputSourceCheck {
    struct Status {
        /// Name of the selected input method, nil for a plain keyboard layout.
        let inputMethod: String?
        let isAppleVietnamese: Bool
    }

    static func current() -> Status {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return Status(inputMethod: nil, isAppleVietnamese: false)
        }
        let type = property(source, kTISPropertyInputSourceType)
        let id = property(source, kTISPropertyInputSourceID) ?? ""
        guard type != (kTISTypeKeyboardLayout as String) else {
            return Status(inputMethod: nil, isAppleVietnamese: false)
        }
        let name = property(source, kTISPropertyLocalizedName) ?? id
        return Status(inputMethod: name, isAppleVietnamese: id.contains("Vietnamese"))
    }

    /// Calls `handler` on the main thread whenever the selected input source changes.
    /// Uses `.deliverImmediately`: a menu bar app is never "active", and by default macOS
    /// holds distributed notifications for inactive apps until they activate.
    @MainActor
    static func observe(_ handler: @escaping @MainActor () -> Void) -> AnyObject {
        let observer = Observer(handler)
        DistributedNotificationCenter.default().addObserver(
            observer, selector: #selector(Observer.changed),
            name: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil, suspensionBehavior: .deliverImmediately
        )
        return observer
    }

    @MainActor
    private final class Observer: NSObject {
        let handler: @MainActor () -> Void

        init(_ handler: @escaping @MainActor () -> Void) {
            self.handler = handler
        }

        @objc nonisolated func changed() {
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self.handler() }
            }
        }
    }

    private static func property(_ source: TISInputSource, _ key: CFString) -> String? {
        guard let ptr = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }
}
