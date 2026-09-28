import Foundation

enum Mod: UInt8, Sendable {
    case none
    case circumflex  // â ê ô
    case breve       // ă
    case horn        // ơ ư
    case stroke      // đ
}

enum Tone: Int, Sendable, CaseIterable {
    case none, acute, grave, hook, tilde, dot

    /// Telex key for each tone: s f r x j.
    init?(key: Character) {
        switch key {
        case "s": self = .acute
        case "f": self = .grave
        case "r": self = .hook
        case "x": self = .tilde
        case "j": self = .dot
        default: return nil
        }
    }

    var key: Character? {
        switch self {
        case .none: nil
        case .acute: "s"
        case .grave: "f"
        case .hook: "r"
        case .tilde: "x"
        case .dot: "j"
        }
    }
}

/// One character of the word being composed. `base` is a lowercase ASCII letter,
/// or any other character kept verbatim (digits, punctuation, …).
struct Letter: Equatable, Sendable {
    var base: Character
    var upper: Bool
    var mod: Mod = .none

    init(base: Character, upper: Bool, mod: Mod = .none) {
        self.base = base
        self.upper = upper
        self.mod = mod
    }

    init(key: Character) {
        if key.isASCII, key.isLetter {
            base = Character(key.lowercased())
            upper = key.isUppercase
        } else {
            base = key
            upper = false
        }
    }

    var isASCIILetter: Bool { base.isASCII && base.isLetter }
    var isVowel: Bool { Self.vowels.contains(base) }

    private static let vowels: Set<Character> = ["a", "e", "i", "o", "u", "y"]
}

/// Precomposed Vietnamese vowels, indexed by base + modifier, then tone.
enum VietChars {
    private static let rows: [(base: Character, mod: Mod, chars: String)] = [
        ("a", .none, "aáàảãạ"), ("a", .breve, "ăắằẳẵặ"), ("a", .circumflex, "âấầẩẫậ"),
        ("e", .none, "eéèẻẽẹ"), ("e", .circumflex, "êếềểễệ"),
        ("i", .none, "iíìỉĩị"),
        ("o", .none, "oóòỏõọ"), ("o", .circumflex, "ôốồổỗộ"), ("o", .horn, "ơớờởỡợ"),
        ("u", .none, "uúùủũụ"), ("u", .horn, "ưứừửữự"),
        ("y", .none, "yýỳỷỹỵ"),
    ]

    private struct Key: Hashable {
        let base: Character
        let mod: Mod
    }

    private static let table: [Key: [Character]] = {
        var t: [Key: [Character]] = [:]
        for row in rows {
            t[Key(base: row.base, mod: row.mod)] = Array(row.chars.precomposedStringWithCanonicalMapping)
        }
        return t
    }()

    private static let reverse: [Character: (base: Character, mod: Mod, tone: Tone)] = {
        var r: [Character: (Character, Mod, Tone)] = [:]
        for (key, chars) in table {
            for (i, c) in chars.enumerated() {
                r[c] = (key.base, key.mod, Tone(rawValue: i)!)
            }
        }
        return r
    }()

    static func render(_ letter: Letter, tone: Tone) -> String {
        let c: Character
        if letter.base == "d", letter.mod == .stroke {
            c = "đ"
        } else if let chars = table[Key(base: letter.base, mod: letter.mod)] {
            c = chars[tone.rawValue]
        } else {
            c = letter.base
        }
        return letter.upper ? c.uppercased() : String(c)
    }

    /// Splits a lowercase precomposed vowel into base, modifier and tone.
    static func decompose(_ c: Character) -> (base: Character, mod: Mod, tone: Tone)? {
        reverse[c]
    }
}
