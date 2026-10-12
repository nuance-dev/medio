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
        let saved = UserDefaults.standard.string(forKey: appearanceKey)
        self.appearanceMode = saved.flatMap(AppearanceMode.init) ?? .auto
        self.isSystemDark = AppearanceManager.detectSystemIsDark()
        setupObservers()
        updateAppearance()
    }
    
    static func detectSystemIsDark() -> Bool {
        CFPreferencesAppSynchronize(kCFPreferencesAnyApplication)
        if let style = CFPreferencesCopyAppValue("AppleInterfaceStyle" as CFString, kCFPreferencesAnyApplication) as? String {
            return style.caseInsensitiveCompare("dark") == .orderedSame
        }
        return false
    }
    
    private func setupObservers() {
        DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil, queue: .main
        ) { [weak self] _ in self?.refreshSystemAppearance() }
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.refreshSystemAppearance() }
    }
    
    func refreshSystemAppearance() {
        let dark = AppearanceManager.detectSystemIsDark()
        if isSystemDark != dark { isSystemDark = dark }
        updateAppearance()
    }
    
    var effectiveIsDark: Bool {
        appearanceMode == .auto ? isSystemDark : (appearanceMode == .dark)
    }
    
    var effectiveColorScheme: ColorScheme {
        effectiveIsDark ? .dark : .light
    }
    
    var effectiveNSAppearance: NSAppearance {
        NSAppearance(named: effectiveIsDark ? .darkAqua : .aqua) ?? .currentDrawing()
    }
    
    var isIconDark: Bool { effectiveIsDark }
    
    func cycleAppearance() { appearanceMode = appearanceMode.next }
    func setAppearance(_ mode: AppearanceMode) { appearanceMode = mode }
    
    func updateAppearance() {
        UserDefaults.standard.set(effectiveIsDark, forKey: legacyDarkModeKey)
        updateAppIcon()
        NotificationCenter.default.post(name: AppearanceManager.appearanceDidChangeNotification, object: nil)
    }
    
    var currentIcon: NSImage {
        (isIconDark ? loadDarkIcon() : loadLightIcon()) ?? NSImage()
    }
    
    func loadLightIcon() -> NSImage? {
        NSImage(named: NSImage.applicationIconName) ?? Bundle.main.image(forResource: NSImage.applicationIconName) ?? NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
    }
    
    func loadDarkIcon() -> NSImage? {
        NSImage(named: "AppIconDark") ?? Bundle.main.image(forResource: "AppIconDark")
    }
    
    private func updateAppIcon() {
        let darkIcon = loadDarkIcon()
        let lightIcon = loadLightIcon()
        
        // 1. Update live Dock icon tile
        NSApplication.shared.applicationIconImage = isIconDark ? darkIcon : nil
        
        // 2. Update Finder file bundle icon (affects Finder views & Get Info)
        _ = NSWorkspace.shared.setIcon(isIconDark ? darkIcon : nil, forFile: Bundle.main.bundlePath, options: [])
    }
}
