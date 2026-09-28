import Testing
@testable import SKeyEngine

/// Marks typed late: circumflex/horn after the final consonant, tone as the last key,
/// đ at the end of a word that already has Vietnamese marks.
struct LateMarksTests {
    static let cases: [(String, String)] = [
        ("hienej", "hiện"), ("hienje", "hiện"), ("tiengse", "tiếng"), ("tienges", "tiếng"),
        ("vietej", "việt"), ("vietje", "việt"), ("quocos", "quốc"), ("quocso", "quốc"),
        ("khongo", "không"), ("baanj", "bận"), ("banaj", "bận"), ("chuyenej", "chuyện"),
        ("muonos", "muốn"), ("cuocoj", "cuộc"), ("xuana", "xuân"), ("tuanaf", "tuần"),
        ("nguoiwf", "người"), ("duongw", "dương"), ("truongwf", "trường"), ("namw", "năm"),
        ("hoacwj", "hoặc"), ("dieenjd", "điện"), ("dienejd", "điện"), ("dojd", "đọ"),
        ("duongwd", "đương"), ("dungwsd", "đứng"), ("dodongj", "động"),
        ("ddoongj", "động"), ("dongjd", "đọng"), ("dieemr", "diểm") /* one d → no đ */,
        ("Hienej", "Hiện"), ("HIENEJ", "HIỆN"), ("Vietej Nam", "Việt Nam"),
    ]

    @Test(arguments: cases)
    func lateMark(_ keys: String, _ expected: String) {
        var s = Screen()
        s.type(keys + " ")
        #expect(String(s.text.dropLast()) == expected)
    }

    /// Every word typed with all marks at the end: base letters, then circumflex letters,
    /// then w, then the tone key (đ is typed as dd up front).
    @Test(arguments: VietnameseWords.all)
    func allMarksLast(_ word: String) {
        let keys = Self.lateKeys(for: word)
        #expect(Screen.word(String(keys)) == word, "\(String(keys)) → \(Screen.word(String(keys)))")
    }

    /// Canonical order (each mark right after its vowel, tone last).
    @Test(arguments: VietnameseWords.all)
    func canonicalOrder(_ word: String) {
        let keys = String(TelexEngine.encode(word))
        #expect(Screen.word(keys) == word, "\(keys) → \(Screen.word(keys))")
    }

    static func lateKeys(for word: String) -> [Character] {
        var base: [Character] = []
        var circumflex: [Character] = []
        var horn = false
        var toneKey: Character?
        for ch in word {
            let lower = Character(ch.lowercased())
            let upper = ch.isUppercase
            func put(_ c: Character) { base.append(upper ? Character(c.uppercased()) : c) }
            if lower == "đ" {
                put("d"); put("d")
                continue
            }
            guard let d = VietChars.decompose(lower) else {
                base.append(ch)
                continue
            }
            if let k = d.tone.key { toneKey = k }
            put(d.base)
            switch d.mod {
            case .circumflex: circumflex.append(d.base)
            case .breve, .horn: horn = true
            default: break
            }
        }
        return base + circumflex + (horn ? ["w"] : []) + (toneKey.map { [$0] } ?? [])
    }
}
