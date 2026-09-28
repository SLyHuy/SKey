import Testing
@testable import SKeyEngine

struct TelexCasesTests {
    static let words: [(String, String)] = [
        // Basics and tones
        ("xin", "xin"), ("chaof", "chào"), ("ban", "ban"), ("baanj", "bận"), ("khoong", "không"),
        ("tieengs", "tiếng"), ("tieesng", "tiếng"), ("vieejt", "việt"), ("vieetj", "việt"),
        ("Vieejt", "Việt"), ("VIEEJT", "VIỆT"), ("mootj", "một"), ("hai", "hai"), ("ba", "ba"),
        ("boons", "bốn"), ("nawm", "năm"), ("sasu", "sáu"), ("bayr", "bảy"), ("tams", "tám"),
        ("chins", "chín"), ("muwowif", "mười"), ("ddepj", "đẹp"), ("raats", "rất"),
        ("asf", "à"), ("tieengsf", "tiềng"), ("asz", "a"), ("chaofz", "chao"),
        // đ
        ("ddi", "đi"), ("DDi", "Đi"), ("Ddi", "Đi"), ("ddaay", "đây"), ("ddeemf", "đềm"),
        // ư ơ ươ
        ("nguowif", "người"), ("dduowcj", "được"), ("tuwowng", "tương"), ("truwowngf", "trường"),
        ("truongwf", "trường"), ("duongw", "dương"), ("truwongf", "trường"), ("tuowi", "tươi"),
        ("ruowuj", "rượu"), ("uwowcs", "ước"), ("muaw", "mưa"), ("muwa", "mưa"), ("guwir", "gửi"),
        ("nhuw", "như"), ("tuw", "tư"), ("uw", "ư"), ("ow", "ơ"), ("thuowr", "thuở"),
        ("huow", "huơ"), ("mow", "mơ"),
        // ă â ê ô
        ("hoawcj", "hoặc"), ("xoawn", "xoăn"), ("xuaan", "xuân"), ("tuaanf", "tuần"),
        ("caau", "câu"), ("caua", "câu"), ("tooi", "tôi"), ("nhaf", "nhà"), ("ddeem", "đêm"),
        ("muoons", "muốn"), ("cuoocj", "cuộc"),
        // qu, gi
        ("quyeenr", "quyển"), ("quoocs", "quốc"), ("quas", "quá"), ("quyts", "quýt"),
        ("gif", "gì"), ("giaf", "già"), ("gieengs", "giếng"), ("giuwowngf", "giường"),
        ("giuwx", "giữ"), ("gionf", "giòn"),
        // Clusters
        ("khuyeen", "khuyên"), ("chuyeenj", "chuyện"), ("yeeu", "yêu"), ("yeen", "yên"),
        ("hoafn", "hoàn"), ("huyfnh", "huỳnh"), ("tuyeetj", "tuyệt"), ("ngoaif", "ngoài"),
        ("khuyur", "khuỷu"), ("ngoeof", "ngoèo"), ("ddoongf", "đồng"), ("nghiax", "nghĩa"),
        ("kyx", "kỹ"), ("ghi", "ghi"), ("thichs", "thích"), ("xanh", "xanh"), ("keenhj", "kệnh"),
    ]

    @Test(arguments: words)
    func word(_ keys: String, _ expected: String) {
        #expect(Screen.word(keys) == expected)
    }

    static let toneStyles: [(String, String, String)] = [
        // keys, old style, new style
        ("hoaf", "hòa", "hoà"), ("thuys", "thúy", "thuý"), ("khoer", "khỏe", "khoẻ"),
        ("hoafn", "hoàn", "hoàn"), ("mias", "mía", "mía"), ("tuis", "túi", "túi"),
    ]

    @Test(arguments: toneStyles)
    func toneStyle(_ keys: String, _ old: String, _ new: String) {
        #expect(Screen.word(keys, style: .old) == old)
        #expect(Screen.word(keys, style: .new) == new)
    }

    /// A w with no vowel before it is just "w" (not Unikey's ư): type "uw" for ư.
    static let lonelyW: [(String, String)] = [
        ("w", "w"), ("ww", "ww"), ("www", "www"), ("tw", "tw"), ("nhw", "nhw"), ("W", "W"),
        ("what", "what"), ("while", "while"), ("wget", "wget"), ("uw", "ư"), ("Uw", "Ư"),
    ]

    @Test(arguments: lonelyW)
    func lonelyWStaysW(_ keys: String, _ expected: String) {
        #expect(Screen.word(keys) == expected)
    }

    @Test func sentence() {
        var s = Screen()
        s.type("Tieengs Vieejt raast ddepj, tooi yeeu Vieejt Nam! ")
        #expect(s.text == "Tiếng Việt rất đẹp, tôi yêu Việt Nam! ")
    }

    @Test func mixedLanguageComment() {
        var s = Screen()
        s.type("// Hafm nafy check usser login, return true neeus howpj leej. ")
        #expect(s.text == "// Hàm này check user login, return true nếu hợp lệ. ")
    }

    @Test func outputIsPrecomposed() {
        for (keys, _) in Self.words {
            let out = Screen.word(keys)
            #expect(out.unicodeScalars.count == out.count, "\(keys) → \(out) is not NFC")
        }
    }
}
