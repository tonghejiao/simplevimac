//
//  HotKeyCenter.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/3.
//

import Carbon.HIToolbox
import Foundation

class HotKeyCenter {
    static let shared = HotKeyCenter()

    private var hotKeyRefs: [HotKeyID : EventHotKeyRef] = [:]
    private var handlers: [HotKeyID: () -> Void] = [:]

    private init() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(theEvent, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout.size(ofValue: hotKeyID), nil, &hotKeyID)
            HotKeyCenter.shared.handlers[HotKeyID(hotKeyID)]?()
            return noErr
        }, 1, &eventSpec, nil, nil)
    }

    func register(keyCode: CGKeyCode, modifiers: CGEventFlags, idGen: () -> EventHotKeyID, handler: @escaping () -> Void) -> Bool {
        let hotKeyID = idGen()

        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            carbonFlags(from: modifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            Log.debugLog("⚠️ RegisterEventHotKey failed with status: \(status)")
            return false
        }

        if let ref = hotKeyRef {
            let id = HotKeyID(hotKeyID)
            hotKeyRefs[id] = ref
            handlers[id] = handler
            return true
        }
        return false
    }
    
    func unregister(_ id: HotKeyID) {
        if let ref = hotKeyRefs[id] {
            UnregisterEventHotKey(ref)
            hotKeyRefs.removeValue(forKey: id)
            handlers.removeValue(forKey: id)
        }
    }
    
    func carbonFlags(from flags: CGEventFlags) -> UInt32 {
        var carbonFlags: UInt32 = 0
        if flags.contains(.maskCommand) { carbonFlags |= UInt32(cmdKey) }
        if flags.contains(.maskShift) { carbonFlags |= UInt32(shiftKey) }
        if flags.contains(.maskAlternate) { carbonFlags |= UInt32(optionKey) }
        if flags.contains(.maskControl) { carbonFlags |= UInt32(controlKey) }
        return carbonFlags
    }
}
