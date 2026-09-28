import Carbon
import Foundation

/// A macOS setting that works against SKey, and whether it is currently fine.
struct SystemTip: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let ok: Bool
}

/// Reads the live macOS settings that interfere with an event-tap input method.
enum SystemTips {
    static func current(hotkey: ToggleHotkey) -> [SystemTip] {
        var tips = [
            SystemTip(
                id: "spelling",
                title: "Tắt Correct spelling automatically",
                detail: "macOS có thể \"sửa\" chữ tiếng Việt thành từ tiếng Anh.",
                ok: !globalBool("NSAutomaticSpellingCorrectionEnabled", default: true)
            ),
            SystemTip(
                id: "capitalize",
                title: "Tắt Capitalize words automatically",
                detail: "Tránh tự viết hoa sai khi SKey sửa lại chữ.",
                ok: !globalBool("NSAutomaticCapitalizationEnabled", default: true)
            ),
            SystemTip(
                id: "predictive",
                title: "Tắt Show inline predictive text",
                detail: "Gợi ý chữ xám sau con trỏ có thể nuốt mất chữ SKey gửi vào.",
                ok: !globalBool("NSAutomaticInlinePredictionEnabled", default: true)
            ),
            SystemTip(
                id: "vietnameseIM",
                title: "Xoá Simple Telex khỏi Input Sources",
                detail: "Chỉ giữ ABC. Hai bộ gõ tiếng Việt cùng lúc sẽ gõ chồng lên nhau.",
                ok: !appleVietnameseEnabled()
            ),
        ]
        if let conflict = inputSourceShortcutConflict(hotkey) {
            tips.append(SystemTip(
                id: "shortcut",
                title: "Tắt phím tắt \(conflict) của macOS",
                detail: "Keyboard Shortcuts… → Input Sources: phím này đang dùng để đổi input source, trùng với phím chuyển Vi/En của SKey.",
                ok: false
            ))
        }
        return tips
    }

    static func openKeyboardSettings() -> URL? {
        URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension")
    }

    // MARK: - Readers

    /// Reads a fresh global preference (System Settings may have just changed it).
    private static func globalBool(_ key: String, default defaultValue: Bool) -> Bool {
        CFPreferencesAppSynchronize(kCFPreferencesAnyApplication)
        guard let value = CFPreferencesCopyAppValue(key as CFString, kCFPreferencesAnyApplication) else {
            return defaultValue
        }
        return (value as? Bool) ?? (value as? NSNumber)?.boolValue ?? defaultValue
    }

    private static func appleVietnameseEnabled() -> Bool {
        let filter = [kTISPropertyInputSourceIsEnabled as String: true] as CFDictionary
        guard let list = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] else {
            return false
        }
        return list.contains { source in
            guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return false }
            let id = Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
            return id.hasPrefix("com.apple.inputmethod.VietnameseIM")
        }
    }

    /// Returns the shortcut name if macOS' "select previous/next input source" uses the
    /// same keys as SKey's hotkey (⌥Space or ⌃Space). macOS handles it before SKey sees it.
    private static func inputSourceShortcutConflict(_ hotkey: ToggleHotkey) -> String? {
        let modifier: Int
        switch hotkey {
        case .optionSpace: modifier = 0x80000   // NSEvent option flag
        case .controlSpace: modifier = 0x40000  // NSEvent control flag
        case .controlShift, .optionShift: return nil
        }
        let domain = "com.apple.symbolichotkeys" as CFString
        CFPreferencesAppSynchronize(domain)
        let all = CFPreferencesCopyAppValue("AppleSymbolicHotKeys" as CFString, domain) as? [String: Any] ?? [:]
        // 60 = select previous input source (default ⌃Space), 61 = select next.
        let defaults: [String: (enabled: Bool, params: [Int])] = [
            "60": (true, [32, 49, 0x40000]),
            "61": (true, [32, 49, 0xC0000]),
        ]
        for id in ["60", "61"] {
            var enabled = defaults[id]!.enabled
            var params = defaults[id]!.params
            if let entry = all[id] as? [String: Any] {
                enabled = (entry["enabled"] as? Bool) ?? (entry["enabled"] as? NSNumber)?.boolValue ?? false
                if let value = entry["value"] as? [String: Any], let p = value["parameters"] as? [Int] {
                    params = p
                }
            }
            if enabled, params.count == 3, params[1] == 49, params[2] == modifier {
                return hotkey.symbol
            }
        }
        return nil
    }
}
