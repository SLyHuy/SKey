import Testing
@testable import SKeyEngine

/// Runs every word of `EnglishCorpus` (code keywords, types, identifiers, tools, git/shell,
/// everyday English) through the engine. SKey never corrects words afterwards, like Unikey
/// with spell checking off, so some English words take Vietnamese marks. Each of those is
/// listed with what it becomes and the spelling that types it: double one mark key.
struct EnglishCorpusTests {
    /// (typed, what appears, how to type the English word)
    static let changed: [(word: String, shown: String, escape: String)] = [
        ("affect", "afect", "afffect"), ("ansible", "ánible", "anssible"), ("are", "ảe", "arre"),
        ("args", "ảgs", "arrgs"), ("array", "aray", "arrray"), ("arrow", "arow", "arrrow"),
        ("as", "á", "ass"), ("ask", "ák", "assk"), ("asked", "áked", "assked"),
        ("assert", "asert", "asssert"), ("assess", "asess", "asssess"),
        ("associatedtype", "asociatedtype", "asssociatedtype"), ("astro", "átro", "asstro"),
        ("async", "aýnc", "assync"), ("await", "âit", "aawait"), ("awk", "ăk", "awwk"),
        ("aws", "ắ", "awws"), ("banana", "banna", "baanana"), ("bar", "bả", "barr"),
        ("base", "báe", "basse"), ("bash", "báh", "bassh"), ("best", "bét", "besst"),
        ("book", "bôk", "boook"), ("bool", "bôl", "boool"), ("boolean", "bôlean", "booolean"),
        ("boot", "bôt", "booot"), ("borrow", "borow", "borrrow"), ("boss", "bos", "bosss"),
        ("box", "bõ", "boxx"), ("buffer", "bufer", "bufffer"), ("bus", "bú", "buss"),
        ("car", "cả", "carr"), ("cargo", "cảgo", "carrgo"), ("carry", "cary", "carrry"),
        ("case", "cáe", "casse"), ("cases", "caes", "casses"), ("char", "chả", "charr"),
        ("cherry", "chery", "cherrry"), ("chess", "ches", "chesss"), ("chore", "chỏe", "chorre"),
        ("chown", "chơn", "chowwn"), ("coco", "côc", "cooco"), ("cocoa", "côca", "coocoa"),
        ("coffee", "cofee", "cofffee"), ("config", "cònig", "conffig"),
        ("console", "cốnle", "conssole"), ("const", "cónt", "consst"),
        ("cookie", "côkie", "coookie"), ("cool", "côl", "coool"), ("core", "cỏe", "corre"),
        ("correct", "corect", "corrrect"), ("curl", "củl", "currl"),
        ("current", "curent", "currrent"), ("cursor", "củo", "currsor"),
        ("custom", "cútom", "cusstom"), ("dad", "đa", "ddad"), ("data", "dât", "daata"),
        ("def", "dè", "deff"), ("default", "deàult", "deffault"), ("defer", "dể", "deffer"),
        ("describe", "décribe", "desscribe"), ("did", "đi", "ddid"), ("died", "đie", "ddied"),
        ("diff", "dif", "difff"), ("differ", "difer", "difffer"), ("dir", "dỉ", "dirr"),
        ("direct", "diẻct", "dirrect"), ("docs", "dóc", "docss"), ("does", "dóe", "doess"),
        ("effect", "efect", "efffect"), ("effort", "efort", "efffort"), ("err", "er", "errr"),
        ("error", "eror", "errror"), ("errors", "erors", "errrors"), ("eslint", "élint", "esslint"),
        ("estimate", "étimate", "esstimate"), ("except", "ẽcept", "exxcept"),
        ("expect", "ẽpect", "exxpect"), ("export", "ẽport", "exxport"),
        ("express", "ẽpress", "exxpress"), ("extends", "ẽtends", "exxtends"),
        ("extension", "ẽtension", "exxtension"), ("gas", "gá", "gass"), ("goes", "góe", "goess"),
        ("good", "gôd", "goood"), ("google", "gôgle", "gooogle"), ("goto", "gôt", "gooto"),
        ("guard", "guảd", "guarrd"), ("guess", "gues", "guesss"), ("hard", "hảd", "harrd"),
        ("has", "há", "hass"), ("hash", "háh", "hassh"), ("her", "hẻ", "herr"),
        ("hex", "hẽ", "hexx"), ("his", "hí", "hiss"), ("hook", "hôk", "hoook"),
        ("horror", "horor", "horrror"), ("host", "hót", "hosst"), ("how", "hơ", "howw"),
        ("hurry", "hury", "hurrry"), ("if", "ì", "iff"), ("infix", "ìnix", "inffix"),
        ("info", "ìno", "inffo"), ("insert", "ínert", "inssert"),
        ("instanceof", "íntanceof", "insstanceof"), ("ipsum", "ípum", "ipssum"), ("is", "í", "iss"),
        ("isEmpty", "iÉmpty", "issEmpty"), ("issue", "isue", "isssue"),
        ("issues", "isues", "isssues"), ("its", "ít", "itss"), ("keep", "kêp", "keeep"),
        ("kiss", "kis", "kisss"), ("last", "lát", "lasst"), ("law", "lă", "laww"),
        ("left", "lèt", "lefft"), ("less", "les", "lesss"), ("list", "lít", "lisst"),
        ("listener", "lítener", "lisstener"), ("look", "lôk", "loook"), ("loop", "lôp", "looop"),
        ("lorem", "loẻm", "lorrem"), ("loss", "los", "losss"), ("mar", "mả", "marr"),
        ("marry", "mary", "marrry"), ("mass", "mas", "masss"), ("master", "máter", "masster"),
        ("max", "mã", "maxx"), ("meeting", "mêting", "meeeting"), ("merge", "mẻge", "merrge"),
        ("mess", "mes", "messs"), ("message", "mesage", "messsage"), ("mirror", "miror", "mirrror"),
        ("miss", "mis", "misss"), ("mix", "mĩ", "mixx"), ("mongo", "mông", "moongo"),
        ("more", "mỏe", "morre"), ("most", "mót", "mosst"), ("moto", "môt", "mooto"),
        ("mysql", "mýql", "myssql"), ("narrow", "narow", "narrrow"), ("nest", "nét", "nesst"),
        ("next", "nẽt", "nexxt"), ("nor", "nỏ", "norr"), ("now", "nơ", "noww"),
        ("nuxt", "nũt", "nuxxt"), ("of", "ò", "off"), ("offer", "ofer", "offfer"),
        ("office", "ofice", "offfice"), ("offset", "ofset", "offfset"), ("or", "ỏ", "orr"),
        ("origin", "oỉgin", "orrigin"), ("papa", "pâp", "paapa"), ("par", "pả", "parr"),
        ("params", "pấm", "parrams"), ("parse", "páe", "parrse"), ("pass", "pas", "passs"),
        ("password", "pasword", "passsword"), ("per", "pẻ", "perr"), ("perf", "pè", "perrf"),
        ("photo", "phôt", "phooto"), ("port", "pỏt", "porrt"), ("possess", "posess", "posssess"),
        ("postfix", "pótfix", "posstfix"), ("postgres", "potgres", "posstgres"),
        ("power", "pơer", "powwer"), ("push", "púh", "pussh"), ("query", "quẻy", "querry"),
        ("queue", "quêu", "queeue"), ("raise", "raíe", "raisse"), ("ref", "rè", "reff"),
        ("refactor", "reàctor", "reffactor"), ("reflex", "rèlex", "refflex"), ("res", "ré", "ress"),
        ("reset", "rết", "resset"), ("response", "reponse", "ressponse"),
        ("result", "reúlt", "ressult"), ("risk", "rík", "rissk"), ("row", "rơ", "roww"),
        ("rows", "rớ", "rowws"), ("rust", "rút", "russt"), ("safe", "sàe", "saffe"),
        ("saw", "să", "saww"), ("see", "sê", "seee"), ("server", "sever", "serrver"),
        ("session", "sesion", "sesssion"), ("sex", "sẽ", "sexx"), ("sir", "sỉ", "sirr"),
        ("sis", "sí", "siss"), ("six", "sĩ", "sixx"), ("sorry", "sory", "sorrry"),
        ("sort", "sỏt", "sorrt"), ("suffer", "sufer", "sufffer"), ("sure", "sủe", "surre"),
        ("tar", "tả", "tarr"), ("task", "ták", "tassk"), ("tasks", "taks", "tassks"),
        ("tax", "tã", "taxx"), ("terraform", "teraform", "terrraform"),
        ("terror", "teror", "terrror"), ("test", "tét", "tesst"), ("tests", "tets", "tessts"),
        ("theme", "thêm", "theeme"), ("this", "thí", "thiss"), ("tomorrow", "tômrow", "toomorrow"),
        ("too", "tô", "tooo"), ("took", "tôk", "toook"), ("toss", "tos", "tosss"),
        ("transient", "tránient", "transsient"), ("tree", "trê", "treee"),
        ("unsafe", "únafe", "unssafe"), ("uri", "ủi", "urri"), ("url", "ủl", "urrl"),
        ("use", "úe", "usse"), ("useState", "uéState", "usseState"), ("user", "ủe", "usser"),
        ("userId", "uẻId", "usserId"), ("users", "úe", "ussers"), ("var", "vả", "varr"),
        ("vercel", "vẻcel", "verrcel"), ("verify", "veỉfy", "verrify"),
        ("version", "veíon", "verrsion"), ("yes", "ýe", "yess"),
        ("yesterday", "yếtrday", "yessterday"),
    ]

    static let unchanged: [String] = {
        let changedWords = Set(changed.map(\.word))
        return EnglishCorpus.all.filter { !changedWords.contains($0) }
    }()

    @Test(arguments: unchanged)
    func staysEnglish(_ word: String) {
        #expect(Screen.word(word) == word)
    }

    @Test(arguments: changed)
    func takesVietnameseMarks(_ word: String, _ shown: String, _ escape: String) {
        #expect(Screen.word(word) == shown)
    }

    /// Every changed word can still be typed in Vietnamese mode by doubling one key.
    @Test(arguments: changed)
    func doubledKeyTypesTheEnglishWord(_ word: String, _ shown: String, _ escape: String) {
        #expect(Screen.word(escape) == word, "\(escape) should give \(word)")
    }
}
