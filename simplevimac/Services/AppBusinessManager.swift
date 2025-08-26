//
//  AppBusinessManager.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/12.
//

import Cocoa

class AppBusinessManager {
    static let shared = AppBusinessManager()
    // 业务依赖
    var eventTap: CFMachPort?
    var eventSource: CGEventSource? = CGEventSource(stateID: .hidSystemState)
    
    var mode = Mode.normal

    var config: Config? = nil
    var keyCodeCache: [CGKeyCode] = []
    var lastGPressTime: TimeInterval = 0
    let gPressInterval: TimeInterval = 0.3
    var isKeyCodeCacheUpdate: Bool = false
    var needClearKeyCodeCache = true
    
    var keyDownSet: Set<KeyMapper.KeyCombo> = []

    let accessibilityElementManager = AccessibilityElementManager.shared
    let commandExecutor = CommandExecutor.shared
    let mouseActionExecutor = MouseActionExecutor.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            requestAccessibilityPermission()
            try initData()
            setupGlobalKeyListener()
            
            if let appConfig = self.config {
                StatusItemController.shared.updateGlobalSwitchState(isOn: appConfig.iSwitch)
            }
            
            //Register global shortcut keys
            HotKeyRegistrar.register(
                AppViewModel.shared.hotkeyConfig.globalSwitch,
                onTrigger: {
                    self.toggleGlobalSwitch()
                },
                onSuccess: { AppViewModel.shared.globalSwitchErrorMessage = nil },
                onFailure: { AppViewModel.shared.globalSwitchErrorMessage = "快捷键注册失败，可能已被系统或其他程序占用"}
            )
        } catch {
            Log.debugLog("\(error)")
        }
    }
    
    func toggleGlobalSwitch() {
        if let appConfig = self.config {
            appConfig.iSwitch = !appConfig.iSwitch
            appConfig.saveISwitchToFile()
            StatusItemController.shared.updateGlobalSwitchState(isOn: appConfig.iSwitch)
        }
    }

    func requestAccessibilityPermission() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(opts) else {
            Log.debugLog("请在 系统设置 → 隐私与安全性 → 辅助功能 中授权本应用")
            return
        }
    }
    
    func initData() throws{
        do {
            self.config = try Config.loadConfigFromFile()
            
            AppViewModel.shared.config = try Config.loadConfigFromFile()
            AppViewModel.shared.hotkeyConfig = try HotKeyConfig.loadConfigFromFile()
        } catch {
            throw AppError.unexpected("❌ 加载失败：\(error)")
        }
    }
    
    func clearTempVars() {
        accessibilityElementManager.clearTempVars()
        
        self.isKeyCodeCacheUpdate = false
        self.needClearKeyCodeCache = true
    }
    
    func getKeyCodeCache(type: CGEventType, keyCode: CGKeyCode) -> [CGKeyCode] {
        if type == .keyDown {
            if self.isKeyCodeCacheUpdate {
                return self.keyCodeCache
            }
            self.keyCodeCache.append(keyCode)
            self.isKeyCodeCacheUpdate = true
            return self.keyCodeCache
        } else {
            return [keyCode]
        }
    }
    
    func handleKeyEvent(type: CGEventType, event: CGEvent) throws -> Unmanaged<CGEvent>? {
        guard let config = self.config, config.iSwitch else {
            return Unmanaged.passUnretained(event)
        }
        
        SmoothScroller.stop()
        if self.mode != .hints {
            commandExecutor.clearOverlays()
        }
        
        defer {
            if self.mode == .normal, type == .keyDown, self.needClearKeyCodeCache {
                self.clearKeyCodeCache()
            }
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        let cgKeyCode = CGKeyCode(keyCode)
        let cleanedFlags = flags.intersection(Constant.allowModifiers)
        
        if self.mode == .hints && type == .keyDown {
            if cgKeyCode == 51 { // backspace key
                if !self.keyCodeCache.isEmpty {
                    self.keyCodeCache.removeLast()
                }
            } else if cgKeyCode != 49 { //空格
                self.keyCodeCache.append(cgKeyCode)
            }
            
            let inputString = KeySpecBase.keyCodeToString(self.keyCodeCache)
            if cgKeyCode == 49 { //空格
                self.handleHintInput(inputString,true)
            } else {
                self.handleHintInput(inputString)
            }
            
            return nil
        }

        if !config.allTriggerSet.contains(KeyMapper.KeyCombo(keyCode: [cgKeyCode], modifiers: cleanedFlags)) {
            return Unmanaged.passUnretained(event)
        }
                
        self.clearTempVars()
        if (cleanedFlags.isEmpty || cleanedFlags == [.maskShift] )
            ,try accessibilityElementManager.isTextInputFocused() {
            return Unmanaged.passUnretained(event)
        }
        
        var inAppLevelConfig = false
        var notGlobalBlacklist = true
        if !config.app.isEmpty,
           let bundleId = try accessibilityElementManager.getBundleIdOfFocusedApp(),
           let appLevelConfig = config.appMap[bundleId] {
            inAppLevelConfig = true
            notGlobalBlacklist = !appLevelConfig.inBlacklist
            if appLevelConfig.iSwitch {
                var inWindowLevelConfig = false
                var notAppLevelBlacklist = true
                let windowLevelGroup = appLevelConfig.window
                switch windowLevelGroup.mode {
                    case .title:
                        if !windowLevelGroup.titleMap.isEmpty,
                           let title = try accessibilityElementManager.getTitleOfFocusedWindow(),
                           let windowLevelConfig = windowLevelGroup.titleMap[title] {
                            inWindowLevelConfig = true
                            if windowLevelConfig.inBlacklist {
                                switch windowLevelConfig.blacklistLevel {
                                case .global:
                                    notGlobalBlacklist = false
                                case .app:
                                    notAppLevelBlacklist = false
                                }
                            }
                            if windowLevelConfig.iSwitch {
                                let windowTileKeyBinding = Config.match(trieMap: windowLevelConfig.trieMap, keyCodes: getKeyCodeCache(type: type, keyCode: cgKeyCode), flags: cleanedFlags)
                                if self.dealTrieSearchResult(type: type, trieSearchResult: windowTileKeyBinding) {
                                    return nil
                                }
                            }
                        }
                    case .url:
                        if !windowLevelGroup.url.isEmpty,
                           let url = try accessibilityElementManager.getURLOfFocusedWindow(),
                           let urlLevelConfig = windowLevelGroup.urlRadixTrie.longestPrefixMatch(url) {
                            inWindowLevelConfig = true
                            if urlLevelConfig.inBlacklist {
                                switch urlLevelConfig.blacklistLevel {
                                case .global:
                                    notGlobalBlacklist = false
                                case .app:
                                    notAppLevelBlacklist = false
                                }
                            }
                            if urlLevelConfig.iSwitch {
                                let windowUrlKeyBinding = Config.match(trieMap: urlLevelConfig.trieMap, keyCodes: getKeyCodeCache(type: type, keyCode: cgKeyCode), flags: cleanedFlags)
                                if self.dealTrieSearchResult(type: type, trieSearchResult: windowUrlKeyBinding) {
                                    return nil
                                }
                            }
                        }
                    }
                
                if notAppLevelBlacklist {
                    switch appLevelConfig.mode {
                        case .disable:
                            break
                        case .whiteListEffective:
                            if inWindowLevelConfig {
                                let appKeyBinding = Config.match(trieMap: appLevelConfig.trieMap, keyCodes: getKeyCodeCache(type: type, keyCode: cgKeyCode), flags: cleanedFlags)
                                if self.dealTrieSearchResult(type: type, trieSearchResult: appKeyBinding) {
                                    return nil
                                }
                            }
                        case .globallyEffective:
                            let appKeyBinding = Config.match(trieMap: appLevelConfig.trieMap, keyCodes: getKeyCodeCache(type: type, keyCode: cgKeyCode), flags: cleanedFlags)
                            if self.dealTrieSearchResult(type: type, trieSearchResult: appKeyBinding) {
                                return nil
                            }
                    }
                }
            }
        }
        if notGlobalBlacklist {
            switch config.mode {
                case .disable:
                    break
                case .whiteListEffective:
                    if inAppLevelConfig {
                        let rootKeyBinding = Config.match(trieMap: config.trieMap, keyCodes: getKeyCodeCache(type: type, keyCode: cgKeyCode), flags: cleanedFlags)
                        if self.dealTrieSearchResult(type: type, trieSearchResult: rootKeyBinding) {
                            return nil
                        }
                    }
                case .globallyEffective:
                    let rootKeyBinding = Config.match(trieMap: config.trieMap, keyCodes: getKeyCodeCache(type: type, keyCode: cgKeyCode), flags: cleanedFlags)
                    if self.dealTrieSearchResult(type: type, trieSearchResult: rootKeyBinding) {
                        return nil
                    }
            }
        }
        return Unmanaged.passUnretained(event)
    }
    
    func setupGlobalKeyListener() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue | 1 << CGEventType.keyUp.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { (proxy, type, event, userInfo) -> Unmanaged<CGEvent>? in
                do {
                    return try AppBusinessManager.shared.handleKeyEvent(type: type, event: event)
                } catch {
                    Log.debugLog("\(error)")
                    return Unmanaged.passUnretained(event)
                }
            },
            userInfo: nil
        )

        if let tap = eventTap {
            let runLoopSrc = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)!
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSrc, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }
    
    func dealTrieSearchResult(type: CGEventType , trieSearchResult: KeyMapper.Trie.TrieSearchResult?) -> Bool {
        if type == .keyDown {
            if trieSearchResult == nil {
                return false
            }
            switch trieSearchResult {
                case .none,.noMatch:
                    break
                case .matchedNoValue:
                    self.lastGPressTime = Date().timeIntervalSince1970
                    self.needClearKeyCodeCache = false
                    return true
                case .matchedWithValue(let binding):
                    let lastGPressTime = self.lastGPressTime
                    let keyCodeCacheCount = self.keyCodeCache.count
                    if keyCodeCacheCount == 1 {
                        if self.doActionkeyDown(keyBinding: binding) {
                            return true
                        }
                    } else {
                        let now = Date().timeIntervalSince1970
                        if now - lastGPressTime < self.gPressInterval {
                            if self.doActionkeyDown(keyBinding: binding) {
                                return true
                            }
                        }
                    }
            }
        }
        else if type == .keyUp {
            if trieSearchResult == nil {
                return false
            }
            switch trieSearchResult {
                case .none,.noMatch,.matchedNoValue: break
                case .matchedWithValue(let binding):
                    if self.doActionkeyUp(keyBinding: binding) {
                        return true
                    }
            }
        }
        return false
    }

    func doActionkeyDown(keyBinding :KeyMapper.KeyBinding) -> Bool{
        var success = false
        //Simulate the key
        for keyCodeItem in keyBinding.action.keyCode {
            let kDown = CGEvent(keyboardEventSource: self.eventSource, virtualKey: keyCodeItem, keyDown: true)!
            kDown.flags = keyBinding.action.modifiers
            kDown.post(tap: .cghidEventTap)
            
            addInKeyDownSet(keyCodeItem, keyBinding.action.modifiers)
            success = true
        }
        
        if mouseActionExecutor.execute(mouseAction: keyBinding.action.mouse) {
            success = true
        }
        
        if commandExecutor.execute(command: keyBinding.action.command) {
            success = true
        }
        return success
    }
    
    func doActionkeyUp(keyBinding :KeyMapper.KeyBinding) -> Bool{
        var success = false
        //Simulate the key
        for keyCodeItem in keyBinding.action.keyCode {
            let keyCombo = KeyMapper.KeyCombo(keyCode: [keyCodeItem], modifiers: keyBinding.action.modifiers)
            if keyDownSet.contains(keyCombo) {
                let kUp = CGEvent(keyboardEventSource: self.eventSource, virtualKey: keyCodeItem, keyDown: false)!
                kUp.flags = keyBinding.action.modifiers
                kUp.post(tap: .cghidEventTap)
                
                keyDownSet.remove(keyCombo)
                success = true
            }
        }
        return success
    }
    
    func handleHintInput(_ input: String, _ clickFiist: Bool = false) {
        let inputLowercased = input.lowercased()
        // 1. 找到所有前缀匹配的 hints
        var matches: [ClickableElement] = []
        if input.isEmpty {
            matches = commandExecutor.currentHints
        } else {
            matches = commandExecutor.currentHints.filter {
                $0.hintChar.lowercased().hasPrefix(inputLowercased)
            }
        }
        
        if matches.isEmpty {
            // 没有任何匹配，清理掉 overlays
            commandExecutor.clearOverlays()
            self.switchMode(.normal)
            return
        }

        // 2. 如果有完全匹配的，直接点击
        if matches.count == 1 || clickFiist {
            let match = matches[0]
            if let screenFrame = NSScreen.main?.frame {
                let center = NSPoint(
                    x: match.frame.midX,
                    y: screenFrame.height - match.frame.midY
                )
                MouseUtils.leftClick(position: center)
            }
            commandExecutor.clearOverlays()
            self.switchMode(.normal)
            return
        }

        // 3. 如果没有完全匹配但还有多个前缀匹配，就只展示这些
        commandExecutor.showHintOverlays(matches)
    }
    
    func switchMode(_ mode: Mode) {
        self.mode = mode
        self.clearKeyCodeCache()
    }
    
    func clearKeyCodeCache(){
        self.keyCodeCache.removeAll(keepingCapacity: false)
        self.lastGPressTime = 0
    }
    
    func addInKeyDownSet(_ keyCode: CGKeyCode, _ modifiers: CGEventFlags){
        if keyDownSet.count > 1000 {
            return
        }
        keyDownSet.insert(KeyMapper.KeyCombo(keyCode: [keyCode], modifiers: modifiers))
    }
        
    func applicationWillTerminate(_ notification: Notification) {
        SmoothScroller.stop()
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            eventTap = nil
        }
    }
}
