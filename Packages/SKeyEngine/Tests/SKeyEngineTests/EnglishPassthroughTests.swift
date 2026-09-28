import Testing
@testable import SKeyEngine

/// Whole lines of code and comments. English words that would take Vietnamese marks are
/// typed with a doubled mark key (consst, usser, dataa), as the user does in practice.
struct EnglishPassthroughTests {
    @Test func codeLine() {
        var s = Screen()
        s.type("consst usserName = getUser(id) ")
        #expect(s.text == "const userName = getUser(id) ")
    }

    @Test func codeWithVietnameseComment() {
        var s = Screen()
        s.type("let dataa = fetch(urrl) // laays duwx lieeuj tuwf serrver, neeus looix thif return null ")
        #expect(s.text == "let data = fetch(url) // lấy dữ liệu từ server, nếu lỗi thì return null ")
    }

    @Test func gitCommitMessage() {
        var s = Screen()
        s.type("git commit -m \"fix: suwra looix gox nhanh\" ")
        #expect(s.text == "git commit -m \"fix: sửa lỗi gõ nhanh\" ")
    }

    /// Code the user typed while testing.
    static let reported = ["writeFunc", "throw", "for", "while", "function", "throwError"]

    @Test(arguments: reported)
    func reportedCodeWords(_ word: String) {
        #expect(Screen.word(word) == word)
    }
}
