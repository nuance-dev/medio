import AppKit

class LineNumberView: NSView {
    weak var textView: NSTextView? {
        didSet {
            // Remove previous observer if any
            if let oldTextView = oldValue {
                oldTextView.enclosingScrollView?.contentView.postsBoundsChangedNotifications = false
                if let layoutManager = oldTextView.layoutManager, let index = layoutManager.textContainers.firstIndex(of: textContainer) {
                    layoutManager.removeTextContainer(at: index)
                }
            }

            if let textView = textView {
                // Ensure the scroll view's content view posts bounds changed notifications
                textView.enclosingScrollView?.contentView.postsBoundsChangedNotifications = true
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(handleTextViewBoundsChange(_:)),
                    name: NSView.boundsDidChangeNotification,
                    object: textView.enclosingScrollView?.contentView
                )

                // Add text container to layout manager
                if let layoutManager = textView.layoutManager {
                    layoutManager.addTextContainer(textContainer)
                }
            }
        }
    }

    private let font: NSFont = .monospacedSystemFont(ofSize: 14, weight: .regular) // Ensured font size matches
    private let textContainer: NSTextContainer

    override init(frame frameRect: NSRect) {
        self.textContainer = NSTextContainer(size: NSSize(width: 0, height: 0))
        super.init(frame: frameRect)
        setupTextContainer()
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        self.textContainer = NSTextContainer(size: NSSize(width: 0, height: 0))
        super.init(coder: coder)
        setupTextContainer()
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    private func setupTextContainer() {
        textContainer.widthTracksTextView = false
        textContainer.heightTracksTextView = false
    }

    // Ensure the view uses a flipped coordinate system
    override var isFlipped: Bool {
        return true
    }

    @objc private func handleTextViewBoundsChange(_ notification: Notification) {
        self.needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let textView = self.textView,
              let layoutManager = textView.layoutManager,
              let container = textView.textContainer,
              let content = textView.string as NSString? else {
            return
        }

        // Set the font for line numbers
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.secondaryLabelColor
        ]

        // Use the textView's visibleRect
        let visibleRect = textView.visibleRect

        // Calculate the range of glyphs that's currently visible
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: container)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        // Enumerate through each line in the visible range
        let nsString = content as NSString
        if nsString.length == 0 {
            let lineNumberString = "1"
            let stringSize = (lineNumberString as NSString).size(withAttributes: attributes)
            let xPosition = self.bounds.width - stringSize.width - 8
            let yPosition = textView.textContainerInset.height - visibleRect.origin.y
            (lineNumberString as NSString).draw(
                at: NSPoint(x: xPosition, y: yPosition),
                withAttributes: attributes
            )
            return
        }
        var lineNumber = nsString.substring(to: characterRange.location).components(separatedBy: .newlines).count
        if lineNumber == 0 {
            lineNumber = 1
        }

        // Enumerate lines within the visible character range
        nsString.enumerateSubstrings(in: characterRange, options: [.byLines, .substringNotRequired]) { (substring, lineRange, _, _) in
            // Get the glyph range for the current line
            let lineGlyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)

            // Get the line fragment rect for the first glyph in the line
            let lineFragmentRect = layoutManager.lineFragmentRect(forGlyphAt: lineGlyphRange.location, effectiveRange: nil)

            // Adjust yPosition to account for scrolling
            let yPosition = lineFragmentRect.origin.y + textView.textContainerInset.height - visibleRect.origin.y

            // Prepare the line number string
            let lineNumberString = "\(lineNumber)"

            // Calculate the size of the line number string
            let stringSize = (lineNumberString as NSString).size(withAttributes: attributes)

            // Right align with consistent padding (e.g., 8 pixels)
            let xPosition = self.bounds.width - stringSize.width - 8

            // Draw the line number string
            (lineNumberString as NSString).draw(
                at: NSPoint(x: xPosition, y: yPosition),
                withAttributes: attributes
            )

            lineNumber += 1
        }

        // Handle the case where the text ends with a newline character
        if nsString.hasSuffix("\n") {
            let lastGlyphIndex = layoutManager.numberOfGlyphs
            let lineFragmentRect = layoutManager.lineFragmentRect(forGlyphAt: lastGlyphIndex - 1, effectiveRange: nil)
            let yPosition = lineFragmentRect.origin.y + lineFragmentRect.height + textView.textContainerInset.height - visibleRect.origin.y

            let lineNumberString = "\(lineNumber)"
            let stringSize = (lineNumberString as NSString).size(withAttributes: attributes)
            let xPosition = self.bounds.width - stringSize.width - 8

            (lineNumberString as NSString).draw(
                at: NSPoint(x: xPosition, y: yPosition),
                withAttributes: attributes
            )
        }
    }
    deinit {
        // Remove observer to prevent memory leaks
        NotificationCenter.default.removeObserver(self)
    }
}
