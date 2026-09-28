/// Tracks the text right before the caret, so a finished word can still be edited: type
/// "tân ", Backspace, then "j" → "tận". When the caret moved somewhere unknown (click,
/// arrows), the first mark key asks `context` for the text before the caret.
///
/// Privacy by design, it keeps and reads as little as possible:
/// - at most `memoryLength` (21) characters before the current word, in memory only,
///   dropped whenever the caret moves;
/// - at most `contextLength` (14) characters read before the caret, once, not kept beyond
///   the word being edited.
/// Only a word of up to `maxWordLength` (7) letters is ever taken over: no Vietnamese word
/// is longer, so longer ones are English and have nothing to fix.
///
/// Invariant: `before` + `engine.text` is exactly what sits before the caret, as far as the
/// session knows. Anything that may break that (cursor moves) calls `cursorMoved()`.
public struct TypingSession: Sendable {
    public var engine: TelexEngine

    /// Longest Vietnamese word, in letters ("nghiêng", "nghiệp").
    public static let maxWordLength = 7
    /// Characters read before the caret: a 7-letter word plus room for brackets, quotes
    /// and spaces around it.
    public static let contextLength = 14
    /// Characters remembered for Backspace: the context plus one more word.
    public static let memoryLength = contextLength + maxWordLength

    /// Text before the current word, valid while `contextKnown`.
    private var before = ""
    private var contextKnown = false
    /// Whether `before` starts at a word boundary: true where typing began, false once the
    /// start was trimmed from memory (the first letters of a word may be missing).
    private var beforeStartKnown = false

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
            beforeStartKnown = true  // typing starts a word here
            if Self.isMarkKey(ch), let c = context(), !c.letterAfter {
                adopt(String(c.before.suffix(Self.contextLength)))
            }
        }
        return engine.process(ch)
    }

    /// Space, punctuation or a digit ended the word; `ch` is typed after the returned edit.
    public mutating func wordBreak(_ ch: Character) -> Edit? {
        let shown = engine.text
        let edit = engine.finalize()
        let committed = edit.map { String(shown.dropLast($0.deleteCount)) + $0.insert } ?? shown
        remember(before + committed + String(ch))
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
            forget()
            return
        }
        before.removeLast()
        let word = TelexEngine.trailingWord(of: before)
        guard !word.isEmpty else {
            if before.isEmpty { forget() }  // past everything we know
            return
        }
        let wholeWordKnown = word.count < before.count || beforeStartKnown
        if word.count <= Self.maxWordLength, wholeWordKnown {
            before.removeLast(word.count)
            engine.load(word)
        } else {
            // Too long to be Vietnamese, or its start was trimmed from memory: stop guessing.
            // The next mark key reads the real text around the caret instead.
            forget()
        }
    }

    /// Click, arrows, app switch, shortcut, Enter…: the text before the caret is unknown.
    public mutating func cursorMoved() {
        engine.reset()
        forget()
    }

    private mutating func forget() {
        before = ""
        contextKnown = false
        beforeStartKnown = false
    }

    private mutating func remember(_ text: String) {
        before = String(text.suffix(Self.memoryLength))
        if text.count > Self.memoryLength { beforeStartKnown = false }
    }

    private mutating func adopt(_ text: String) {
        let word = TelexEngine.trailingWord(of: text)
        guard word.count <= Self.maxWordLength else { return }
        before = String(text.dropLast(word.count))
        // Fewer characters than asked for means the field starts there.
        beforeStartKnown = text.count < Self.contextLength
        engine.load(word)
    }

    /// Keys that can change an existing word: tones, z, circumflex/breve/horn, đ.
    static func isMarkKey(_ ch: Character) -> Bool {
        "sfrxjzaeowd".contains(Character(ch.lowercased()))
    }
}
