//
//  RepresentedKeyCaptureView.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/13.
//

import SwiftUI

struct RepresentedKeyCaptureView: NSViewRepresentable {
    @Binding var keyCodes: [CGKeyCode]
    @Binding var modifierFlags: CGEventFlags
    @Binding var clearTrigger: Bool
    var accumulateKeyCodes: Bool
    var needModifierFlags: Bool
    var onCommit: (([CGKeyCode], CGEventFlags) -> Void)? = nil
    var allowedKeyCodes: Set<CGKeyCode>? = nil
    var allowedModifierFlags: CGEventFlags? = nil

    func makeNSView(context: Context) -> NSView {
        let view = KeyCaptureNSView()
        view.accumulateKeyCodes = accumulateKeyCodes
        view.needModifierFlags = needModifierFlags
        view.allowedKeyCodes = allowedKeyCodes
        view.allowedModifierFlags = allowedModifierFlags
        view.onKeyPress = { codes, flags in
            DispatchQueue.main.async {
                self.keyCodes = codes
                self.modifierFlags = flags
                onCommit?(codes, flags)
            }
        }
        view.onFocus = {
            AppBusinessManager.shared.tempSetGlobalSwitch(false)
        }
        view.unFocus = {
            AppBusinessManager.shared.resumeGlobalSwitch()
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let keyView = nsView as? KeyCaptureNSView {
            keyView.accumulateKeyCodes = accumulateKeyCodes
            if clearTrigger {
                keyView.clearKeyCodes()
            }
        }
    }
}
