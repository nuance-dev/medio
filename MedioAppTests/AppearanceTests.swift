import XCTest
import SwiftUI
import AppKit
@testable import Medio

final class AppearanceTests: XCTestCase {
    
    func testAppearanceModeCycling() {
        XCTAssertEqual(AppearanceMode.auto.next, .light)
        XCTAssertEqual(AppearanceMode.light.next, .dark)
        XCTAssertEqual(AppearanceMode.dark.next, .auto)
    }
    
    func testAppearanceModeProperties() {
        // Auto
        XCTAssertEqual(AppearanceMode.auto.title, "Auto")
        XCTAssertEqual(AppearanceMode.auto.iconName, "circle.righthalf.filled")
        XCTAssertNil(AppearanceMode.auto.colorScheme)
        XCTAssertNil(AppearanceMode.auto.nsAppearance)
        
        // Light
        XCTAssertEqual(AppearanceMode.light.title, "Light")
        XCTAssertEqual(AppearanceMode.light.iconName, "sun.max.fill")
        XCTAssertEqual(AppearanceMode.light.colorScheme, .light)
        XCTAssertEqual(AppearanceMode.light.nsAppearance?.name, .aqua)
        
        // Dark
        XCTAssertEqual(AppearanceMode.dark.title, "Dark")
        XCTAssertEqual(AppearanceMode.dark.iconName, "moon.fill")
        XCTAssertEqual(AppearanceMode.dark.colorScheme, .dark)
        XCTAssertEqual(AppearanceMode.dark.nsAppearance?.name, .darkAqua)
    }
    
    func testAppearanceManagerModes() {
        let manager = AppearanceManager.shared
        let originalMode = manager.appearanceMode
        
        defer {
            manager.setAppearance(originalMode)
        }
        
        manager.setAppearance(.light)
        XCTAssertEqual(manager.appearanceMode, .light)
        XCTAssertFalse(manager.effectiveIsDark)
        XCTAssertEqual(manager.effectiveColorScheme, .light)
        XCTAssertEqual(manager.effectiveNSAppearance.name, .aqua)
        XCTAssertFalse(manager.isIconDark)
        
        manager.setAppearance(.dark)
        XCTAssertEqual(manager.appearanceMode, .dark)
        XCTAssertTrue(manager.effectiveIsDark)
        XCTAssertEqual(manager.effectiveColorScheme, .dark)
        XCTAssertEqual(manager.effectiveNSAppearance.name, .darkAqua)
        XCTAssertTrue(manager.isIconDark)
        
        manager.setAppearance(.auto)
        XCTAssertEqual(manager.appearanceMode, .auto)
        XCTAssertEqual(manager.effectiveIsDark, manager.isSystemDark)
        XCTAssertEqual(manager.effectiveColorScheme, manager.isSystemDark ? .dark : .light)
        XCTAssertEqual(manager.isIconDark, manager.isSystemDark)
        
        // Test full cycle rotation: Auto -> Light -> Dark -> Auto
        manager.setAppearance(.auto)
        manager.cycleAppearance() // auto -> light
        XCTAssertEqual(manager.appearanceMode, .light)
        XCTAssertFalse(manager.effectiveIsDark)
        XCTAssertEqual(manager.effectiveColorScheme, .light)
        
        manager.cycleAppearance() // light -> dark
        XCTAssertEqual(manager.appearanceMode, .dark)
        XCTAssertTrue(manager.effectiveIsDark)
        XCTAssertEqual(manager.effectiveColorScheme, .dark)
        
        manager.cycleAppearance() // dark -> auto
        XCTAssertEqual(manager.appearanceMode, .auto)
        // When rotated back to auto, must reflect isSystemDark!
        XCTAssertEqual(manager.effectiveIsDark, manager.isSystemDark)
        XCTAssertEqual(manager.effectiveColorScheme, manager.isSystemDark ? .dark : .light)
    }
    
    func testIconLoading() {
        let manager = AppearanceManager.shared
        let lightIcon = manager.loadLightIcon()
        XCTAssertNotNil(lightIcon, "Light icon should be loadable")
        
        let darkIcon = manager.loadDarkIcon()
        XCTAssertNotNil(darkIcon, "Dark icon should be loadable")
        
        let currentIcon = manager.currentIcon
        XCTAssertNotNil(currentIcon, "Current icon should never be nil")
    }
}
