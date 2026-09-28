import CoreGraphics
import Foundation

@MainActor
protocol KeyboardTapDelegate: AnyObject {
    /// Return true to let the event through, false to swallow it.
    func keyboardTap(_ tap: KeyboardTap, shouldPass event: CGEvent, type: CGEventType) -> Bool
}

/// Owns the CGEventTap and posts synthetic key events. Runs on the main run loop, so the
/// callback executes on the main thread; it must stay fast (no window or app queries).
@MainActor
final class KeyboardTap {
    weak var delegate: KeyboardTapDelegate?

    private var machPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var proxy: CGEventTapProxy?
    private let source = CGEventSource(stateID: .privateState)

    /// Tags our own events so the callback ignores them ("SKEY").
    private static let marker: Int64 = 0x534B_4559

    private static let backspaceKeyCode: CGKeyCode = 51
    /// Key code carried by our text events. Must not be a key the user may still be
    /// holding: with 0 (the "a" key), typing "laf" fast sent our "à" while "a" was still
    /// down, and macOS dropped it. 10 is the ISO "§" key, absent on ANSI keyboards and
    /// never held while typing words.
    private static let textKeyCode: CGKeyCode = 10
    /// CGEventKeyboardSetUnicodeString handles at most 20 UTF-16 units per event.
    private static let maxUnitsPerEvent = 20

    var isRunning: Bool { machPort != nil }

    func start() -> Bool {
        guard machPort == nil else { return true }
        let types: [CGEventType] = [.keyDown, .flagsChanged, .leftMouseDown, .rightMouseDown, .otherMouseDown]
        let mask = types.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { proxy, type, event, refcon in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let tap = Unmanaged<KeyboardTap>.fromOpaque(refcon).takeUnretainedValue()
                let pass = MainActor.assumeIsolated {
                    tap.handle(proxy: proxy, type: type, event: event)
                }
                return pass ? Unmanaged.passUnretained(event) : nil
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }

        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        machPort = port
        runLoopSource = src
        return true
    }

    func stop() {
        guard let port = machPort else { return }
        CGEvent.tapEnable(tap: port, enable: false)
        if let runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes) }
        CFMachPortInvalidate(port)
        machPort = nil
        runLoopSource = nil
        proxy = nil
    }

    private func handle(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Bool {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            // macOS turns the tap off if a callback was too slow; turn it straight back on.
            if let machPort { CGEvent.tapEnable(tap: machPort, enable: true) }
            return true
        default:
            break
        }
        if event.getIntegerValueField(.eventSourceUserData) == Self.marker { return true }
        self.proxy = proxy
        return delegate?.keyboardTap(self, shouldPass: event, type: type) ?? true
    }

    // MARK: - Posting (only valid while handling an event)

    func postBackspaces(_ count: Int) {
        for _ in 0..<count {
            post(keyCode: Self.backspaceKeyCode)
        }
    }

    func postText(_ text: String) {
        let units = Array(text.utf16)
        var start = 0
        while start < units.count {
            let chunk = Array(units[start..<min(start + Self.maxUnitsPerEvent, units.count)])
            for keyDown in [true, false] {
                guard let e = CGEvent(keyboardEventSource: source, virtualKey: Self.textKeyCode, keyDown: keyDown) else { continue }
                e.flags = []
                e.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: chunk)
                send(e)
            }
            start += chunk.count
        }
    }

    /// Re-sends a swallowed event after our edits, keeping the original order.
    func repost(_ event: CGEvent) {
        guard let copy = event.copy() else { return }
        send(copy)
    }

    private func post(keyCode: CGKeyCode) {
        for keyDown in [true, false] {
            guard let e = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown) else { continue }
            e.flags = []
            send(e)
        }
    }

    private func send(_ event: CGEvent) {
        guard let proxy else { return }
        event.setIntegerValueField(.eventSourceUserData, value: Self.marker)
        event.tapPostEvent(proxy)
    }
}
