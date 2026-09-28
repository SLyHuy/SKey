import AppKit
import Observation
import SKeyEngine

struct AppInfo: Equatable {
    let bundleID: String
    let name: String
}

/// User settings (persisted) plus live status shown in the menu.
@MainActor
@Observable
final class AppState {
    private let defaults = UserDefaults.standard

    var isVietnamese: Bool {
        didSet { defaults.set(isVietnamese, forKey: Keys.vietnamese) }
    }
    var hotkey: ToggleHotkey {
        didSet { defaults.set(hotkey.rawValue, forKey: Keys.hotkey) }
    }
    var toneStyle: ToneStyle {
        didSet { defaults.set(toneStyle.rawValue, forKey: Keys.toneStyle) }
    }
    var beepOnToggle: Bool {
        didSet { defaults.set(beepOnToggle, forKey: Keys.beep) }
    }
    /// Work around inline predictions and autocomplete that swallow corrections.
    var fixSuggestions: Bool {
        didSet { defaults.set(fixSuggestions, forKey: Keys.fixSuggestions) }
    }
    /// After a click or arrow keys, read the word before the caret so its marks can change.
    var editPreviousWords: Bool {
        didSet { defaults.set(editPreviousWords, forKey: Keys.editPreviousWords) }
    }
    /// Bundle IDs of apps where SKey always types English.
    var englishApps: [String] {
        didSet { defaults.set(englishApps, forKey: Keys.englishApps) }
    }

    // Live status
    var permissionGranted = false
    /// The last app the user typed in (never SKey itself).
    var frontApp: AppInfo?
    /// Name of a non-layout input source (Apple Vietnamese, Japanese IME…) that is active.
    /// SKey stays out of the way while one is selected.
    var activeInputMethod: String?
    var activeInputMethodIsVietnamese = false
    /// macOS settings shown in the setup guide, refreshed while it is open.
    var systemTips: [SystemTip] = []

    var frontAppIsEnglishOnly: Bool {
        guard let frontApp else { return false }
        return englishApps.contains(frontApp.bundleID)
    }

    /// What the menu bar icon shows.
    var showsVietnamese: Bool { isVietnamese && !frontAppIsEnglishOnly }

    /// Whether keys should go through the Telex engine right now.
    var isComposing: Bool { showsVietnamese && activeInputMethod == nil }

    static let defaultEnglishApps = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "com.mitchellh.ghostty",
        "net.kovidgoyal.kitty",
        "org.alacritty",
        "com.github.wez.wezterm",
    ]

    init() {
        defaults.register(defaults: [
            Keys.vietnamese: true,
            Keys.hotkey: ToggleHotkey.optionSpace.rawValue,
            Keys.toneStyle: ToneStyle.old.rawValue,
            Keys.beep: false,
            Keys.fixSuggestions: true,
            Keys.editPreviousWords: true,
            Keys.englishApps: Self.defaultEnglishApps,
        ])
        isVietnamese = defaults.bool(forKey: Keys.vietnamese)
        hotkey = ToggleHotkey(rawValue: defaults.string(forKey: Keys.hotkey) ?? "") ?? .optionSpace
        toneStyle = ToneStyle(rawValue: defaults.string(forKey: Keys.toneStyle) ?? "") ?? .old
        beepOnToggle = defaults.bool(forKey: Keys.beep)
        fixSuggestions = defaults.bool(forKey: Keys.fixSuggestions)
        editPreviousWords = defaults.bool(forKey: Keys.editPreviousWords)
        englishApps = defaults.stringArray(forKey: Keys.englishApps) ?? Self.defaultEnglishApps
    }

    func setEnglishOnly(_ bundleID: String, _ on: Bool) {
        if on {
            if !englishApps.contains(bundleID) { englishApps.append(bundleID) }
        } else {
            englishApps.removeAll { $0 == bundleID }
        }
    }

    private enum Keys {
        static let vietnamese = "isVietnamese"
        static let hotkey = "toggleHotkey"
        static let toneStyle = "toneStyle"
        static let beep = "beepOnToggle"
        static let fixSuggestions = "fixSuggestions"
        static let editPreviousWords = "editPreviousWords"
        static let englishApps = "englishApps"
    }
}
