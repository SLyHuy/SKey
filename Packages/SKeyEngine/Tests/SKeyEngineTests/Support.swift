@testable import SKeyEngine

/// A fake text field with a caret. It feeds a `TypingSession` exactly like the real key
/// router, and answers context lookups like the Accessibility API would.
struct Screen {
    var session: TypingSession
    var text = ""
    var caret = 0

    init(style: ToneStyle = .old, existing: String = "") {
        session = TypingSession(toneStyle: style)
        text = existing
        caret = existing.count
    }

    var engine: TelexEngine { session.engine }

    mutating func apply(_ edit: Edit) {
        precondition(edit.deleteCount <= caret, "edit deletes more than is before the caret")
        let start = text.index(text.startIndex, offsetBy: caret - edit.deleteCount)
        let end = text.index(text.startIndex, offsetBy: caret)
        text.replaceSubrange(start..<end, with: edit.insert)
        caret += edit.insert.count - edit.deleteCount
    }

    private mutating func insert(_ ch: Character) {
        apply(Edit(deleteCount: 0, insert: String(ch)))
    }

    /// What the Accessibility API reports: text before the caret, and whether a letter follows.
    func context() -> TypingSession.Context? {
        let chars = Array(text)
        return (String(chars[..<caret]), caret < chars.count && chars[caret].isLetter)
    }

    /// Types `input`. Like the real key router, any non-letter (space, punctuation,
    /// digits) ends the word and is then typed as-is.
    mutating func type(_ input: String) {
        for ch in input {
            if ch.isASCII, ch.isLetter {
                let ctx = context()
                apply(session.letter(ch, context: { ctx }))
            } else {
                if let e = session.wordBreak(ch) { apply(e) }
                insert(ch)
            }
        }
    }

    mutating func backspace(_ times: Int = 1) {
        for _ in 0..<times {
            apply(Edit(deleteCount: 1, insert: ""))
            session.backspace()
        }
    }

    /// A click or arrow keys: the caret jumps and the session loses track.
    mutating func moveCaret(to index: Int) {
        caret = index
        session.cursorMoved()
    }

    /// The part of the screen that belongs to the word being typed.
    var currentWord: Substring {
        text.prefix(caret).suffix(engine.text.count)
    }

    /// Types a whole word and ends it, returning what is on screen.
    static func word(_ keys: String, style: ToneStyle = .old) -> String {
        var s = Screen(style: style)
        s.type(keys + " ")
        return String(s.text.dropLast())
    }
}
