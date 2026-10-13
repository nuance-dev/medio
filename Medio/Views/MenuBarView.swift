import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var updater: UpdateChecker
    @ObservedObject private var appearanceManager = AppearanceManager.shared
    @Environment(\.dismiss) var dismiss
    
    private var appIcon: NSImage {
        appearanceManager.currentIcon
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // App Icon and Version
            VStack(spacing: 8) {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                
                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 16)
            
            // Status Section
            Group {
                if updater.isChecking {
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Checking for updates...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else if let error = updater.error {
                    VStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else if updater.updateAvailable {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                        
                        if let version = updater.latestVersion {
                            Text("Version \(version) Available")
                                .font(.headline)
                        }
                        
                        if let notes = updater.releaseNotes {
                            ScrollView {
                                Text(notes)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .frame(maxHeight: 80)
                        }
                        
                        Button {
                            if let url = updater.downloadURL {
                                NSWorkspace.shared.open(url)
                                dismiss()
                            }
                        } label: {
                            Text("Download Update")
                                .frame(maxWidth: 200)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.green)
                        Text("Medio is up to date")
                            .font(.headline)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
            
            Divider()
            
            // Bottom Buttons
            HStack(spacing: 16) {
                Button("Check Again") {
                    updater.checkForUpdates()
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.bottom, 16)
            
            Text("Built by [Nuance](https://nuancedev.vercel.app)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
        }
        .padding(.horizontal)
        .frame(width: 300)
        .fixedSize(horizontal: false, vertical: true)
    }
}
