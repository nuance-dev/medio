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
            Button(action: { appearanceManager.setAppearance(.auto) }) {
                HStack {
                    Text("Auto (System)")
                    if appearanceManager.appearanceMode == .auto {
                        Image(systemName: "checkmark")
                    }
                }
            }
            Button(action: { appearanceManager.setAppearance(.light) }) {
                HStack {
                    Text("Light")
                    if appearanceManager.appearanceMode == .light {
                        Image(systemName: "checkmark")
                    }
                }
            }
            Button(action: { appearanceManager.setAppearance(.dark) }) {
                HStack {
                    Text("Dark")
                    if appearanceManager.appearanceMode == .dark {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
}
