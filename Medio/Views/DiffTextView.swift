import SwiftUI
import AppKit

struct DiffTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var comparisonText: String
    var side: DiffSide

    static let textDidChangeNotification = NSNotification.Name("DiffTextViewDidChangeNotification")

    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()

        // Create line numbers view
        let lineNumbersView = LineNumberView()
        lineNumbersView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(lineNumbersView)

        // Create scroll view and text view
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        let textView = CustomTextView()

        // Configure text view
        textView.allowsUndo = true
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular) // Ensured font size matches LineNumberView
        textView.textContainerInset = NSSize(width: 5, height: 5)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.backgroundColor = .clear

        // Configure scroll view
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false

        containerView.addSubview(scrollView)

        // Set up constraints
        NSLayoutConstraint.activate([
            lineNumbersView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            lineNumbersView.topAnchor.constraint(equalTo: containerView.topAnchor),
            lineNumbersView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            lineNumbersView.widthAnchor.constraint(equalToConstant: 40),

            scrollView.leadingAnchor.constraint(equalTo: lineNumbersView.trailingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        // Set up line numbers view
        lineNumbersView.textView = textView

        // Store references in coordinator
        context.coordinator.textView = textView
        context.coordinator.lineNumbersView = lineNumbersView

        // Set up notifications
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleTextChange(_:)),
            name: DiffTextView.textDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleAppearanceChange(_:)),
            name: AppearanceManager.appearanceDidChangeNotification,
            object: nil
        )

        return containerView
    }

    func updateNSView(_ containerView: NSView, context: Context) {
        guard let textView = context.coordinator.textView else { return }

        if !context.coordinator.isEditing && textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            textView.setSelectedRange(selectedRange)
            highlightDifferences(in: textView)
            context.coordinator.lineNumbersView?.needsDisplay = true
        }
    }

    private func highlightDifferences(in textView: NSTextView) {
        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.utf16.count)

        attributedString.addAttributes([
            .foregroundColor: NSColor.labelColor,
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular) // Ensure font size matches
        ], range: fullRange)

        let analyzer = DiffAnalyzer(sourceText: text, targetText: comparisonText)
        let diffs = analyzer.computeDifferences()

        for lineDiff in diffs {
            guard lineDiff.range.location + lineDiff.range.length <= text.utf16.count else { continue }

            if lineDiff.isDifferent {
                let backgroundColor = side == .left ?
                    NSColor.systemRed.withAlphaComponent(0.2) :
                    NSColor.systemGreen.withAlphaComponent(0.2)

                attributedString.addAttribute(.backgroundColor, value: backgroundColor, range: lineDiff.range)

                for wordDiff in lineDiff.wordDiffs {
                    guard wordDiff.range.location + wordDiff.range.length <= text.utf16.count else { continue }

                    let foregroundColor = side == .left ?
                        NSColor.systemRed :
                        NSColor(calibratedRed: 0, green: 0.6, blue: 0, alpha: 1.0)

                    attributedString.addAttributes([
                        .foregroundColor: foregroundColor,
                        .backgroundColor: backgroundColor
                    ], range: wordDiff.range)
                }
            }
        }

        textView.textStorage?.setAttributedString(attributedString)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: DiffTextView
        var isEditing = false
        var isProcessingChange = false
        weak var textView: NSTextView?
        weak var lineNumbersView: LineNumberView?

        init(_ parent: DiffTextView) {
            self.parent = parent
        }

        func textDidBeginEditing(_ notification: Notification) {
            isEditing = true
        }

        func textDidEndEditing(_ notification: Notification) {
            isEditing = false
            if let textView = notification.object as? NSTextView {
                updateText(from: textView)
            }
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                  !isProcessingChange else { return }

            updateText(from: textView)
            lineNumbersView?.needsDisplay = true

            NotificationCenter.default.post(
                name: DiffTextView.textDidChangeNotification,
                object: nil,
                userInfo: ["side": parent.side]
            )
        }

        @objc func handleTextChange(_ notification: Notification) {
            guard let userInfo = notification.userInfo,
                  let side = userInfo["side"] as? DiffSide,
                  side != parent.side,
                  let textView = self.textView else { return }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.parent.highlightDifferences(in: textView)
            }
        }

        @objc func handleAppearanceChange(_ notification: Notification) {
            guard let textView = self.textView else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.parent.highlightDifferences(in: textView)
                self.lineNumbersView?.needsDisplay = true
            }
        }

        private func updateText(from textView: NSTextView) {
            isProcessingChange = true

            let currentRange = textView.selectedRange()
            let visibleRect = textView.visibleRect

            parent.text = textView.string

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.parent.highlightDifferences(in: textView)

                if currentRange.location <= textView.string.count {
                    textView.setSelectedRange(currentRange)
                    textView.scrollToVisible(visibleRect)
                }

                self.isProcessingChange = false
            }
        }
    }
}
