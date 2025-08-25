//
//  Untitled.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/20.
//
import Cocoa

class MouseUtils {
    static func leftClick(position: NSPoint) {
        let source = CGEventSource(stateID: .hidSystemState)

        // 1. 鼠标按下事件
        if let mouseDown = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseDown,
            mouseCursorPosition: position,
            mouseButton: .left
        ) {
            mouseDown.post(tap: .cghidEventTap)
        }

        // 2. 鼠标抬起事件
        if let mouseUp = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseUp,
            mouseCursorPosition: position,
            mouseButton: .left
        ) {
            mouseUp.post(tap: .cghidEventTap)
        }
    }
}
