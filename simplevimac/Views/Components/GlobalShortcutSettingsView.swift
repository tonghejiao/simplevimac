//
//  GlobalShortcutSettingsView.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/13.
//

import SwiftUICore

struct GlobalShortcutSettingsView: View {
    @Binding var metadata: HotKeyConfig.HotKeyMetadata
    var onSuccess: () -> Void
    var onTrigger: () -> Void
    @Binding var hotkeyErrorMessage: String?
    @State private var isHoveringIcon: Bool = false

    var body: some View {
        HStack(spacing: 100) {
            Text("全局开关")
                .font(.headline)
            HStack {
                KeyCaptureField(
                    keyCodes: $metadata.keyCode,
                    modifierFlags: $metadata.modifiers,
                    onCommit: { _, _ in
                        HotKeyRegistrar.register(metadata,
                            onTrigger: {
                                //todo 全局开关
                                onTrigger()
                            },
                            onSuccess: {
                                onSuccess()
                                hotkeyErrorMessage = nil
                            },
                            onFailure: { hotkeyErrorMessage = "快捷键注册失败，可能已被系统或其他程序占用" }
                        )
                    }
                )
                ZStack {
                    if let error = hotkeyErrorMessage {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .padding(4)
                            .background(Color.clear)
                            .foregroundColor(.red)
                            .onHover { hovering in
                                withAnimation(.easeInOut(duration: 0.08)) {
                                    isHoveringIcon = hovering
                                }
                            }
                            .overlay(
                                Group {
                                    if isHoveringIcon {
                                        TooltipBubble(text: error)
                                            .offset(x: 0, y: -36)
                                            .transition(.opacity.combined(with: .move(edge: .top)))
                                            .zIndex(1)
                                    }
                                },
                                alignment: .topTrailing
                            )
                    }
                }
                .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal)
    }
}
