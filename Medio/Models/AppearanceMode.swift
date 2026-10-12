import SwiftUI
import AppKit

enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case auto = "auto", light = "light", dark = "dark"
    
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    
    var iconName: String {
        switch self {
        case .auto: return "circle.righthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        self == .auto ? nil : (self == .dark ? .dark : .light)
    }
    
    var nsAppearance: NSAppearance? {
        self == .auto ? nil : NSAppearance(named: self == .dark ? .darkAqua : .aqua)
    }
    
    var next: AppearanceMode {
        switch self {
        case .auto: return .light
        case .light: return .dark
        case .dark: return .auto
        }
    }
}
