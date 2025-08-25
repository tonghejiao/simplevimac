//
//  MainWindowController.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/9.
//
import SwiftUI
import Cocoa

class MainWindowController: NSWindowController, NSWindowDelegate {
    static let shared = MainWindowController()

    private init() {
        // 创建一个 NSWindow，设置内容为 SwiftUI ContentView
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 850, height: 870),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered, defer: false)
                
        // 用 SwiftUI 视图做窗口内容
        window.contentView = NSHostingView(rootView: ContentView())

        super.init(window: window)
        window.center()
        
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showWindowAndActivate() {
        NSApp.setActivationPolicy(.regular)
        self.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
    
    func windowWillClose(_: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        // 固定高度，允许宽度调整
        return NSSize(width: frameSize.width, height: 900)
    }
}
