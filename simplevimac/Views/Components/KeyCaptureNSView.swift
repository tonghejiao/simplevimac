//
//  KeyCaptureNSView.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/13.
//

import AppKit

class KeyCaptureNSView: NSView {
    var onKeyPress: (([CGKeyCode], CGEventFlags) -> Void)?
    var onFocus: (() -> Void)?
    var unFocus: (() -> Void)?
    var accumulateKeyCodes = false
    var needModifierFlags = true
    var allowedKeyCodes: Set<CGKeyCode>? = nil
    var allowedModifierFlags: CGEventFlags? = nil
    private var accumulatedKeyCodes: [CGKeyCode] = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.borderWidth = 1
        self.layer?.borderColor = NSColor.separatorColor.cgColor
        self.layer?.cornerRadius = 4
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        let modifierFlags = CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue))
        let cleanModifierFlags = allowedModifierFlags != nil ? modifierFlags.intersection(allowedModifierFlags!) : modifierFlags
        
        if needModifierFlags && cleanModifierFlags.isEmpty {
            return
        }

        if let allowedKeyCodes = allowedKeyCodes, !allowedKeyCodes.contains(event.keyCode) {
            return
        }
        if accumulateKeyCodes {
            accumulatedKeyCodes.append(event.keyCode)
        } else {
            accumulatedKeyCodes = [event.keyCode]
        }
        onKeyPress?(accumulatedKeyCodes, cleanModifierFlags)
    }

    override func mouseDown(with event: NSEvent) {
        self.window?.makeFirstResponder(self)
    }

    override func becomeFirstResponder() -> Bool {
        onFocus?()
        self.layer?.borderColor = NSColor.controlAccentColor.cgColor
        return true
    }

    override func resignFirstResponder() -> Bool {
        unFocus?()
        self.layer?.borderColor = NSColor.separatorColor.cgColor
        return true
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // 只有当自己是第一响应者时才拦截快捷键
        if self.window?.firstResponder == self {
            self.keyDown(with: event)
            return true
        }
        return false
    }

    func clearKeyCodes() {
        accumulatedKeyCodes = []
        onKeyPress?([], [])
    }
}
