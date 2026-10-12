import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    var appearance: NSAppearance
    
    func makeNSView(context: Context) -> NSView {
        let nsView = NSView()
        
        DispatchQueue.main.async {
            if let window = nsView.window {
                window.appearance = appearance
                
                // Avoid adding duplicate accessories
                let alreadyHasAccessory = window.titlebarAccessoryViewControllers.contains { controller in
                    controller.view is NSHostingView<TitleBarAccessory>
                }
                
                if !alreadyHasAccessory {
                    let titleBarAccessory = NSTitlebarAccessoryViewController()
                    let hostingView = NSHostingView(rootView: TitleBarAccessory())
                    
                    hostingView.frame.size = hostingView.fittingSize
                    titleBarAccessory.view = hostingView
                    titleBarAccessory.layoutAttribute = .trailing
                    
                    window.addTitlebarAccessoryViewController(titleBarAccessory)
                }
            }
        }
        
        return nsView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            window.appearance = appearance
        }
    }
}
