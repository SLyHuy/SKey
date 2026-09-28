import Testing
@testable import SKeyEngine

/// Going back into a finished word to change its tone, marks or consonant.
struct EditPreviousWordTests {
    // MARK: Backspace into the previous word (no Accessibility needed)

    @Test func backspaceOverSpaceThenChangeTone() {
        var s = Screen()
        s.type("taan ")
        s.backspace()
        #expect(s.text == "tân")
        s.type("j")
        #expect(s.text == "tận")
    }

    static let backspaceCases: [(typed: String, back: Int, keys: String, expected: String)] = [
        ("taan ", 1, "j", "tận"),            // add a tone
        ("tajn ", 1, "s", "tán"),            // change the tone
        ("tajn ", 1, "z", "tan"),            // remove the tone
        ("dang ", 1, "d", "đang"),           // change the consonant d → đ
        ("tien ", 1, "es", "tiến"),          // add circumflex, then tone
        ("nguoi ", 1, "wf", "người"),        // add horn, then tone
        ("xin chao ", 1, "f", "xin chào"),   // only the last word changes
        ("chao, ", 2, "f", "chào"),          // back over punctuation too
        ("chao  ", 2, "f", "chào"),          // and over several spaces
        ("hello world ", 1, "s", "hello worlds"), // English stays as typed
    ]

    @Test(arguments: backspaceCases)
    func backspaceIntoWord(_ typed: String, _ back: Int, _ keys: String, _ expected: String) {
        var s = Screen()
        s.type(typed)
        s.backspace(back)
        s.type(keys)
        #expect(s.text == expected, "\(typed) ⌫×\(back) \(keys) → \(s.text)")
    }

    @Test func backspaceIntoWordThenContinueTyping() {
        var s = Screen()
        s.type("Tooi teen laf Huy ")
        s.backspace(5)  // " Huy " → back into "là"
        #expect(s.text == "Tôi tên là")
        s.type("z Huy ")
        #expect(s.text == "Tôi tên la Huy ")
    }

    @Test func deletingPartOfThePreviousWord() {
        var s = Screen()
        s.type("tieengs ")
        s.backspace(3)  // " ", g, n
        #expect(s.text == "tiế")
        s.type("t")
        #expect(s.text == "tiết")
    }

    // MARK: Caret moved by mouse or arrows (context from Accessibility)

    @Test func clickAfterWordThenChangeTone() {
        var s = Screen(existing: "Tôi tên tân Huy")
        s.moveCaret(to: 11)  // right after "tân"
        s.type("j")
        #expect(s.text == "Tôi tên tận Huy")
    }

    @Test func arrowBackThenChangeMarks() {
        var s = Screen()
        s.type("Tooi yeu Vieejt Nam")
        s.moveCaret(to: 7)  // after "yeu"
        s.type("e")
        #expect(s.text == "Tôi yêu Việt Nam")
    }

    @Test func caretInsideWordLeavesItAlone() {
        var s = Screen(existing: "tân")
        s.moveCaret(to: 2)  // "tâ|n"
        s.type("j")
        #expect(s.text == "tâjn")
    }

    @Test func nonMarkKeyAfterClickStartsANewWord() {
        var s = Screen(existing: "ba")
        s.moveCaret(to: 2)
        s.type("nj")
        #expect(s.text == "banj")  // "n" was not a mark key, so "ba" was not taken over
    }

    @Test func noContextAvailableKeepsOldBehaviour() {
        var session = TypingSession()
        let edit = session.letter("j", context: { nil })
        #expect(edit == Edit(deleteCount: 0, insert: "j"))
    }

    @Test func clickAfterEnglishWordTypesNormally() {
        var s = Screen(existing: "class")
        s.moveCaret(to: 5)
        s.type("es")
        #expect(s.text == "classes")
    }

    // MARK: Privacy limits: read and remember as little as possible

    @Test func limits() {
        #expect(TypingSession.maxWordLength == 7)
        #expect(TypingSession.contextLength == 14)
        #expect(TypingSession.memoryLength == 21)
    }

    @Test func wordInBracketsAndQuotes() {
        var s = Screen(existing: "print(\"tan\")")
        s.moveCaret(to: 10)  // right after "tan", before the closing quote
        s.type("j")
        #expect(s.text == "print(\"tạn\")")
    }

    @Test func onlyTheLast14CharactersAreUsed() {
        var s = Screen(existing: "một câu rất dài trước từ tân")
        s.moveCaret(to: s.text.count)
        s.type("j")
        #expect(s.text == "một câu rất dài trước từ tận")
    }

    @Test func wordsLongerThan7LettersAreNeverTakenOver() {
        var s = Screen(existing: "internationalization")
        s.moveCaret(to: s.text.count)
        s.type("s")
        #expect(s.text == "internationalizations")

        var t = Screen()
        t.type("internationalization ")
        t.backspace()
        t.type("s")
        #expect(t.text == "internationalizations")
    }

    @Test func backspaceWithinMemoryReachesTwoWordsBack() {
        var s = Screen(contextAvailable: false)
        s.type("laf Huy ")  // 8 characters, well within 21
        s.backspace(5)
        s.type("z")
        #expect(s.text == "la")
    }

    /// When memory trimmed the start of a word, SKey does not guess from the fragment: it
    /// asks the app for the real text, or leaves the word alone if the app cannot tell.
    @Test func trimmedWordIsNotGuessed() {
        let typed = "nguowif" + String(repeating: " ", count: 18)  // "người" + 18 spaces > 21

        var withContext = Screen()
        withContext.type(typed)
        withContext.backspace(18)
        withContext.type("z")
        #expect(withContext.text == "ngươi")

        var withoutContext = Screen(contextAvailable: false)
        withoutContext.type(typed)
        withoutContext.backspace(18)
        withoutContext.type("z")
        #expect(withoutContext.text == "ngườiz")
    }

    // MARK: Engine building blocks

    @Test func loadThenModify() {
        var e = TelexEngine()
        e.load("tân")
        #expect(e.text == "tân")
        #expect(e.process("j") == Edit(deleteCount: 2, insert: "ận"))
    }

    @Test func loadKeepsNonVietnameseLiteral() {
        var e = TelexEngine()
        e.load("pas")  // typed as "pass" (escape); must not become "pá"
        #expect(e.text == "pas")
        #expect(e.process("s") == Edit(deleteCount: 0, insert: "s"))
    }

    @Test func trailingWord() {
        #expect(TelexEngine.trailingWord(of: "Tôi tên là") == "là")
        #expect(TelexEngine.trailingWord(of: "xin chào, ") == "")
        #expect(TelexEngine.trailingWord(of: "") == "")
        #expect(TelexEngine.trailingWord(of: "a" + String(repeating: "b", count: 40)) == "")
    }
}
