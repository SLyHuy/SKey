import Testing
@testable import SKeyEngine

/// Random typing with a fixed seed. Whatever the keys, the engine must never disagree with
/// the screen, never delete more than it typed, and always emit precomposed text.
struct FuzzTests {
    /// Deterministic xorshift, so failures reproduce.
    struct RNG: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return state
        }
    }

    static let alphabet = Array("aaeeiioouuydwsfrxjzhnmtcgkqlpbvAEOWDS")

    @Test(arguments: 1...40)
    func randomWordsStayInSync(seed: Int) {
        var rng = RNG(state: UInt64(seed) &* 0x9E37_79B9_7F4A_7C15)
        var s = Screen()
        for _ in 0..<60 {
            let length = Int.random(in: 1...14, using: &rng)
            for _ in 0..<length {
                if Int.random(in: 0..<10, using: &rng) == 0, !s.engine.isEmpty {
                    s.backspace()
                } else {
                    s.type(String(Self.alphabet.randomElement(using: &rng)!))
                }
                #expect(s.currentWord == Substring(s.engine.text), "screen \(s.text) vs engine \(s.engine.text)")
            }
            s.type(" ")
        }
        #expect(s.text.unicodeScalars.count == s.text.count, "output must be NFC")
    }

    /// After any word, the finished text is either the typed keys or a Vietnamese word.
    @Test(arguments: 1...20)
    func finishedWordIsTypedOrVietnamese(seed: Int) {
        var rng = RNG(state: UInt64(seed) &* 0xD1B5_4A32_D192_ED03)
        for _ in 0..<200 {
            let length = Int.random(in: 1...8, using: &rng)
            let keys = String((0..<length).map { _ in Self.alphabet.randomElement(using: &rng)! })
            let out = Screen.word(keys)
            if out.allSatisfy(\.isASCII) { continue }  // typed (or escaped) letters
            #expect(out.count <= keys.count, "\(keys) → \(out)")
        }
    }

    @Test func veryLongIdentifierPassesThrough() {
        let id = "thisIsAVeryLongIdentifierNameThatKeepsGoingForever"
        #expect(Screen.word(id) == id)
    }

    /// The first repeat undoes the mark and is dropped; every later key is literal.
    @Test func repeatedToneKeysNeverCrash() {
        #expect(Screen.word("a" + String(repeating: "s", count: 9)) == "a" + String(repeating: "s", count: 8))
        #expect(Screen.word(String(repeating: "a", count: 10)) == String(repeating: "a", count: 9))
        #expect(Screen.word(String(repeating: "w", count: 10)) == String(repeating: "w", count: 10))
        #expect(Screen.word(String(repeating: "z", count: 10)) == String(repeating: "z", count: 10))
    }
}
