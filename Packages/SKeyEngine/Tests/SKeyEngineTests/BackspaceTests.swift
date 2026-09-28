import Testing
@testable import SKeyEngine

struct BackspaceTests {
    @Test func continueAfterBackspace() {
        var s = Screen()
        s.type("tieengs")
        #expect(s.text == "tiếng")
        s.backspace()
        #expect(s.text == "tiến")
        s.type("g")
        #expect(s.text == "tiếng")
    }

    @Test func modifiersStillWorkAfterBackspace() {
        var t = Screen()
        t.type("vieejx")
        #expect(t.text == "viễ")
        t.backspace()
        t.type("ee")
        #expect(t.text == "viê")
    }

    @Test func uoHornAcrossBackspace() {
        var s = Screen()
        s.type("nguowif")
        #expect(s.text == "người")
        s.backspace()
        #expect(s.text == "ngườ")
        s.type("i")
        #expect(s.text == "người")
    }

    @Test func restoredEnglishWordStaysEnglish() {
        var s = Screen()
        s.type("windo")  // "ưin" is not Vietnamese → restored to the typed keys
        #expect(s.text == "windo")
        s.backspace()
        #expect(s.text == "wind")
        s.type("ow")
        #expect(s.text == "window")
    }

    @Test func backspaceToEmptyResets() {
        var s = Screen()
        s.type("ddi")
        s.backspace()
        s.backspace()
        #expect(s.text == "")
        #expect(s.engine.isEmpty)
        s.type("as")
        #expect(s.text == "á")
    }

    /// Re-encoding what is on screen must recompose to exactly the same text.
    @Test(arguments: TelexCasesTests.words.map(\.1))
    func encodeRoundTrip(_ word: String) {
        var e = TelexEngine()
        for k in TelexEngine.encode(word) { _ = e.process(k) }
        let shown = e.text
        // Open "ươ" becomes "uơ" only at word end; compare the committed form.
        let committed = e.finalize().map { edit in
            String(shown.dropLast(edit.deleteCount)) + edit.insert
        } ?? shown
        #expect(committed == word, "\(word) → keys \(String(TelexEngine.encode(word))) → \(committed)")
    }

    @Test func pureAppendIsDetectable() {
        var e = TelexEngine()
        #expect(e.process("b") == Edit(deleteCount: 0, insert: "b"))
        #expect(e.process("a") == Edit(deleteCount: 0, insert: "a"))
        #expect(e.process("s") == Edit(deleteCount: 1, insert: "á"))
    }
}

/// A wrong letter after a Vietnamese word keeps the marks (also after the word ends), so it
/// can be fixed: "tân" + k (typo for j) → Backspace → j → "tận".
struct TypoFixTests {
    @Test func wrongToneKeyCanBeFixed() {
        var s = Screen()
        s.type("taank")
        #expect(s.text == "tânk")
        s.backspace()
        #expect(s.text == "tân")
        s.type("j ")
        #expect(s.text == "tận ")
    }

    @Test func typoLeftInPlaceIsKeptAtWordEnd() {
        var s = Screen()
        s.type("taank ")
        #expect(s.text == "tânk ")  // never corrected behind the user's back
    }

    static let fixes: [(typo: String, fix: String, expected: String)] = [
        ("vieejk", "t", "việt"), ("nguowif", "", "người"), ("dduowck", "j", "được"),
        ("tieengq", "s", "tiếng"), ("hocz", "j", "học"), ("banl", "j", "bạn"),
    ]

    @Test(arguments: fixes)
    func backspaceThenCorrectKey(_ typo: String, _ fix: String, _ expected: String) {
        var s = Screen()
        s.type(typo)
        if !fix.isEmpty || typo.last == "k" || typo.last == "q" || typo.last == "l" { s.backspace() }
        s.type(fix + " ")
        #expect(s.text == expected + " ", "\(typo) ⌫ \(fix) → \(s.text)")
    }

    @Test func englishNeedsTheDoubledKey() {
        #expect(Screen.word("base") == "báe")
        #expect(Screen.word("basse") == "base")
    }
}
