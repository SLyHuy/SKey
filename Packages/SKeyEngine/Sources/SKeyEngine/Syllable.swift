import Foundation

/// Vietnamese syllable structure: initial consonant + vowel cluster + final consonant.
/// Used to decide whether a Telex key may transform the word, whether the word must be
/// restored to the typed letters (English), and where the tone mark goes.
enum Syllable {
    struct Parts {
        var initial: Range<Int>
        var vowels: Range<Int>
        var final: Range<Int>
        /// False when letters follow the final consonant (e.g. "data", "useState").
        var isWellFormed: Bool
    }

    static func parse(_ l: [Letter]) -> Parts {
        let n = l.count
        var i = 0
        while i < n, !l[i].isVowel { i += 1 }
        // "qu" and "gi" (before another vowel) are initial consonants.
        if i == 1, l[0].base == "q", i < n, l[i].base == "u", l[i].mod == .none {
            i += 1
        } else if i == 1, l[0].base == "g", l[0].mod == .none,
                  i + 1 < n, l[i].base == "i", l[i].mod == .none, l[i + 1].isVowel {
            i += 1
        }
        let initialEnd = i
        while i < n, l[i].isVowel { i += 1 }
        let vowelEnd = i
        while i < n, !l[i].isVowel { i += 1 }
        return Parts(initial: 0..<initialEnd, vowels: initialEnd..<vowelEnd,
                     final: vowelEnd..<i, isWellFormed: i == n)
    }

    /// `complete == false`: could still become a valid syllable by typing more keys.
    /// `complete == true`: is a finished, valid syllable (checked at word end).
    static func isValid(_ l: [Letter], tone: Tone, complete: Bool) -> Bool {
        let p = parse(l)
        guard p.isWellFormed else { return false }
        let initial = consonants(l, p.initial)
        if p.vowels.isEmpty {
            return !complete && tone == .none && initialPrefixes.contains(initial)
        }
        guard initials.contains(initial), initialFits(initial, l[p.vowels.lowerBound]) else { return false }

        var cluster = Array(l[p.vowels])
        let final = consonants(l, p.final)
        guard finals.contains(final) else { return false }
        if complete, final.isEmpty, isOpenUoHorn(cluster) {
            cluster[0].mod = .none  // "ươ" without a final consonant is written "uơ" (thuở)
        }
        if stopFinals.contains(final) {
            // Syllables ending in c, ch, p, t only take the acute or dot tone.
            if complete {
                guard tone == .acute || tone == .dot else { return false }
            } else {
                guard tone == .none || tone == .acute || tone == .dot else { return false }
            }
        }
        let finalCandidates = complete ? [final] : extensions(of: final)

        return clusters.contains { c in
            if complete {
                guard c.letters.count == cluster.count, zip(cluster, c.letters).allSatisfy({
                    $0.base == $1.base && $0.mod == $1.mod
                }) else { return false }
            } else {
                guard final.isEmpty ? c.letters.count >= cluster.count : c.letters.count == cluster.count,
                      zip(cluster, c.letters).allSatisfy({
                          $0.base == $1.base && ($0.mod == .none || $0.mod == $1.mod)
                      }) else { return false }
            }
            if final.isEmpty { return !complete || c.rule != .required }
            guard c.rule != .forbidden else { return false }
            return finalCandidates.contains { finalFits(c.text, $0) }
        }
    }

    /// Index (within the vowel cluster) of the vowel that carries the tone mark.
    static func tonePosition(_ cluster: [Letter], hasFinal: Bool, style: ToneStyle) -> Int {
        if cluster.count <= 1 { return 0 }
        // A modified vowel (â ê ô ơ ư ă) always takes the mark; for ươ it is the ơ.
        if let last = cluster.indices.last(where: { cluster[$0].mod != .none }) { return last }
        if cluster.count >= 3 { return 1 }            // oai, oay, uyu, oeo
        if hasFinal { return 1 }                      // hoàn, huỳnh
        let text = String(cluster.map(\.base))
        if text == "oa" || text == "oe" || text == "uy" {
            return style == .old ? 0 : 1              // hòa / hoà
        }
        return 0                                      // mái, màu, mía, múa, túi
    }

    static func isOpenUoHorn(_ cluster: [Letter]) -> Bool {
        cluster.count == 2
            && cluster[0].base == "u" && cluster[0].mod == .horn
            && cluster[1].base == "o" && cluster[1].mod == .horn
    }

    // MARK: - Tables

    private static let initials: Set<String> = [
        "", "b", "c", "ch", "d", "đ", "g", "gh", "gi", "h", "k", "kh", "l", "m", "n", "ng",
        "ngh", "nh", "p", "ph", "qu", "r", "s", "t", "th", "tr", "v", "x",
    ]

    private static let initialPrefixes: Set<String> = {
        var s = Set<String>()
        for i in initials {
            for n in 0...i.count { s.insert(String(i.prefix(n))) }
        }
        return s
    }()

    private static let finals: Set<String> = ["", "c", "ch", "m", "n", "ng", "nh", "p", "t"]
    private static let stopFinals: Set<String> = ["c", "ch", "p", "t"]

    private static func extensions(of final: String) -> [String] {
        switch final {
        case "c": ["c", "ch"]
        case "n": ["n", "ng", "nh"]
        default: [final]
        }
    }

    /// Spelling rules tying the initial consonant to the first vowel (ki/ke, ghi, nghe, ca, ga, nga).
    private static func initialFits(_ initial: String, _ vowel: Letter) -> Bool {
        let front = vowel.base == "i" || vowel.base == "e" || vowel.base == "y"
        switch initial {
        case "k", "gh", "ngh": return front
        case "c", "ng": return !front
        case "g": return vowel.base != "e" && vowel.base != "y"
        default: return true
        }
    }

    /// Which finals may follow a vowel cluster: ch/nh only after a, ê, i, y; c/ng never after i, y, uy
    /// (Vietnamese writes -ich/-inh there, which also keeps English "-ing" words intact).
    private static func finalFits(_ cluster: String, _ final: String) -> Bool {
        // Rare clusters take only a few finals: khoen/khoét, huệch/tuềnh, huynh/huých/tuýt/tuýp.
        switch cluster {
        case "oe": return final == "n" || final == "t"
        case "uê": return final == "ch" || final == "nh"
        case "uy": return ["ch", "nh", "t", "p"].contains(final)
        default: break
        }
        switch final {
        case "ch", "nh":
            guard let last = cluster.last else { return false }
            return last == "a" || last == "ê" || last == "i" || last == "y"
        case "c", "ng":
            return !["i", "y", "uy"].contains(cluster)
        default:
            return true
        }
    }

    private static func consonants(_ l: [Letter], _ range: Range<Int>) -> String {
        String(l[range].map { $0.mod == .stroke ? "đ" : $0.base })
    }

    enum FinalRule { case optional, required, forbidden }

    struct Cluster {
        let text: String
        let letters: [(base: Character, mod: Mod)]
        let rule: FinalRule
    }

    private static let clusters: [Cluster] = {
        let spec: [(String, FinalRule)] = [
            ("a", .optional), ("ă", .required), ("â", .required), ("e", .optional), ("ê", .optional),
            ("i", .optional), ("o", .optional), ("ô", .optional), ("ơ", .optional), ("u", .optional),
            ("ư", .optional), ("y", .optional),
            ("ai", .forbidden), ("ao", .forbidden), ("au", .forbidden), ("ay", .forbidden),
            ("âu", .forbidden), ("ây", .forbidden), ("eo", .forbidden), ("êu", .forbidden),
            ("ia", .forbidden), ("iê", .required), ("iu", .forbidden),
            ("oa", .optional), ("oă", .required), ("oe", .optional), ("oi", .forbidden),
            ("ôi", .forbidden), ("ơi", .forbidden), ("oo", .required),
            ("ua", .forbidden), ("uâ", .required), ("uê", .optional), ("ui", .forbidden),
            ("uô", .required), ("uơ", .forbidden), ("uy", .optional),
            ("ưa", .forbidden), ("ưi", .forbidden), ("ươ", .required), ("ưu", .forbidden),
            ("yê", .required),
            ("iêu", .forbidden), ("yêu", .forbidden), ("oai", .forbidden), ("oay", .forbidden),
            ("oeo", .forbidden), ("uây", .forbidden), ("uôi", .forbidden), ("ươi", .forbidden),
            ("ươu", .forbidden), ("uya", .forbidden), ("uyê", .required), ("uyu", .forbidden),
        ]
        return spec.map { text, rule in
            let normalized = text.precomposedStringWithCanonicalMapping
            let letters = normalized.map { c -> (Character, Mod) in
                let d = VietChars.decompose(c)!
                return (d.base, d.mod)
            }
            return Cluster(text: normalized, letters: letters, rule: rule)
        }
    }()
}
