//
//  AccessibilityElementManager.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/12.
//


import Cocoa
import ApplicationServices

class AccessibilityElementManager {
    static let shared = AccessibilityElementManager()
    
    var focusedElem: AXUIElement? = nil
    var focusedPid: pid_t = 0
    var focusedWindow: AXUIElement? = nil

    var frameMap: [AXUIElement:NSRect?] = [:]
    var roleMap: [AXUIElement:String] = [:]
    
    func getFocusedElem() throws -> AXUIElement {
        if self.focusedElem != nil {
            return self.focusedElem!
        }

        let focusedElem = try AccessibilityUtils.getFocusedElem()
        
        self.focusedElem = focusedElem
        return self.focusedElem!
    }
    
    func getFocusedPid() throws -> pid_t{
        if self.focusedPid != 0 {
            return self.focusedPid
        }
        
        let focusedElem = try? getFocusedElem()
        if focusedElem == nil {
            guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
                throw AppError.unexpected("获取不到前台 app")
            }

            self.focusedPid = frontmostApp.processIdentifier
        } else {
            AXUIElementGetPid(focusedElem! , &self.focusedPid)
        }
        
        if self.focusedPid == 0 {
            throw AppError.unexpected("获取不到pid")
        }
        
        return self.focusedPid
    }
    
    
    func getFocusedWindow() throws -> AXUIElement {
        if self.focusedWindow != nil {
            return self.focusedWindow!
        }
        
        let pid = try getFocusedPid()
        let appRef = AXUIElementCreateApplication(pid)
        var windowObj: AnyObject?
        let windowResult = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &windowObj)

        guard windowResult == .success, let window = windowObj else {
            throw AppError.unexpected("无法获取焦点窗口 result: \(windowResult.rawValue)")
        }
        
        self.focusedWindow = (window as! AXUIElement)
        return self.focusedWindow!
    }

    func isTextInputFocused() throws -> Bool {
        var elem:AXUIElement
        do {
            elem = try getFocusedElem()
        } catch AppError.unexpected(_){
            return false
        }
        
        let role = try getRole(of: elem)
        
        if !role.isEmpty {
            return Constant.editableElementRoles.contains(role)
        }
        
        return false
    }
    
    func getBundleIdOfFocusedApp() throws -> String? {
        let pid = try getFocusedPid()
        
        var bundleId: String?
        if let app = NSRunningApplication(processIdentifier: pid) {
            bundleId = app.bundleIdentifier
        }

        return bundleId
    }
    
    func getTitleOfFocusedWindow() throws -> String? {
        let window = try getFocusedWindow()

        var titleObj: AnyObject?
        let titleResult = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleObj)

        guard titleResult == .success, let title = titleObj as? String else {
            throw AppError.unexpected("获取不到窗口标题 result: \(titleResult.rawValue)")
        }

        return title
    }

    func getURLOfFocusedWindow() throws -> String? {
        let window = try getFocusedWindow()
        
        let url = WebAreaURLResolver.getURL(of: window)
        return url
    }
    
    func getFrame(of element: AXUIElement) -> NSRect? {
        if frameMap.index(forKey: element) != nil {
            return frameMap[element] ?? nil
        }
        
        let frame = AccessibilityUtils.getFrame(of: element)
        frameMap[element] = frame
        return frame
    }
    
    func getRole(of element: AXUIElement) throws -> String {
        if let role = roleMap[element] {
            return role
        }
        
        let role = try AccessibilityUtils.getRole(of: element)
        roleMap[element] = role
        return role
    }
    
    func clearTempVars() {
        self.focusedElem = nil
        self.focusedPid = 0
        self.focusedWindow = nil
        self.frameMap = [:]
        self.roleMap = [:]
    }
    
}
