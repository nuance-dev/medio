import AppKit

class CustomTextView: NSTextView {
    var placeholderAttributedString: NSAttributedString? {
        didSet {
            needsDisplay = true
        }
    }

    override func drawBackground(in rect: NSRect) {
        super.drawBackground(in: rect)

        if string.isEmpty, let placeholder = placeholderAttributedString {
            let padding = textContainer?.lineFragmentPadding ?? 5.0
            let originX = textContainerInset.width + padding
            let originY = textContainerInset.height
            let targetRect = NSRect(
                x: originX,
                y: originY,
                width: max(0, bounds.width - originX - textContainerInset.width),
                height: max(0, bounds.height - originY - textContainerInset.height)
            )
            placeholder.draw(with: targetRect, options: [.usesLineFragmentOrigin, .usesFontLeading])
        }
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        needsDisplay = true
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        needsDisplay = true
        return result
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "z":
                if event.modifierFlags.contains(.shift) {
                    return undoManager?.redo() != nil
                } else {
                    return undoManager?.undo() != nil
                }
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}
