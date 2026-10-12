import SwiftUI
import AppKit
import Combine

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
    
    private var darkIconCache: NSImage?
    private var lightIconCache: NSImage?
    private var observers: [Any] = []
    
    init() {
        if let savedMode = UserDefaults.standard.string(forKey: appearanceKey),
           let mode = AppearanceMode(rawValue: savedMode) {
            self.appearanceMode = mode
        } else {
            self.appearanceMode = .auto
        }
        
        self.isSystemDark = AppearanceManager.detectSystemIsDark()
        setupObservers()
        updateAppearance()
    }
    
    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }
    
    // MARK: - System Appearance Detection
    
    static func detectSystemIsDark() -> Bool {
        if let style = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") {
            return style.caseInsensitiveCompare("dark") == .orderedSame
        }
        return NSApplication.shared.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    }
    
    private func setupObservers() {
        // Observe macOS system theme changes (Light <-> Dark mode toggles)
        let distObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshSystemAppearance()
        }
        observers.append(distObserver)
        
        // Refresh when app becomes active
        let appActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshSystemAppearance()
        }
        observers.append(appActiveObserver)
    }
    
    func refreshSystemAppearance() {
        let systemDark = AppearanceManager.detectSystemIsDark()
        if self.isSystemDark != systemDark {
            self.isSystemDark = systemDark
        }
        updateAppearance()
    }
    
    // MARK: - Appearance Logic
    
    var effectiveIsDark: Bool {
        switch appearanceMode {
        case .auto:
            return isSystemDark
        case .light:
            return false
        case .dark:
            return true
        }
    }
    
    var isIconDark: Bool {
        switch appearanceMode {
        case .auto:
            return isSystemDark
        case .light:
            return false
        case .dark:
            return true
        }
    }
    
    func cycleAppearance() {
        appearanceMode = appearanceMode.next
    }
    
    func setAppearance(_ mode: AppearanceMode) {
        appearanceMode = mode
    }
    
    func updateAppearance() {
        // Sync legacy key
        UserDefaults.standard.set(effectiveIsDark, forKey: legacyDarkModeKey)
        
        // Update dock icon
        updateAppIcon()
        
        // Post notification so AppKit views can update if needed
        NotificationCenter.default.post(name: AppearanceManager.appearanceDidChangeNotification, object: nil)
    }
    
    // MARK: - Icon Management
    
    var currentIcon: NSImage {
        if isIconDark {
            return loadDarkIcon() ?? loadLightIcon() ?? NSImage()
        } else {
            return loadLightIcon() ?? NSImage()
        }
    }
    
    func loadLightIcon() -> NSImage? {
        if let cached = lightIconCache {
            return cached
        }
        
        if let bundleIcon = NSImage(named: NSImage.applicationIconName) {
            lightIconCache = bundleIcon
            return bundleIcon
        }
        
        if let icon = Bundle.main.image(forResource: NSImage.applicationIconName) {
            lightIconCache = icon
            return icon
        }
        
        let wsIcon = NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        lightIconCache = wsIcon
        return wsIcon
    }
    
    func loadDarkIcon() -> NSImage? {
        if let cached = darkIconCache {
            return cached
        }
        
        // 1. Try named asset
        if let image = NSImage(named: "AppIconDark") {
            darkIconCache = image
            return image
        }
        
        // 2. Try bundle resource
        if let image = Bundle.main.image(forResource: "AppIconDark") {
            darkIconCache = image
            return image
        }
        
        // 3. Fallback: dynamically generate dark icon from light icon
        if let lightIcon = loadLightIcon(),
           let generated = generateDarkIcon(from: lightIcon) {
            darkIconCache = generated
            return generated
        }
        
        return nil
    }
    
    private func updateAppIcon() {
        if isIconDark {
            if let dark = loadDarkIcon() {
                NSApplication.shared.applicationIconImage = dark
            }
        } else {
            if let light = loadLightIcon() {
                NSApplication.shared.applicationIconImage = light
            } else {
                NSApplication.shared.applicationIconImage = nil
            }
        }
    }
    
    private func generateDarkIcon(from image: NSImage) -> NSImage? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else {
            return nil
        }
        
        let width = rep.pixelsWide
        let height = rep.pixelsHigh
        guard width > 0, height > 0 else { return nil }
        
        guard let outRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: width * 4,
            bitsPerPixel: 32
        ) else {
            return nil
        }
        
        for y in 0..<height {
            for x in 0..<width {
                guard let c = rep.colorAt(x: x, y: y) else { continue }
                let a = c.alphaComponent
                if a < 0.01 {
                    outRep.setColor(NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 0), atX: x, y: y)
                    continue
                }
                
                let r = c.redComponent
                let g = c.greenComponent
                let b = c.blueComponent
                
                let minC = min(r, min(g, b))
                let glyphFactor: CGFloat
                if minC >= 0.92 {
                    glyphFactor = 0.0
                } else if minC <= 0.70 {
                    glyphFactor = 1.0
                } else {
                    glyphFactor = (0.92 - minC) / (0.92 - 0.70)
                }
                
                let darkR = r * glyphFactor
                let darkG = g * glyphFactor
                let darkB = b * glyphFactor
                
                outRep.setColor(NSColor(calibratedRed: darkR, green: darkG, blue: darkB, alpha: a), atX: x, y: y)
            }
        }
        
        let result = NSImage(size: image.size)
        result.addRepresentation(outRep)
        return result
    }
}
