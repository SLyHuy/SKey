import CoreGraphics

/// Shortcut that switches between Vietnamese and English.
enum ToggleHotkey: String, CaseIterable, Identifiable {
    case optionSpace
    case controlSpace
    case controlShift
    case optionShift

    var id: String { rawValue }

    var title: String {
        switch self {
        case .optionSpace: "⌥ Space"
        case .controlSpace: "⌃ Space"
        case .controlShift: "⌃ ⇧ (nhấn rồi thả)"
        case .optionShift: "⌥ ⇧ (nhấn rồi thả)"
        }
    }

    /// Short form for the menu title.
    var symbol: String {
        switch self {
        case .optionSpace: "⌥Space"
        case .controlSpace: "⌃Space"
        case .controlShift: "⌃⇧"
        case .optionShift: "⌥⇧"
        }
    }

    static let modifierMask: CGEventFlags = [.maskShift, .maskControl, .maskAlternate, .maskCommand]
    private static let spaceKeyCode: Int64 = 49

    func matchesKeyDown(keyCode: Int64, flags: CGEventFlags) -> Bool {
        let mods = flags.intersection(Self.modifierMask)
        switch self {
        case .optionSpace: return keyCode == Self.spaceKeyCode && mods == .maskAlternate
        case .controlSpace: return keyCode == Self.spaceKeyCode && mods == .maskControl
        case .controlShift, .optionShift: return false
        }
    }

    /// Modifiers of a press-and-release chord, or nil for key shortcuts.
    var chord: CGEventFlags? {
        switch self {
        case .controlShift: [.maskControl, .maskShift]
        case .optionShift: [.maskAlternate, .maskShift]
        case .optionSpace, .controlSpace: nil
        }
    }
}

/// Detects a modifier-only chord (e.g. ⌃⇧): fires when all modifiers are released
/// without any other key or modifier in between, so ⌃⇧K and friends never toggle.
struct ModifierChord {
    private var armed = false

    mutating func flagsChanged(_ flags: CGEventFlags, target: CGEventFlags) -> Bool {
        let mods = flags.intersection(ToggleHotkey.modifierMask)
        if mods == target {
            armed = true
        } else if mods.isEmpty {
            defer { armed = false }
            return armed
        } else if !target.contains(mods) {
            armed = false
        }
        return false
    }

    mutating func cancel() {
        armed = false
    }
}
