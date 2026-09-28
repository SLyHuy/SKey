/// Telex composer for one word at a time.
///
/// The engine keeps the raw keys of the current word and recomposes the whole word from
/// scratch on every key, so there is no incremental state to drift out of sync. Each call
/// returns the `Edit` that turns what is on screen into the new text.
///
/// Rules:
/// - A Telex key only transforms the word if the result can still be Vietnamese, so words
///   that can never be Vietnamese (class, function, window, useState) stay as typed.
/// - Nothing is ever corrected afterwards: what is on screen stays, so a typo ("tân" + k)
///   is fixed with Backspace, and the word end never rewrites anything.
/// - Typing a transform key again (ss, xx, aa, ww, dd…) removes that mark and types the key
///   as a letter, like Unikey: nẽ + x → nex, serrver → server, usser → user, đi + d → did.
/// - Marks may come late: circumflex after the final consonant (hienej → hiện), đ from a
///   later d (dodongj → động), tone last.
public struct TelexEngine: Sendable {
    public var toneStyle: ToneStyle

    /// The current word as it appears on screen.
    public private(set) var text = ""

    private var keys: [Character] = []
    private var startRaw = false

    // Composition state, rebuilt from `keys` by `compose()`.
    private var letters: [Letter] = []
    private var tone: Tone = .none
    private var raw = false
    private var transformed = false
    /// After a doubled key: the text shown at that point (mark removed, key typed once)
    /// and the index of the first key that follows it literally.
    private var undoText: String?
    private var undoEnd = 0

    /// Longer "words" (hashes, long identifiers) are passed through untouched.
    private static let maxKeys = 32

    public init(toneStyle: ToneStyle = .old) {
        self.toneStyle = toneStyle
    }

    public var isEmpty: Bool { keys.isEmpty }

    /// Feeds one typed character of the current word.
    public mutating func process(_ key: Character) -> Edit {
        keys.append(key)
        compose()
        let new = render(finalForm: false)
        let edit = Edit.between(text, new)
        text = new
        return edit
    }

    /// The word ended (space, punctuation, Enter…) and a new one starts. The only change it
    /// can make is spelling: "ươ" with nothing after it is written "uơ" (thưở → thuở).
    public mutating func finalize() -> Edit? {
        defer { reset() }
        guard !raw, transformed else { return nil }
        let edit = Edit.between(text, render(finalForm: true))
        return edit.isEmpty ? nil : edit
    }

    /// The app just deleted the last character on screen (Backspace passed through).
    public mutating func backspace() {
        load(String(text.dropLast()))
    }

    /// Takes over a word already on screen right before the caret, so more keys can change
    /// it: load("tân") then "j" → "tận". A word that does not recompose to exactly the same
    /// text (English, or after an escape like "pas") is kept literal.
    public mutating func load(_ word: String) {
        reset()
        guard !word.isEmpty else { return }
        keys = Self.encode(word)
        compose()
        text = render(finalForm: false)
        if text != word {
            // Never disagree with the screen: fall back to the literal text.
            keys = Array(word)
            startRaw = true
            compose()
            text = word
        }
    }

    /// The letters right before the end of `text` (the word the caret is at), or "" if
    /// there are none or too many to be a word.
    public static func trailingWord(of text: String) -> String {
        let word = String(text.reversed().prefix { $0.isLetter }.reversed())
        return word.count <= maxKeys ? word : ""
    }

    public mutating func reset() {
        keys = []
        startRaw = false
        letters = []
        tone = .none
        raw = false
        transformed = false
        undoText = nil
        text = ""
    }

    // MARK: - Composition

    private enum Outcome { case applied, undo, notApplicable }

    private mutating func compose() {
        letters = []
        tone = .none
        transformed = false
        undoText = nil
        raw = startRaw || keys.count > Self.maxKeys
        guard !raw else { return }
        for i in keys.indices {
            if raw { break }
            apply(keys[i], at: i)
        }
    }

    private mutating func apply(_ key: Character, at index: Int) {
        let letter = Letter(key: key)
        // An uppercase key is a command only in an all-caps word ("VIEEJT"), so camelCase
        // identifiers like "useState" keep their capitals.
        let isCommandCase = !letter.upper || letters.allSatisfy(\.upper)
        let outcome = letter.isASCIILetter && isCommandCase ? command(letter) : .notApplicable
        switch outcome {
        case .applied:
            transformed = true
        case .undo:
            // The command already removed its mark: show the word without it, plus the key
            // (nẽ + x → nex, đi + d → did). Everything after that is typed literally.
            undoText = renderComposed(finalForm: false) + String(key)
            undoEnd = index + 1
            raw = true
        case .notApplicable:
            // Keep the marks even if this letter breaks the word ("tân" + k → "tânk"): the
            // user sees their typo and fixes it with Backspace.
            letters.append(letter)
            if transformed { Self.normalizeHorn(&letters) }
        }
    }

    private mutating func command(_ letter: Letter) -> Outcome {
        switch letter.base {
        case "s", "f", "r", "x", "j":
            return toneCommand(Tone(key: letter.base)!)
        case "z":
            guard tone != .none else { return .notApplicable }
            tone = .none
            return .applied
        case "a", "e", "o":
            return circumflexCommand(letter.base)
        case "w":
            return hornCommand()
        case "d":
            return strokeCommand()
        default:
            return .notApplicable
        }
    }

    private mutating func toneCommand(_ t: Tone) -> Outcome {
        guard letters.contains(where: \.isVowel) else { return .notApplicable }
        if tone == t {
            tone = .none
            return .undo
        }
        guard Syllable.isValid(letters, tone: t, complete: false) else { return .notApplicable }
        tone = t
        return .applied
    }

    /// aa → â, ee → ê, oo → ô, also after the final consonant (hien + e → hiên). English
    /// words hit by this ("data" → "dât") are not complete syllables and restore at word end.
    private mutating func circumflexCommand(_ base: Character) -> Outcome {
        let p = Syllable.parse(letters)
        guard p.isWellFormed,
              let j = p.vowels.reversed().first(where: { letters[$0].base == base })
        else { return .notApplicable }
        if letters[j].mod == .circumflex {
            letters[j].mod = .none
            return .undo
        }
        var candidate = letters
        candidate[j].mod = .circumflex
        guard Syllable.isValid(candidate, tone: tone, complete: false) else { return .notApplicable }
        letters = candidate
        return .applied
    }

    /// w: uo → ươ, then the nearest a → ă, o → ơ, u → ư. Unlike Unikey, a w with no vowel
    /// before it stays "w" (type "uw" for ư), so w, www, what, while never flash an ư.
    private mutating func hornCommand() -> Outcome {
        let p = Syllable.parse(letters)
        guard p.isWellFormed, !p.vowels.isEmpty else { return .notApplicable }

        let v = p.vowels
        var candidates: [[Letter]] = []
        if let j = v.first(where: { $0 + 1 < v.upperBound && letters[$0].base == "u" && letters[$0 + 1].base == "o" }),
           !(letters[j].mod == .horn && letters[j + 1].mod == .horn) {
            var c = letters
            c[j].mod = .horn
            c[j + 1].mod = .horn
            candidates.append(c)
        }
        for j in v.reversed() where letters[j].mod == .none {
            var c = letters
            switch letters[j].base {
            case "a": c[j].mod = .breve
            case "o", "u": c[j].mod = .horn
            default: continue
            }
            candidates.append(c)
        }
        for var c in candidates {
            Self.normalizeHorn(&c)
            if Syllable.isValid(c, tone: tone, complete: false) {
                letters = c
                return .applied
            }
        }
        guard v.contains(where: { letters[$0].mod == .breve || letters[$0].mod == .horn }) else {
            return .notApplicable
        }
        for j in v where letters[j].mod == .breve || letters[j].mod == .horn {
            letters[j].mod = .none
        }
        return .undo
    }

    /// dd → đ, and like Unikey a later d works too: dodongj → động, dieenjd → điện.
    private mutating func strokeCommand() -> Outcome {
        guard let first = letters.first, first.base == "d" else { return .notApplicable }
        if first.mod == .stroke {
            letters[0].mod = .none  // didd → did, ddid → did
            return .undo
        }
        var candidate = letters
        candidate[0].mod = .stroke
        guard Syllable.isValid(candidate, tone: tone, complete: false) else { return .notApplicable }
        letters = candidate
        return .applied
    }

    /// "ưo" and "uơ" followed by more letters become "ươ" (trưong → trương, tuơi → tươi).
    /// Not before that, so the w of "uwow" still lands on the o instead of undoing.
    private static func normalizeHorn(_ l: inout [Letter]) {
        let v = Syllable.parse(l).vowels
        for j in v where j + 2 < l.count && j + 1 < v.upperBound && l[j].base == "u" && l[j + 1].base == "o" {
            if (l[j].mod == .horn) != (l[j + 1].mod == .horn), l[j].mod != .circumflex, l[j + 1].mod != .circumflex {
                l[j].mod = .horn
                l[j + 1].mod = .horn
            }
        }
    }

    // MARK: - Rendering

    private func render(finalForm: Bool) -> String {
        guard raw else { return renderComposed(finalForm: finalForm) }
        if let undoText { return undoText + String(keys[undoEnd...]) }
        return String(keys)
    }

    private func renderComposed(finalForm: Bool) -> String {
        var l = letters
        let p = Syllable.parse(l)
        var toneIndex: Int?
        if !p.vowels.isEmpty {
            if finalForm, p.final.isEmpty, Syllable.isOpenUoHorn(Array(l[p.vowels])) {
                l[p.vowels.lowerBound].mod = .none  // thuở, huơ
            }
            if tone != .none {
                toneIndex = p.vowels.lowerBound
                    + Syllable.tonePosition(Array(l[p.vowels]), hasFinal: !p.final.isEmpty, style: toneStyle)
            }
        }
        var s = ""
        for (i, letter) in l.enumerated() {
            s += VietChars.render(letter, tone: i == toneIndex ? tone : .none)
        }
        return s
    }

    /// Canonical Telex keys that recompose to `text` (tiến → tieens), used after Backspace.
    static func encode(_ text: String) -> [Character] {
        var out: [Character] = []
        var toneKey: Character?
        let chars = Array(text)
        for (i, ch) in chars.enumerated() {
            let lower = Character(ch.lowercased())
            let upper = ch.isUppercase
            func put(_ c: Character) { out.append(upper ? Character(c.uppercased()) : c) }

            if lower == "đ" {
                put("d")
                put("d")
                continue
            }
            guard let d = VietChars.decompose(lower) else {
                out.append(ch)
                continue
            }
            if let k = d.tone.key { toneKey = k }
            put(d.base)
            switch d.mod {
            case .circumflex:
                put(d.base)
            case .breve:
                out.append("w")
            case .horn:
                // In "ươ" the single w typed after the o horns both letters.
                let next = i + 1 < chars.count ? VietChars.decompose(Character(chars[i + 1].lowercased())) : nil
                if !(d.base == "u" && next?.base == "o" && next?.mod == .horn) { out.append("w") }
            case .none, .stroke:
                break
            }
        }
        if let toneKey { out.append(toneKey) }
        return out
    }
}
