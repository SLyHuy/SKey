import AppKit
import SKeyEngine

/// Decides what every key does: feed the Telex engine, end a word, toggle the language,
/// or just pass through. The typing session tracks the text before the caret; anything
/// that may move the caret tells it so, and it asks the app again when needed.
@MainActor
final class KeyRouter: KeyboardTapDelegate {
    private let state: AppState
    private var session = TypingSession()
    private var chord = ModifierChord()

    /// Called when the hotkey toggles the language.
    var onToggle: (() -> Void)?

    init(state: AppState) {
        self.state = state
    }

    func reset() {
        session.cursorMoved()
        chord.cancel()
    }

    func keyboardTap(_ tap: KeyboardTap, shouldPass event: CGEvent, type: CGEventType) -> Bool {
        switch type {
        case .keyDown:
            return handleKeyDown(event, tap: tap)
        case .flagsChanged:
            if let target = state.hotkey.chord, chord.flagsChanged(event.flags, target: target) {
                toggle()
            }
            return true
        default:  // mouse down: the cursor may have moved
            reset()
            return true
        }
    }

    private func handleKeyDown(_ event: CGEvent, tap: KeyboardTap) -> Bool {
        chord.cancel()
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        if state.hotkey.matchesKeyDown(keyCode: keyCode, flags: flags) {
            toggle()
            return false
        }
        guard state.isComposing else {
            session.cursorMoved()
            return true
        }
        // Shortcuts (⌘C, ⌃A, ⌥-letters…) may move the cursor or change the text.
        if !flags.intersection([.maskCommand, .maskControl, .maskAlternate]).isEmpty {
            session.cursorMoved()
            return true
        }

        switch keyCode {
        case KeyCode.delete:
            session.backspace()
            return true
        case _ where KeyCode.cursorMoving.contains(keyCode):
            session.cursorMoved()
            return true
        default:
            break
        }

        let ch = Self.character(of: event)
        if let ch, ch.isASCII, ch.isLetter {
            session.engine.toneStyle = state.toneStyle
            let lookUp = state.editPreviousWords
            let edit = session.letter(ch, context: { lookUp ? TextContext.beforeCaret() : nil })
            if edit.deleteCount == 0, edit.insert == String(ch) { return true }  // plain letter
            apply(edit, tap: tap)
            return false
        }

        // Space, digits, punctuation end the word; Enter, Tab (or no character) also leave
        // the line, so what is before the caret is unknown afterwards.
        let edit: Edit?
        if let ch, ch != "\r", ch != "\n", ch != "\t" {
            edit = session.wordBreak(ch)
        } else {
            edit = session.wordBreak(" ")
            session.cursorMoved()
        }
        guard let edit else { return true }
        apply(edit, tap: tap)
        tap.repost(event)
        return false
    }

    private func apply(_ edit: Edit, tap: KeyboardTap) {
        var deletes = edit.deleteCount
        if deletes > 0, state.fixSuggestions {
            // Inline predictions (gray text after the cursor) and address-bar autocomplete
            // swallow our Backspace/insert. Typing an invisible character first dismisses
            // or replaces the suggestion; one extra Backspace removes it again.
            tap.postText("\u{202F}")
            deletes += 1
        }
        tap.postBackspaces(deletes)
        tap.postText(edit.insert)
    }

    private func toggle() {
        session.cursorMoved()
        onToggle?()
    }

    private static func character(of event: CGEvent) -> Character? {
        var length = 0
        var buffer = [UniChar](repeating: 0, count: 4)
        event.keyboardGetUnicodeString(maxStringLength: buffer.count, actualStringLength: &length, unicodeString: &buffer)
        guard length == 1 else { return nil }
        return String(utf16CodeUnits: buffer, count: 1).first
    }
}

private enum KeyCode {
    static let delete: Int64 = 51
    /// Keys that move the cursor or leave the field: arrows, Home/End, Page Up/Down,
    /// forward delete, Escape, F1–F20.
    static let cursorMoving: Set<Int64> = [
        123, 124, 125, 126, 115, 119, 116, 121, 117, 53,
        122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111, 105, 107, 113, 106, 64, 79, 80, 90,
    ]
}
