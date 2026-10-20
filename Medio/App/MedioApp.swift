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
            CommandGroup(replacing: .appInfo) {
                Button("About Medio") {
                    NSApplication.shared.orderFrontStandardAboutPanel([
                        NSApplication.AboutPanelOptionKey.applicationIcon: AppearanceManager.shared.currentIcon
                    ])
                }
            }
            
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
                ForEach(Array(AppearanceMode.allCases.enumerated()), id: \.element.id) { index, mode in
                    Button(mode.title) { appearanceManager.setAppearance(mode) }
                        .keyboardShortcut(KeyEquivalent(Character("\(index)")), modifiers: [.command, .option])
                }
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
