//
//  KeyboardUtils.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/9/3.
//

import Cocoa

class KeyboardUtils {
    static let source = Constant.source
    /// 模拟一个按键事件
    static func sendKey(keyCode: CGKeyCode, flags: CGEventFlags = []) {
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = flags
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = flags
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    /// 模拟Backspace键
    static func sendDelete() {
        sendKey(keyCode: 51)
    }
}
