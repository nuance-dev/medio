import SwiftUI
import AppKit

final class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()
    static let appearanceDidChangeNotification = Notification.Name("MedioAppearanceDidChangeNotification")
    
    private let appearanceKey = "appearanceMode"
    private let legacyDarkModeKey = "isDarkMode"
    
    @Published var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: appearanceKey)
            updateAppearance()
        }
    }
    
    @Published private(set) var isSystemDark: Bool = false
    
    init() {
        self.appearanceMode = UserDefaults.standard.string(forKey: appearanceKey).flatMap(AppearanceMode.init) ?? .auto
        self.isSystemDark = AppearanceManager.detectSystemIsDark()
        setupObservers()
        updateAppearance()
    }
    
    static func detectSystemIsDark() -> Bool {
        CFPreferencesAppSynchronize(kCFPreferencesAnyApplication)
        return (CFPreferencesCopyAppValue("AppleInterfaceStyle" as CFString, kCFPreferencesAnyApplication) as? String)?.caseInsensitiveCompare("dark") == .orderedSame
    }
    
    private func setupObservers() {
        DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"), object: nil, queue: .main
        ) { [weak self] _ in self?.refreshSystemAppearance() }
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.refreshSystemAppearance() }
    }
    
    func refreshSystemAppearance() {
        let dark = AppearanceManager.detectSystemIsDark()
        if isSystemDark != dark { isSystemDark = dark }
        updateAppearance()
    }
    
    var effectiveIsDark: Bool { appearanceMode == .auto ? isSystemDark : (appearanceMode == .dark) }
    var effectiveColorScheme: ColorScheme { effectiveIsDark ? .dark : .light }
    var effectiveNSAppearance: NSAppearance { NSAppearance(named: effectiveIsDark ? .darkAqua : .aqua) ?? .currentDrawing() }
    var isIconDark: Bool { effectiveIsDark }
    
    func cycleAppearance() { appearanceMode = appearanceMode.next }
    func setAppearance(_ mode: AppearanceMode) { appearanceMode = mode }
    
    func updateAppearance() {
        UserDefaults.standard.set(effectiveIsDark, forKey: legacyDarkModeKey)
        updateAppIcon()
        NotificationCenter.default.post(name: AppearanceManager.appearanceDidChangeNotification, object: nil)
    }
    
    var currentIcon: NSImage { (isIconDark ? loadDarkIcon() : nil) ?? loadLightIcon() ?? NSImage() }
    func loadLightIcon() -> NSImage? { NSImage(named: NSImage.applicationIconName) ?? Bundle.main.image(forResource: NSImage.applicationIconName) ?? NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath) }
    func loadDarkIcon() -> NSImage? { NSImage(named: "AppIconDark") ?? Bundle.main.image(forResource: "AppIconDark") }
    
    private func updateAppIcon() {
        let icon = isIconDark ? loadDarkIcon() : nil
        NSApplication.shared.applicationIconImage = icon
        if NSClassFromString("XCTest") == nil && !Bundle.main.bundlePath.contains("DerivedData") {
            _ = NSWorkspace.shared.setIcon(icon, forFile: Bundle.main.bundlePath, options: [])
        }
    }
}
