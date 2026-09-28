import AppKit

/// Input-source badges drawn like macOS' own ("A", "VI"): a filled rounded rectangle with
/// the letters knocked out, same fixed size for every badge. Template images, so macOS
/// tints them for light/dark menu bars and highlighted menu items.
@MainActor
enum StatusIcon {
    static let vietnamese = badge("VI")
    static let english = badge("EN")

    /// Measured from the system badges: 22 × 16 pt, ~4 pt corners, cap height ≈ half.
    private static let size = NSSize(width: 22, height: 16)
    private static let cornerRadius: CGFloat = 4
    private static let font = NSFont.systemFont(ofSize: 11.5, weight: .bold)

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
}

private extension CGFloat {
    func rounded(toMultipleOf step: CGFloat) -> CGFloat {
        (self / step).rounded() * step
    }
}
