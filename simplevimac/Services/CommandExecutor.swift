//
//  CommandEXecutor.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/13.
//

import Cocoa

class CommandExecutor {
    static let shared = CommandExecutor()
    
    private var accessibilityElementManager = AccessibilityElementManager.shared
    private var overlayWindow: NSWindow?
    var currentHints: [ClickableElement] = []
    
    let font = NSFont.systemFont(ofSize: Constant.fontSize, weight: .semibold)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: Constant.fontSize, weight: .semibold)
    ]
    var showMenu = false
    
    func execute(command: KeyMapper.KeySpec.Command?) {
        switch command {
            case .none:
                break
            case .firstInputBox:
                firstInputBox()
            case .showClickableElements:
                showClickableElements()
        }
    }
    
    func firstInputBox() {
        let window = try? accessibilityElementManager.getFocusedWindow()
        guard let window else { return }

        if let inputElement = AccessibilityUtils.findFirstEditableElement(in: window) {
            if let frame = accessibilityElementManager.getFrame(of: inputElement),
               let windowFrame = accessibilityElementManager.getFrame(of: window) {
                let validFrame = frame.intersection(windowFrame)
                guard !validFrame.isEmpty else {
                    return
                }
                let center = CGPoint(x: validFrame.midX, y: validFrame.midY)
                MouseUtils.leftClick(position: center)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                AXUIElementSetAttributeValue(AccessibilityUtils.getSystemWide(), kAXFocusedUIElementAttribute as CFString, inputElement)
                let focusedValue = kCFBooleanTrue as CFBoolean
                AXUIElementSetAttributeValue(inputElement, kAXFocusedAttribute as CFString, focusedValue)
                
                // ✅ 尝试将光标移动到文本结尾
                var textObj: AnyObject?
                let getTextResult = AXUIElementCopyAttributeValue(inputElement, kAXValueAttribute as CFString, &textObj)
                if getTextResult == .success, let text = textObj as? String {
                    let textLength = text.count
                    var range = CFRange(location: textLength, length: 0)
                    if let rangeValue = AXValueCreate(.cfRange, &range) {
                        AXUIElementSetAttributeValue(inputElement, kAXSelectedTextRangeAttribute as CFString, rangeValue)
                    }
                }
            }

        }
    }
    
    func showClickableElements() {
        showMenu = false

        var clickableHints: [ClickableElement] = []
        
        var elements = findMenuBarClickableElementFrame()
        
        if !showMenu, let window = try? accessibilityElementManager.getFocusedWindow() {
            elements.append(contentsOf: findAllClickableElementsFrame(in: window))
        }
        
        // Sort elements by centerY descending (top to bottom), then by centerX ascending (left to right)
        let sortedElements = elements.sorted { lhsFrame, rhsFrame in
            let lhsCenterX = lhsFrame.midX
            let lhsCenterY = lhsFrame.midY
            let rhsCenterX = rhsFrame.midX
            let rhsCenterY = rhsFrame.midY
            if lhsCenterY != rhsCenterY {
                return lhsCenterY < rhsCenterY
            } else {
                return lhsCenterX < rhsCenterX
            }
        }
        
        let hintChars = HintCharsUtils.generateHintChars(count: sortedElements.count)
        
        for (idx, elementHint) in sortedElements.enumerated() {
            let hint = ClickableElement(frame: elementHint, hintChar: hintChars[idx])
            clickableHints.append(hint)
        }
        
        let finalHints = filterOutOverlappingHitns(clickableHints)
        self.currentHints = finalHints
        if !finalHints.isEmpty {
            AppBusinessManager.shared.switchMode(Mode.hints)
        }
        
        showHintOverlays(finalHints)
        
    }
    
    // 用辅助功能 API 递归遍历所有可点击元素，使用 hit testing 判断元素是否为顶层可点击元素
    func findAllClickableElementsFrame(in root: AXUIElement) -> [NSRect] {
        guard let windowFrame = accessibilityElementManager.getFrame(of: root) else { return [] }
        var result: [NSRect] = []
        var stack: [AXUIElement] = [root]
        while let el = stack.popLast() {
            guard let elFrame = accessibilityElementManager.getFrame(of: el) else {
                continue
            }
            if isElementClickable(el,windowFrame) {
                result.append(elFrame)
            }
            let children = getChildren(of: el)
            for child in children {
                stack.append(child)
            }
        }
        return result
    }
    
    // 判断是否可点击（参照 Vimac 的 isActionable 逻辑），并通过 hit testing 确认元素为顶层可点击元素
    func isElementClickable(_ element: AXUIElement, _ windowFrame: NSRect) -> Bool {
        guard let frame = accessibilityElementManager.getFrame(of: element) else {
            return false
        }
        
        if frame.width <= 1 || frame.height <= 1 {
            return false
        }
        
        let centerPoint = CGPoint(x: frame.midX, y: frame.midY)
        if !windowFrame.contains(centerPoint) {
            return false
        }
        
        let role = try? accessibilityElementManager.getRole(of: element)
        if role == "AXWindow"{
            return false
        }

        return true
    }
    
    // 获取元素子节点
    func getChildren(of element: AXUIElement) -> [AXUIElement] {
        let role = try? accessibilityElementManager.getRole(of: element)
        if role == "AXTable" || role == "AXOutline" {
            return AccessibilityUtils.getVisibleRows(of: element)
        }
        return AccessibilityUtils.getChildren(of: element)
    }
    
    func filterOutOverlappingHitns(_ clickableHints: [ClickableElement]) -> [ClickableElement] {
        guard let screen = NSScreen.main else { return []}

        // Step 1: Pre-generate all potential square frames for all clickableHints
        var potentialSquares: [ClickableElement] = []
        for hint in clickableHints {
            let axFrame = hint.frame
            let squareRect = getFrameByHintchar(frame: axFrame, hintChar: hint.hintChar, flipY: true, screenFrameHeight: screen.frame.height)
            potentialSquares.append(ClickableElement(frame: squareRect, hintChar: ""))
        }

        // Step 2: Filter out overlapping frames, keep only one square per overlapping region
        var filteredSquares: [ClickableElement] = []
        for candidate in potentialSquares {
            var overlaps = false
            for existing in filteredSquares {
                if existing.frame.intersects(candidate.frame) {
                    overlaps = true
                    break
                }
            }
            if !overlaps {
                filteredSquares.append(candidate)
            }
        }

        // Step 3: After filtering, regenerate the yellow squares and assign hintChar sequentially
        let hintChars = HintCharsUtils.generateHintChars(count: filteredSquares.count)

        var finalHints = filteredSquares
        for i in 0..<finalHints.count {
            finalHints[i].hintChar = hintChars[i]
        }
        
        return finalHints
    }
    
    // 在屏幕上绘制黄色小方块
    func showHintOverlays(_ finalHints: [ClickableElement]) {
        guard let screen = NSScreen.main else { return }

        // 彻底销毁旧的 overlay 窗口
        clearOverlays()
        
        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.backgroundColor = .clear
        panel.hasShadow = false

        overlayWindow = panel
        let overlayView = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
        panel.contentView = overlayView

        for hint in finalHints {
            let hintChar = hint.hintChar
            let adjustedFrame = getFrameByHintchar(frame: hint.frame, hintChar: hint.hintChar)
            let squareView = NSView(frame: adjustedFrame)
            squareView.wantsLayer = true
            squareView.layer?.backgroundColor = NSColor.systemYellow.cgColor
            squareView.layer?.cornerRadius = Constant.cornerRadius

            let label = NSTextField(labelWithString: hintChar)
            label.frame = squareView.bounds
            label.alignment = .center
            label.font = self.font
            squareView.addSubview(label)

            overlayView.addSubview(squareView)
        }

        panel.orderFrontRegardless()
    }
    
    func getFrameByHintchar(frame: NSRect, hintChar: String, flipY: Bool = false, screenFrameHeight: CGFloat = 0) -> NSRect {
        let textSize = (hintChar as NSString).size(withAttributes: attributes)

        let squareWidth: CGFloat = textSize.width + 2*Constant.cornerRadius
        let squareHeight: CGFloat = textSize.height
        
        let centerX = frame.midX
        let centerY = flipY ? screenFrameHeight - frame.midY :frame.midY
        
        return NSRect(x: centerX - squareWidth / 2, y: centerY - squareHeight / 2, width: squareWidth, height: squareHeight)
    }
    
    func clearOverlays() {
        overlayWindow?.close()
        overlayWindow = nil
    }
    
    // 获取菜单栏的所有可点击元素的 frame
    func findMenuBarClickableElementFrame() -> [NSRect] {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return [] }
        let appElement = AXUIElementCreateApplication(pid)
        var menuBar: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &menuBar)
        guard result == .success, let menuBarElement = menuBar else {
            return []
        }
        
        var maxX: CGFloat = 0
        var resultElements: [NSRect] = []
        let children = getChildren(of: menuBarElement as! AXUIElement)
        for el in children {
            if let frame = accessibilityElementManager.getFrame(of: el){
                resultElements.append(frame)
                if maxX < frame.midX {
                    maxX = frame.midX
                }
            }
        }
        
        resultElements.append(contentsOf: findMenuBarRightClickableElementFrame(minX: maxX))
        return resultElements
    }
    
    func findMenuBarRightClickableElementFrame(minX: CGFloat) -> [NSRect] {
        guard let screen = NSScreen.main else {
            return []
        }
        
        guard let windowListInfo = CGWindowListCopyWindowInfo([.excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        let menuBarHeight = NSApplication.shared.mainMenu?.menuBarHeight ?? 0

        var results: [NSRect] = []
        for windowInfo in windowListInfo {
            guard
                let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: Any],
                let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary)
            else { continue }
            let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
            if screen.frame.contains(centerPoint) && centerPoint.y <= menuBarHeight && centerPoint.x > minX {
                results.append(bounds)
            }
        }
        
        return results
    }
}
