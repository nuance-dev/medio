import SwiftUI
import AppKit

struct ContentView: View {
    @State private var leftText = ""
    @State private var rightText = ""
    
    var body: some View {
        ZStack {
            VisualEffectBlur(material: .headerView, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            HStack(spacing: 0) {
                DiffTextView(text: $leftText, comparisonText: $rightText, side: .left)
                Divider()
                    .background(Color(NSColor.separatorColor))
                DiffTextView(text: $rightText, comparisonText: $leftText, side: .right)
            }
            .padding()
        }
    }
}
