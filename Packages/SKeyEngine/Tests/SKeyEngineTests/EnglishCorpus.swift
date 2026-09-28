/// English words likely to trip a Telex engine: they contain tone keys (s f r x j), w,
/// doubled vowels/d, or a vowel after a consonant. Grouped by where a coder meets them.
enum EnglishCorpus {
    static let keywords = [
        // Swift / Kotlin / TS / JS / Python / Go / Rust / Java / C
        "abstract", "actor", "any", "as", "assert", "associatedtype", "async", "await", "break",
        "case", "catch", "class", "const", "continue", "convenience", "debugger", "def", "default",
        "defer", "del", "delete", "deinit", "do", "dynamic", "elif", "else", "enum", "except",
        "export", "extends", "extension", "fallthrough", "false", "fileprivate", "final",
        "finally", "fn", "for", "from", "fun", "func", "get", "global", "go", "goto", "guard",
        "if", "impl", "implements", "import", "in", "indirect", "infix", "init", "inout",
        "instanceof", "interface", "internal", "is", "lambda", "lazy", "let", "loop", "macro",
        "match", "mod", "module", "mut", "mutating", "namespace", "native", "new", "nil",
        "nonlocal", "none", "not", "null", "object", "of", "open", "operator", "optional", "or",
        "override", "package", "pass", "postfix", "prefix", "private", "protected", "protocol",
        "pub", "public", "raise", "readonly", "rethrows", "return", "some", "static", "struct",
        "subscript", "super", "switch", "sync", "synchronized", "this", "throw", "throws",
        "trait", "transient", "true", "try", "type", "typealias", "typeof", "undefined",
        "unsafe", "use", "var", "void", "volatile", "weak", "where", "while", "with", "yield",
    ]

    static let types = [
        "string", "str", "int", "float", "double", "bool", "char", "byte", "bytes", "array",
        "list", "dict", "map", "set", "tuple", "vector", "slice", "error", "errors", "result",
        "option", "future", "promise", "stream", "buffer", "date", "data", "json", "xml",
        "regex", "uuid", "url", "uri", "path", "file", "files", "dir", "folder", "node",
        "tree", "graph", "queue", "stack", "heap", "hash", "key", "keys", "value", "values",
        "index", "item", "items", "entry", "record", "row", "rows", "column", "table", "view",
        "model", "schema", "query", "cursor", "session", "token", "cookie", "header", "body",
    ]

    static let identifiers = [
        "user", "users", "admin", "role", "roles", "auth", "login", "logout", "signup", "email",
        "password", "reset", "verify", "config", "settings", "options", "params", "args",
        "kwargs", "props", "state", "store", "action", "reducer", "effect", "context", "hook",
        "render", "mount", "update", "create", "read", "write", "remove", "insert", "select",
        "sort", "filter", "reduce", "find", "search", "fetch", "request", "response", "status",
        "message", "event", "events", "handler", "listener", "callback", "timer", "timeout",
        "retry", "cache", "memo", "debug", "info", "warn", "trace", "fatal", "log", "logs",
        "test", "tests", "spec", "mock", "stub", "fixture", "setup", "teardown", "expect",
        "describe", "suite", "case", "cases", "sample", "demo", "todo", "fixme", "hack", "note",
        "draft", "release", "version", "build", "deploy", "server", "client", "socket", "port",
        "host", "proxy", "router", "route", "page", "pages", "layout", "style", "styles",
        "theme", "color", "font", "icon", "image", "video", "audio", "media", "upload", "export",
        "import", "parse", "format", "encode", "decode", "encrypt", "decrypt", "sign", "verify",
        "offset", "limit", "count", "total", "sum", "max", "min", "avg", "size", "length",
        "width", "height", "top", "left", "right", "bottom", "first", "last", "next", "prev",
        "previous", "current", "default", "custom", "base", "core", "utils", "helpers", "lib",
    ]

    static let tools = [
        "git", "github", "gitlab", "npm", "yarn", "pnpm", "brew", "pip", "cargo", "gradle",
        "maven", "docker", "compose", "kubectl", "helm", "terraform", "ansible", "nginx",
        "redis", "postgres", "mysql", "sqlite", "mongo", "kafka", "rabbit", "vite", "webpack",
        "babel", "eslint", "prettier", "jest", "vitest", "pytest", "xcode", "swift", "rust",
        "java", "kotlin", "python", "ruby", "rails", "django", "flask", "fastapi", "react",
        "vue", "svelte", "angular", "next", "nuxt", "remix", "astro", "deno", "bun", "node",
        "express", "nest", "prisma", "drizzle", "supabase", "firebase", "vercel", "netlify",
        "aws", "gcp", "azure", "linux", "macos", "ios", "android", "windows", "ubuntu", "debian",
        "vim", "neovim", "emacs", "tmux", "zsh", "bash", "fish", "curl", "wget", "ssh", "sudo",
        "grep", "sed", "awk", "jq", "make", "cmake", "clang", "gcc", "llvm", "wasm",
    ]

    static let gitAndShell = [
        "commit", "push", "pull", "merge", "rebase", "branch", "checkout", "switch", "stash",
        "cherry", "pick", "revert", "reset", "diff", "status", "clone", "fork", "tag", "fetch",
        "origin", "main", "master", "dev", "staging", "prod", "feat", "fix", "chore", "docs",
        "refactor", "perf", "ci", "cd", "ls", "mv", "cp", "rm", "mkdir", "touch", "cat", "echo",
        "export", "source", "chmod", "chown", "kill", "ps", "top", "df", "du", "tar", "zip",
    ]

    static let common = [
        "the", "and", "for", "are", "but", "not", "you", "all", "any", "can", "her", "was",
        "one", "our", "out", "day", "get", "has", "him", "his", "how", "man", "new", "now",
        "old", "see", "two", "way", "who", "boy", "did", "its", "let", "put", "say", "she",
        "too", "use", "dad", "mom", "yes", "no", "hello", "world", "thanks", "please", "sorry",
        "okay", "great", "good", "nice", "cool", "fine", "sure", "maybe", "done", "doing",
        "does", "goes", "going", "gone", "have", "had", "make", "made", "take", "took", "give",
        "gave", "come", "came", "know", "knew", "think", "thought", "say", "said", "tell",
        "told", "ask", "asked", "work", "works", "working", "worked", "fix", "fixed", "fixes",
        "bug", "bugs", "issue", "issues", "feature", "features", "review", "reviews", "ship",
        "shipped", "meeting", "today", "tomorrow", "yesterday", "week", "month", "year", "time",
        "team", "sprint", "task", "tasks", "ticket", "deadline", "estimate", "done", "blocked",
        "less", "more", "most", "best", "worst", "fast", "slow", "easy", "hard", "safe", "risk",
        "box", "mix", "six", "tax", "fax", "wax", "sex", "hex", "flex", "index", "reflex",
        "car", "bar", "far", "jar", "star", "war", "tar", "mar", "par", "nor", "per", "sir",
        "fur", "her", "err", "ref", "res", "sis", "bus", "gas", "yes", "his", "has", "was",
        "coffee", "office", "offer", "suffer", "differ", "effort", "affect", "effect", "access",
        "success", "process", "address", "express", "impress", "stress", "dress", "press",
        "class", "glass", "grass", "mass", "pass", "boss", "loss", "toss", "cross", "miss",
        "kiss", "bliss", "chess", "mess", "less", "bless", "guess", "assess", "possess",
        "error", "mirror", "terror", "horror", "sorry", "worry", "hurry", "carry", "marry",
        "array", "arrow", "narrow", "borrow", "tomorrow", "current", "correct", "direct",
    ]

    /// Earlier hand-picked lists: code words, words at risk from late marks, reported words.
    static let extra = [
        "GitHub", "Hello", "OK", "SKey", "World", "add", "and", "api", "are", "args", "async",
        "await", "awk", "banana", "base", "beta", "book", "bool", "boolean", "boot", "branch",
        "break", "brew", "cancel", "case", "catch", "class", "coco", "cocoa", "code", "commit",
        "console", "const", "continue", "cool", "curl", "data", "dead", "demo", "deploy", "died",
        "docker", "done", "dota", "draw", "else", "enum", "even", "export", "false", "filter",
        "follow", "for", "forEach", "from", "func", "function", "git", "golang", "gone", "good",
        "google", "grep", "hanoi", "helm", "hidden", "home", "hotdog", "http", "iOS", "import",
        "int", "ipsum", "isEmpty", "java", "json", "keep", "keys", "kid", "king", "kotlin",
        "kubectl", "kwargs", "law", "let", "log", "logo", "look", "lorem", "macOS", "main", "map",
        "master", "memo", "merge", "meta", "moto", "name", "neovim", "new", "nil", "node", "none",
        "not", "npm", "null", "odd", "open", "our", "panel", "papa", "photo", "pnpm", "potato",
        "power", "private", "public", "pull", "push", "python", "rebase", "reduce", "return",
        "ruby", "same", "saw", "sed", "self", "sing", "static", "string", "struct", "sudden",
        "sudo", "super", "swift", "switch", "the", "then", "thing", "things", "throw", "throwError",
        "time", "tmux", "toString", "todo", "token", "tomato", "true", "try", "use", "useState",
        "user", "userId", "users", "view", "vim", "void", "was", "what", "when", "where", "which",
        "while", "window", "windows", "writeFunc", "yarn", "yes", "you", "your",
    ]

    static var all: [String] {
        Array(Set(keywords + types + identifiers + tools + gitAndShell + common + extra)).sorted()
    }
}
