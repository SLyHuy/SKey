import AppKit
import ApplicationServices
import SKeyEngine

/// Reads the text before the caret of the focused text field via the Accessibility API
/// (already granted for the event tap). Used once after the caret moved (click, arrows), so
/// a word typed earlier can be edited. Returns nil when the app does not expose it.
@MainActor
enum TextContext {
    private static let systemWide = AXUIElementCreateSystemWide()
    /// Never hold up typing: an app that does not answer quickly is skipped.
    private static let timeout: Float = 0.05
    /// Read as little as possible: a 7-letter word plus brackets, quotes and spaces.
    private static let lookBehind = TypingSession.contextLength

    private static let spotlightOwnerBundleIDs: Set<String> = [
        AppState.spotlightBundleID,
        "com.apple.campo",
        "com.apple.CampoRemoteService",
    ]

    /// Bundle ID of a non-activating overlay (such as Spotlight) that currently holds keyboard
    /// focus. Checks on-screen floating Spotlight windows first (macOS 27 runs Spotlight inside
    /// `com.apple.campo`, and `AXUIElementCreateSystemWide()` still points at the underlying
    /// frontmost app for non-activating `LSUIElement` panels), then falls back to Accessibility.
    /// Reads only window metadata / owning PID — never any text content.
    static func focusedBundleID() -> String? {
        if isSpotlightWindowOnScreen() {
            return AppState.spotlightBundleID
        }
        AXUIElementSetMessagingTimeout(systemWide, timeout)
        guard let element: AXUIElement = copy(systemWide, kAXFocusedUIElementAttribute) else { return nil }
        var pid: pid_t = 0
        guard AXUIElementGetPid(element, &pid) == .success, pid != 0 else { return nil }
        guard let bundleID = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier else { return nil }
        return spotlightOwnerBundleIDs.contains(bundleID) ? AppState.spotlightBundleID : bundleID
    }

    private static func isSpotlightWindowOnScreen() -> Bool {
        guard let windows = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
        ) as? [[String: Any]] else { return false }

        for window in windows {
            guard let layer = window[kCGWindowLayer as String] as? Int, layer > 0,
                  let alpha = window[kCGWindowAlpha as String] as? Double, alpha > 0.01,
                  let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let width = bounds["Width"] as? Double, width >= 200,
                  let height = bounds["Height"] as? Double, height >= 40,
                  let pid = window[kCGWindowOwnerPID as String] as? pid_t,
                  let bundleID = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
            else { continue }

            if spotlightOwnerBundleIDs.contains(bundleID) {
                return true
            }
        }
        return false
    }

    static func beforeCaret() -> TypingSession.Context? {
        AXUIElementSetMessagingTimeout(systemWide, timeout)
        guard let element: AXUIElement = copy(systemWide, kAXFocusedUIElementAttribute) else { return nil }
        AXUIElementSetMessagingTimeout(element, timeout)

        guard let rangeValue: AXValue = copy(element, kAXSelectedTextRangeAttribute) else { return nil }
        var selection = CFRange()
        guard AXValueGetValue(rangeValue, .cfRange, &selection), selection.length == 0 else { return nil }
        let caret = selection.location

        let start = max(0, caret - lookBehind)
        guard let before = string(element, CFRange(location: start, length: caret - start)) else { return nil }
        let after = string(element, CFRange(location: caret, length: 1)) ?? ""
        return (before, after.first?.isLetter ?? false)
    }

    private static func string(_ element: AXUIElement, _ range: CFRange) -> String? {
        var range = range
        guard let value = AXValueCreate(.cfRange, &range) else { return nil }
        var result: CFTypeRef?
        let error = AXUIElementCopyParameterizedAttributeValue(
            element, kAXStringForRangeParameterizedAttribute as CFString, value, &result)
        guard error == .success else { return nil }
        return result as? String
    }

    private static func copy<T>(_ element: AXUIElement, _ attribute: String) -> T? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value as? T
    }
}
