/// Tracks the text right before the caret across words, so a finished word can still be
/// edited: type "tân ", Backspace, then "j" → "tận". When the caret moved somewhere
/// unknown (click, arrows), the first mark key asks `context` for the text before the caret.
///
/// Invariant: `before` + `engine.text` is exactly what sits before the caret, as far as the
/// session knows. Anything that may break that (cursor moves) calls `cursorMoved()`.
public struct TypingSession: Sendable {
    public var engine: TelexEngine

    /// Text before the current word (bounded), valid while `contextKnown`.
    private var before = ""
    private var contextKnown = false

    private static let beforeLimit = 64

    /// Text before the caret and whether a letter follows the caret.
    public typealias Context = (before: String, letterAfter: Bool)

    public init(toneStyle: ToneStyle = .old) {
        engine = TelexEngine(toneStyle: toneStyle)
    }

    /// Feeds a letter. If the caret context is unknown and the key can change a word,
    /// the word before the caret is taken over first (only when the caret is at its end).
    public mutating func letter(_ ch: Character, context: () -> Context?) -> Edit {
        if engine.isEmpty, !contextKnown {
            contextKnown = true
            before = ""
            if Self.isMarkKey(ch), let c = context(), !c.letterAfter {
                adopt(c.before)
            }
        }
        return engine.process(ch)
    }

    /// Space, punctuation or a digit ended the word; `ch` is typed after the returned edit.
    public mutating func wordBreak(_ ch: Character) -> Edit? {
        let shown = engine.text
        let edit = engine.finalize()
        let committed = edit.map { String(shown.dropLast($0.deleteCount)) + $0.insert } ?? shown
        before = String((before + committed + String(ch)).suffix(Self.beforeLimit))
        contextKnown = true
        return edit
    }

    /// The app deleted the character before the caret. Stepping back into a finished word
    /// makes it editable again.
    public mutating func backspace() {
        if !engine.isEmpty {
            engine.backspace()
            return
        }
        guard !before.isEmpty else {
            contextKnown = false
            return
        }
        before.removeLast()
        let word = TelexEngine.trailingWord(of: before)
        if !word.isEmpty {
            before.removeLast(word.count)
            engine.load(word)
        } else if before.isEmpty {
            contextKnown = false  // past everything we know; ask again if needed
        }
    }

    /// Click, arrows, app switch, shortcut, Enter…: the text before the caret is unknown.
    public mutating func cursorMoved() {
        engine.reset()
        before = ""
        contextKnown = false
    }

    private mutating func adopt(_ text: String) {
        let word = TelexEngine.trailingWord(of: text)
        before = String(text.dropLast(word.count).suffix(Self.beforeLimit))
        engine.load(word)
    }

    /// Keys that can change an existing word: tones, z, circumflex/breve/horn, đ.
    static func isMarkKey(_ ch: Character) -> Bool {
        "sfrxjzaeowd".contains(Character(ch.lowercased()))
    }
}
