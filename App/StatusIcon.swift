import AppKit

/// Input-source badges drawn like macOS' own ("A", "VI"): a filled rounded rectangle with
/// the letters knocked out, same fixed size for every badge. Template images, so macOS
/// tints them for light/dark menu bars and highlighted menu items.
@MainActor
enum StatusIcon {
    static let vietnamese = badge("VI")
    static let english = badge("EN")
    static let vietnameseLocked = lockedBadge("VI")
    static let englishLocked = lockedBadge("EN")

    /// Measured from the system badges: 22 × 16 pt, ~4 pt corners, cap height ≈ half.
    private static let size = NSSize(width: 22, height: 16)
    private static let lockedSize = NSSize(width: 33, height: 16)
    private static let cornerRadius: CGFloat = 4
    private static let font = NSFont.systemFont(ofSize: 11.5, weight: .bold)
    private static let lockedFont = NSFont.systemFont(ofSize: 10.5, weight: .bold)
    private static let lockSymbolConfig = NSImage.SymbolConfiguration(pointSize: 7.5, weight: .bold)
        .applying(.init(paletteColors: [.white]))

    private static func badge(_ text: String) -> NSImage {
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius).fill()

            let label = NSAttributedString(string: text, attributes: [
                .font: font,
                .foregroundColor: NSColor.black,
                .kern: 0.3,
            ])
            // Center on the capital letters, not the line box (which includes the descender).
            let width = label.size().width - 0.3
            let baseline = (rect.midY - font.capHeight / 2).rounded(toMultipleOf: 0.5)
            let origin = NSPoint(x: rect.midX - width / 2, y: baseline + font.descender)

            NSGraphicsContext.current?.compositingOperation = .destinationOut
            label.draw(at: origin)
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = text == "VI" ? "Tiếng Việt" : "English"
        return image
    }

    private static func lockedBadge(_ text: String) -> NSImage {
        let image = NSImage(size: lockedSize, flipped: false) { rect in
            // Attention-grabbing red badge
            NSColor.systemRed.setFill()
            NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius).fill()

            let label = NSAttributedString(string: text, attributes: [
                .font: lockedFont,
                .foregroundColor: NSColor.white,
                .kern: 0.2,
            ])
            let baseline = (rect.midY - lockedFont.capHeight / 2).rounded(toMultipleOf: 0.5)
            let textOrigin = NSPoint(x: 4.5, y: baseline + lockedFont.descender)
            label.draw(at: textOrigin)

            if let lock = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil)?
                .withSymbolConfiguration(lockSymbolConfig) {
                let lockSize = lock.size
                // Shift y up slightly (+0.75pt) so the lock's shackle and body visually balance with the text
                let lockY = ((rect.height - lockSize.height) / 2 + 0.75).rounded(toMultipleOf: 0.5)
                let lockOrigin = NSPoint(x: rect.maxX - lockSize.width - 4.5, y: lockY)
                lock.draw(at: lockOrigin, from: .zero, operation: .sourceOver, fraction: 1.0)
            }
            return true
        }
        image.isTemplate = false  // Keep vibrant red color in menu bar
        image.accessibilityDescription = text == "VI" ? "Tiếng Việt (Secure Input)" : "English (Secure Input)"
        return image
    }
}

private extension CGFloat {
    func rounded(toMultipleOf step: CGFloat) -> CGFloat {
        (self / step).rounded() * step
    }
}
