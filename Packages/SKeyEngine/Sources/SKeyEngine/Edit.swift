/// What the input layer must do to the text on screen: press Backspace
/// `deleteCount` times, then type `insert`.
public struct Edit: Equatable, Sendable {
    public var deleteCount: Int
    public var insert: String

    public init(deleteCount: Int, insert: String) {
        self.deleteCount = deleteCount
        self.insert = insert
    }

    public var isEmpty: Bool { deleteCount == 0 && insert.isEmpty }

    /// Smallest edit turning `old` into `new`: keep the common prefix, redo the rest.
    /// Output is always precomposed (NFC), so one Character == one Backspace.
    static func between(_ old: String, _ new: String) -> Edit {
        let o = Array(old), n = Array(new)
        var i = 0
        while i < o.count, i < n.count, o[i] == n[i] { i += 1 }
        return Edit(deleteCount: o.count - i, insert: String(n[i...]))
    }
}

/// Where the tone mark goes in the two-vowel clusters oa, oe, uy without a final consonant.
public enum ToneStyle: String, Sendable, CaseIterable {
    /// hòa, hòe, thúy
    case old
    /// hoà, hoè, thuý
    case new
}
