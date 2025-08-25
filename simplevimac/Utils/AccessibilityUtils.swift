//
//  AccessibilityUtils.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/13.
//
import Cocoa

class AccessibilityUtils {
    
    private static var systemWide: AXUIElement = AXUIElementCreateSystemWide()
    
    // 递归查找首个可编辑输入框
    static func findFirstEditableElement(in element: AXUIElement) -> AXUIElement? {
        var children: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children)

        guard result == .success, let childrenList = children as? [AXUIElement] else {
            return nil
        }

        for child in childrenList {
            var roleObj: AnyObject?
            if AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &roleObj) == .success,
               let role = roleObj as? String,
               Constant.editableElementRoles.contains(role) {
                return child
            }

            if let found = findFirstEditableElement(in: child) {
                return found
            }
        }
        return nil
    }
    
    static func getSystemWide() -> AXUIElement{
        return self.systemWide
    }
    
    // 获取元素的坐标（frame）
    static func getFrame(of element: AXUIElement) -> NSRect? {
        var frameValue: AnyObject?
        let err = AXUIElementCopyAttributeValue(element, "AXFrame" as CFString, &frameValue)
        guard err == .success else { return nil }

        if let axValue = frameValue, AXValueGetType(axValue as! AXValue) == .cgRect {
            var rect = CGRect.zero
            if AXValueGetValue(axValue as! AXValue, .cgRect, &rect) {
                return rect
            }
        }
        return nil
    }
    
    static func getRole(of element: AXUIElement) throws -> String {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &value)
        if result != .success {
            throw AppError.unexpected("没有获取到角色 result: \(result.rawValue)")
        }
        return value as? String ?? ""
    }
    
    static func getChildren(of element: AXUIElement) -> [AXUIElement] {
        var value: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value)
        return (value as? [AXUIElement]) ?? []
    }
    
    static func getVisibleRows(of element: AXUIElement) -> [AXUIElement] {
        var value: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXVisibleRowsAttribute as CFString, &value)
        return value as? [AXUIElement] ?? []
    }
    
    static func getFocusedElem() throws -> AXUIElement?{
        var focusedObj: AnyObject?
        let result = AXUIElementCopyAttributeValue(Self.getSystemWide(), kAXFocusedUIElementAttribute as CFString, &focusedObj)
        if result != .success {
            throw AppError.unexpected("没有获取到焦点元素 result: \(result.rawValue)")
        }
        if focusedObj == nil {
            return nil
        }
        return (focusedObj as! AXUIElement)
    }
    
    static func highlightFrame(_ axFrame: NSRect) {
        // Find the screen that contains (or intersects) the rect; fallback to main
        let targetScreen = NSScreen.main
        guard let screen = targetScreen else { return }

        // Convert from Quartz (origin bottom-left) to AppKit window coordinates
        let flippedY = screen.frame.maxY - axFrame.origin.y - axFrame.size.height
        let cocoaRect = NSRect(x: axFrame.origin.x,
                               y: flippedY,
                               width: axFrame.size.width,
                               height: axFrame.size.height)

        let overlay = NSWindow(
            contentRect: cocoaRect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        overlay.isReleasedWhenClosed = false
        overlay.level = .screenSaver
        overlay.backgroundColor = NSColor.yellow.withAlphaComponent(0.3)
        overlay.isOpaque = false
        overlay.hasShadow = false
        overlay.ignoresMouseEvents = true
        overlay.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]

        // Do not make key to avoid focus issues
        overlay.orderFront(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            overlay.close()
        }
    }
}
