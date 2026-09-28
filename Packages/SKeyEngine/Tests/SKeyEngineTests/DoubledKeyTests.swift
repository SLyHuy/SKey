import Testing
@testable import SKeyEngine

/// A doubled transform key (ss, xx, rr, aa, ww, dd…) removes the mark and keeps the key
/// once, immediately, exactly like Unikey. No dictionary, no English guessing.
struct DoubledKeyTests {
    static let cases: [(String, String)] = [
        // Escapes
        ("nexxt", "next"), ("tesst", "test"), ("russt", "rust"), ("maxx", "max"),
        ("passs", "pass"), ("errror", "error"), ("offfset", "offset"), ("Tesst", "Test"),
        ("TESST", "TEST"), ("uww", "uw"), ("oww", "ow"), ("aww", "aw"), ("ddd", "dd"),
        ("caaa", "caa"), ("xooong", "xoong"), ("booong", "boong"),
        // Remove the mark, then type the key: đi + d → did, câu + a → caua
        ("didd", "did"), ("ddid", "did"), ("Didd", "Did"), ("DIDD", "DID"), ("dodd", "dod"),
        ("caaua", "caua"), ("tuoww", "tuow"), ("hoawcw", "hoacw"),
        // Plain English double letters lose one letter, as in Unikey: type the key 3 times
        ("pass", "pas"), ("error", "eror"), ("offset", "ofset"), ("tests", "tets"),
        ("terraform", "teraform"), ("terrraform", "terraform"),
    ]

    @Test(arguments: cases)
    func doubledKey(_ keys: String, _ expected: String) {
        #expect(Screen.word(keys) == expected)
    }

    /// The original report: "nẽ" + x must show "nex" at once.
    @Test func secondToneKeyRemovesMarkImmediately() {
        var s = Screen()
        s.type("nex")
        #expect(s.text == "nẽ")
        s.type("x")
        #expect(s.text == "nex")
        s.type("t")
        #expect(s.text == "next")
        s.type(" ")
        #expect(s.text == "next ")
    }

    @Test func secondModifierKeyUndoesImmediately() {
        var s = Screen()
        s.type("uw")
        #expect(s.text == "ư")
        s.type("w")
        #expect(s.text == "uw")

        var t = Screen()
        t.type("dd")
        #expect(t.text == "đ")
        t.type("d")
        #expect(t.text == "dd")

        var u = Screen()
        u.type("caa")
        #expect(u.text == "câ")
        u.type("a")
        #expect(u.text == "caa")
    }

    @Test func nothingChangesAtWordEndAfterAnEscape() {
        var s = Screen()
        s.type("pass")
        #expect(s.text == "pas")
        s.type(" ")
        #expect(s.text == "pas ")
    }

    /// The report: "I didd it" must give "I did it".
    @Test func iDidIt() {
        var s = Screen()
        s.type("I didd it ")
        #expect(s.text == "I did it ")
    }

    @Test func afterUndoTheRestIsLiteral() {
        #expect(Screen.word("assf") == "asf")
        #expect(Screen.word("vieejtt") == "việtt")  // kept as typed, never corrected
    }

    @Test func backspaceAfterDoubleKeepsScreenText() {
        var s = Screen()
        s.type("nexxt")
        s.backspace()
        #expect(s.text == "nex")
        s.type("t ")
        #expect(s.text == "next ")
    }
}
