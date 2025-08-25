//
//  KeyCaptureField.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/13.
//

import SwiftUICore
import SwiftUI

struct KeyCaptureField: View {
    @Binding var keyCodes: [CGKeyCode]
    @Binding var modifierFlags: CGEventFlags
    @State var clearTrigger = false
    var accumulateKeyCodes = false
    var needModifierFlags = true
    var onCommit: (([CGKeyCode], CGEventFlags) -> Void)? = nil

    private static let keyCodeMap: [CGKeyCode: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
        11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2", 20: "3",
        21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]",
        31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "↩", 37: "L", 38: "J", 39: "'", 40: "K",
        41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".", 48: "⇥", 49: "␣", 50: "`",
        51: "⌫", 53: "⎋", 96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9", 103: "F11", 109: "F10",
        111: "F12", 117: "⌦", 118: "F4", 120: "F2", 122: "F1", 123: "←", 124: "→", 125: "↓", 126: "↑"
    ]

    private static let modMap: [(CGEventFlags, String)] = [
        (.maskControl, "⌃"),
        (.maskAlternate, "⌥"),
        (.maskCommand, "⌘"),
        (.maskShift, "⇧"),
    ]
    
    private static let keyCodeSet = Set(keyCodeMap.keys)
    
    private static let allowModifiers = Constant.allowModifiers

    private var displayedKeyText: String {
        let keys = keyCodes.compactMap { Self.keyCodeMap[$0] }
        let mods = Self.modMap.compactMap { (flag, symbol) in
            modifierFlags.contains(flag) ? symbol : nil
        }

        if keys.isEmpty && mods.isEmpty {
            return "点击输入"
        }

        return (mods + keys).joined(separator: "")
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            RepresentedKeyCaptureView(
                keyCodes: $keyCodes,
                modifierFlags: $modifierFlags,
                clearTrigger: $clearTrigger,
                accumulateKeyCodes: accumulateKeyCodes,
                needModifierFlags: needModifierFlags,
                onCommit: onCommit,
                allowedKeyCodes: Self.keyCodeSet,
                allowedModifierFlags: Self.allowModifiers
            )
            .frame(width: 100, height: 24)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.5))
            )
            .background(Color.white)
            .overlay(
                Text(displayedKeyText)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 6)
                    .allowsHitTesting(false),
                alignment: .leading
            )

            if !keyCodes.isEmpty || !modifierFlags.isEmpty {
                Button {
                    clearTrigger = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        clearTrigger = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
        }
    }
}
