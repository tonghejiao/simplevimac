//
//  KeySpecEditor.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/13.
//

import SwiftUICore
import SwiftUI

struct KeySpecEditor: View {
    @Binding var spec: KeyMapper.KeySpec
    var showMouseAndCommand: Bool = true
    
    var body: some View {
        HStack(spacing: 12) {
            Text("键盘")
                .frame(width: 40)

            KeyCaptureField(
                keyCodes: $spec.keyCode,
                modifierFlags: $spec.modifiers,
                accumulateKeyCodes: true,
                needModifierFlags: false
            )

            if showMouseAndCommand {
                Picker("鼠标", selection: $spec.mouse) {
                    Text("无").tag(nil as KeyMapper.KeySpec.MouseAction?)
                    ForEach(KeyMapper.KeySpec.MouseAction.allCases, id: \.self) {
                        Text($0.rawValue).tag(Optional($0))
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 160)

                Picker("命令", selection: $spec.command) {
                    Text("无").tag(nil as KeyMapper.KeySpec.Command?)
                    ForEach(KeyMapper.KeySpec.Command.allCases, id: \.self) {
                        Text($0.rawValue).tag(Optional($0))
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 160)
            }
        }
    }
}
