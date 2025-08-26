//
//  mouseActionExecutor.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/21.
//

import CoreGraphics
import AppKit

class MouseActionExecutor {
    static let shared = MouseActionExecutor()
    
    func execute(mouseAction: KeyMapper.KeySpec.MouseAction?) -> Bool{
        switch mouseAction {
        case .none:
            return false
        case .scrollUp:
            SmoothScroller.start(direction: 20)
        case .scrollDown:
            SmoothScroller.start(direction: -20)
        case .scrollToTop:
            SmoothScroller.scrollToTop()
        case .scrollToBottom:
            SmoothScroller.scrollToBottom()
        case .mouseMoveToLeftTop:
            self.mouseMoveToLeftTop()
        case .mouseMoveToLeftBottom:
            self.mouseMoveToLeftBottom()
        case .mouseMoveToRightTop:
            self.mouseMoveToRightTop()
        case .mouseMoveToRightBottom:
            self.mouseMoveToRightBottom()
        }
        return true
    }
    
    func mouseMoveToLeftTop() {
        let offScreen = CGPoint(x: 0, y: 0)
        let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: offScreen, mouseButton: .left)
        moveEvent?.post(tap: .cghidEventTap)
    }
    
    func mouseMoveToLeftBottom() {
        let screenHeight = CGFloat(Int.max)
        let offScreen = CGPoint(x: 0, y: screenHeight)
        let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: offScreen, mouseButton: .left)
        moveEvent?.post(tap: .cghidEventTap)
    }
    
    func mouseMoveToRightTop() {
        let screenWidth = CGFloat(Int.max)
        let offScreen = CGPoint(x: screenWidth, y: 0)
        let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: offScreen, mouseButton: .left)
        moveEvent?.post(tap: .cghidEventTap)
    }
    
    func mouseMoveToRightBottom() {
        let screenWidth = CGFloat(Int.max)
        let screenHeight =  CGFloat(Int.max)
        let offScreen = CGPoint(x: screenWidth, y: screenHeight)
        let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: offScreen, mouseButton: .left)
        moveEvent?.post(tap: .cghidEventTap)
    }
}
