//
//  AppDelegate.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/6/28.test
//

import Cocoa
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    var eventTap: CFMachPort?
    let scroller = SmoothScroller()
    var lastGPressTime: TimeInterval = 0
    let gPressInterval: TimeInterval = 0.3
    var eventSource: CGEventSource? = CGEventSource(stateID: .hidSystemState)
    let allModifiers: CGEventFlags = [.maskShift, .maskControl, .maskCommand, .maskAlternate, .maskAlphaShift]

    func applicationDidFinishLaunching(_ notification: Notification) {
        // ✅ 显示主窗口，不设置 .accessory
        requestAccessibilityPermission()
        setupGlobalKeyListener()
    }

    func requestAccessibilityPermission() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(opts) else {
            debugLog("请在 系统设置 → 隐私与安全性 → 辅助功能 中授权本应用")
            return
        }
    }

    func isTextInputFocused() -> Bool {
        let systemWide = AXUIElementCreateSystemWide()
        var focused: AnyObject?
        let result = AXUIElementCopyAttributeValue(systemWide,
                      kAXFocusedUIElementAttribute as CFString,
                      &focused)

        guard result == .success, let raw = focused else {
            return false
        }

        let elem = raw as! AXUIElement

        var roleObj: AnyObject?
        if AXUIElementCopyAttributeValue(elem, kAXRoleAttribute as CFString, &roleObj) == .success,
           let role = roleObj as? String {
            debugLog("role is \(role)")
            return ["AXTextField", "AXTextArea", "AXSearchField", "AXEditableText","AXComboBox"].contains(role)
        }
        
        return false
    }
    
    func scroll(deltaY: Int32) {
        let ev = CGEvent(scrollWheelEvent2Source: eventSource, units: .pixel,
                         wheelCount: 1, wheel1: deltaY, wheel2: 0, wheel3: 0)!
        ev.post(tap: .cghidEventTap)
    }
    
    func startScroll(direction: Int32) {
        scroller.start(direction: direction)
    }

    func stopScroll() {
        scroller.stop()
    }
    
    func scrollToTop() {
        stopScroll()
        scroll(deltaY: Int32.max)
    }

    func scrollToBottom() {
        stopScroll()
        scroll(deltaY: Int32.min)
    }
    
    func setupGlobalKeyListener() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue | 1 << CGEventType.keyUp.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { (proxy, type, event, userInfo) -> Unmanaged<CGEvent>? in
                guard let userInfo = userInfo else {
                    return Unmanaged.passUnretained(event)
                }

                // 还原为 AppDelegate 实例
                let mySelf = Unmanaged<AppDelegate>.fromOpaque(userInfo).takeUnretainedValue()
                
                if mySelf.isTextInputFocused() {
                    return Unmanaged.passUnretained(event)
                }
                
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.flags
                mySelf.debugLog("Pressed keyCode: \(keyCode), flags: \(flags.rawValue)")


                if type == .keyDown {
                    if keyCode == 2 { // d
                        if flags.intersection(mySelf.allModifiers).isEmpty {
                            mySelf.startScroll(direction: -20)
                            return nil
                        }
                    } else if keyCode == 14 { // e
                        if flags.intersection(mySelf.allModifiers).isEmpty {
                            mySelf.startScroll(direction: 20)
                            return nil
                        }
                    } else if keyCode == 5 { // Shift + g → G
                        if flags.intersection(mySelf.allModifiers) == .maskShift {
                            mySelf.scrollToBottom()
                            return nil
                        } else if flags.intersection(mySelf.allModifiers).isEmpty {
                            let now = Date().timeIntervalSince1970
                            if now - mySelf.lastGPressTime < mySelf.gPressInterval {
                                mySelf.scrollToTop()
                                mySelf.lastGPressTime = 0
                            } else {
                                mySelf.lastGPressTime = now
                            }
                            return nil
                        }
                    } else if keyCode == 7 { // x 键
                        if flags.intersection(mySelf.allModifiers) == .maskShift {
                            // Shift + x → 恢复标签页（⌘⇧T）
                            let cmdShiftT = CGEvent(keyboardEventSource: mySelf.eventSource, virtualKey: 17, keyDown: true)!
                            cmdShiftT.flags = .maskCommand.union(.maskShift)
                            cmdShiftT.post(tap: .cghidEventTap)
                            let cmdShiftTUp = CGEvent(keyboardEventSource: mySelf.eventSource, virtualKey: 17, keyDown: false)!
                            cmdShiftTUp.flags = .maskCommand.union(.maskShift)
                            cmdShiftTUp.post(tap: .cghidEventTap)
                            return nil
                        } else if flags.intersection(mySelf.allModifiers).isEmpty {
                            // x → 关闭标签页（⌘W）
                            let cmdW = CGEvent(keyboardEventSource: mySelf.eventSource, virtualKey: 13, keyDown: true)!
                            cmdW.flags = .maskCommand
                            cmdW.post(tap: .cghidEventTap)
                            let cmdWUp = CGEvent(keyboardEventSource: mySelf.eventSource, virtualKey: 13, keyDown: false)!
                            cmdWUp.flags = .maskCommand
                            cmdWUp.post(tap: .cghidEventTap)
                            return nil
                        }
                    } else if keyCode == 15 { // r → 刷新 (Cmd + R)
                        if flags.intersection(mySelf.allModifiers).isEmpty {
                            let cmdR = CGEvent(keyboardEventSource: mySelf.eventSource, virtualKey: 15, keyDown: true)!
                            cmdR.flags = .maskCommand
                            cmdR.post(tap: .cghidEventTap)
                            let cmdRUp = CGEvent(keyboardEventSource: mySelf.eventSource, virtualKey: 15, keyDown: false)!
                            cmdRUp.flags = .maskCommand
                            cmdRUp.post(tap: .cghidEventTap)
                            return nil
                        }
                    } else if keyCode == 12 { // q → 后退 (Cmd + [)
                        if flags.intersection(mySelf.allModifiers).isEmpty {
                            let leftBracketDown = CGEvent(keyboardEventSource: mySelf.eventSource, virtualKey: 33, keyDown: true)!
                            leftBracketDown.flags = .maskCommand
                            leftBracketDown.post(tap: .cghidEventTap)
                            let leftBracketUp = CGEvent(keyboardEventSource: mySelf.eventSource, virtualKey: 33, keyDown: false)!
                            leftBracketUp.flags = .maskCommand
                            leftBracketUp.post(tap: .cghidEventTap)
                            return nil
                        }
                    } else if keyCode == 13{ // w → 前进 (Cmd + ])
                        if flags.intersection(mySelf.allModifiers).isEmpty {
                            let rightBracketDown = CGEvent(keyboardEventSource: mySelf.eventSource, virtualKey: 30, keyDown: true)!
                            rightBracketDown.flags = .maskCommand
                            rightBracketDown.post(tap: .cghidEventTap)
                            let rightBracketUp = CGEvent(keyboardEventSource: mySelf.eventSource, virtualKey: 30, keyDown: false)!
                            rightBracketUp.flags = .maskCommand
                            rightBracketUp.post(tap: .cghidEventTap)
                            return nil
                        }
                    }

                } else if type == .keyUp {
                    if keyCode == 2 { // d
                        if flags.intersection(mySelf.allModifiers).isEmpty {
                            mySelf.stopScroll()
                            return nil
                        }
                    } else if keyCode == 14 { // e
                        if flags.intersection(mySelf.allModifiers).isEmpty {
                            mySelf.stopScroll()
                            return nil
                        }
                    }
                }

                return Unmanaged.passUnretained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )

        if let tap = eventTap {
            let runLoopSrc = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)!
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSrc, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopScroll()
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            eventTap = nil
        }
    }
    
    func debugLog(_ message: String) {
        let fileManager = FileManager.default

        // 1. App 支持路径
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

        // 2. App 专属子目录
        let logDirectory = baseURL.appendingPathComponent("simplevimac/logs", isDirectory: true)

        // 3. 确保目录存在
        if !fileManager.fileExists(atPath: logDirectory.path) {
            try? fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        }

        // 4. 写入日志文件
        let logFile = logDirectory.appendingPathComponent("myapp_log.txt")

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let fullMessage = "[\(timestamp)] \(message)\n"

        if let handle = try? FileHandle(forWritingTo: logFile) {
            handle.seekToEndOfFile()
            handle.write(Data(fullMessage.utf8))
            handle.closeFile()
        } else {
            try? fullMessage.write(to: logFile, atomically: true, encoding: .utf8)
        }
    }


}
