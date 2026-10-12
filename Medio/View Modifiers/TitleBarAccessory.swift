import SwiftUI

struct TitleBarAccessory: View {
    @ObservedObject private var appearanceManager = AppearanceManager.shared
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                appearanceManager.cycleAppearance()
            }
        }) {
            Image(systemName: appearanceManager.appearanceMode.iconName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .help("Appearance: \(appearanceManager.appearanceMode.title) (Click to switch)")
        .contextMenu {
            ForEach(AppearanceMode.allCases) { mode in
                Button(action: { appearanceManager.setAppearance(mode) }) {
                    HStack {
                        Text(mode.title)
                        if appearanceManager.appearanceMode == mode {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }
}
