import SwiftUI
import AppKit

@main
struct MedioApp: App {
    @StateObject private var appearanceManager = AppearanceManager.shared
    @StateObject private var updater = UpdateChecker()
    @State private var showingUpdateSheet = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearanceManager.effectiveColorScheme)
                .background(WindowAccessor(appearance: appearanceManager.effectiveNSAppearance))
                .sheet(isPresented: $showingUpdateSheet) {
                    MenuBarView(updater: updater)
                }
                .onAppear {
                    appearanceManager.updateAppearance()
                    
                    // Check for updates when app launches
                    updater.checkForUpdates()
                    
                    // Set up observer for update availability
                    updater.onUpdateAvailable = {
                        showingUpdateSheet = true
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    showingUpdateSheet = true
                    updater.checkForUpdates()
                }
                .keyboardShortcut("U", modifiers: [.command])
                
                if updater.updateAvailable {
                    Button("Download Update") {
                        if let url = updater.downloadURL {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
                
                Divider()
            }
            
            CommandMenu("Appearance") {
                Button("Auto (System)") {
                    appearanceManager.setAppearance(.auto)
                }
                .keyboardShortcut("0", modifiers: [.command, .option])
                
                Button("Light") {
                    appearanceManager.setAppearance(.light)
                }
                .keyboardShortcut("1", modifiers: [.command, .option])
                
                Button("Dark") {
                    appearanceManager.setAppearance(.dark)
                }
                .keyboardShortcut("2", modifiers: [.command, .option])
            }
        }
    }
}

// MARK: - Preview
struct MedioApp_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(nil)
            .environmentObject(UpdateChecker())
    }
}
