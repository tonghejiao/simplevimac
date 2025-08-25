//
//  WindowLevelConfigRowView.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/13.
//

import SwiftUICore
import SwiftUI

struct WindowLevelConfigRowView: View {
    @Binding var config: Config.WindowLevelConfig
    @State private var isChevronHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                NavigationLink(destination:
                    VStack(alignment: .leading, spacing: 12) {
                        DefaultKeyBindingsView(bindings: $config.iDefault)
                        .padding(.horizontal)
                    }
                    .frame(maxHeight: .infinity, alignment: .topLeading)
                    .navigationTitle("窗口级规则配置详情")
                ) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .background(
                            Group {
                                if isChevronHovering {
                                    Color.secondary.opacity(0.1)
                                } else {
                                    Color.clear
                                }
                            }
                        )
                        .cornerRadius(4)
                        .frame(width: 20)
                        .contentShape(Rectangle())
                        .onHover { isHovering in
                            isChevronHovering = isHovering
                        }
                }
                .buttonStyle(.plain)

                TextField("标识符", text: $config.key)
                    .textFieldStyle(.plain)
                
                HStack(spacing: 8) {
                    Toggle("黑名单", isOn: $config.inBlacklist)

                    if config.inBlacklist {
                        Picker("等级", selection: $config.blacklistLevel) {
                            ForEach(Config.BlacklistLevel.allCases, id: \.self) { level in
                                Text(DisplayTextMapper.label(level)).tag(level)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 200)
                    }
                }

                Toggle(isOn: $config.iSwitch) {
                    EmptyView()
                }
                .toggleStyle(.switch)
                .labelsHidden()
                .frame(width: 50)
            }
        }
        .padding(.vertical, 4)
        .cornerRadius(6)
    }
}
