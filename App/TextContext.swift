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

    /// Bundle ID of the app owning the currently focused UI element, including non-activating
    /// overlays (Spotlight, launchers) that NSWorkspace.frontmostApplication never reports.
    /// Reads only the owning PID — never any text content.
    static func focusedBundleID() -> String? {
        AXUIElementSetMessagingTimeout(systemWide, timeout)
        guard let element: AXUIElement = copy(systemWide, kAXFocusedUIElementAttribute) else { return nil }
        var pid: pid_t = 0
        guard AXUIElementGetPid(element, &pid) == .success, pid != 0 else { return nil }
        return NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
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
