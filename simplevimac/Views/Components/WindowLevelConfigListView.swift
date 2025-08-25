//
//  WindowLevelConfigListView.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/13.
//

import SwiftUICore
import SwiftUI

struct WindowLevelConfigListView: View {
    @Binding var configs: [Config.WindowLevelConfig]

    @State private var selectedKeys: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView {
                if configs.isEmpty {
                    VStack {
                        Spacer()
                        Text("暂无窗口级规则")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                        Spacer()
                    }
                    .frame(minHeight: 100)
                } else {
                    ForEach($configs) { $config in
                        HStack {
                            Toggle(isOn: Binding(
                                get: { selectedKeys.contains(config.key) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedKeys.insert(config.key)
                                    } else {
                                        selectedKeys.remove(config.key)
                                    }
                                }
                            )) {
                                EmptyView()
                            }
                            .labelsHidden()
                            .frame(width: 20)
                            
                            WindowLevelConfigRowView(config: $config)
                        }
                        .padding(.horizontal, 10)

                    }
                }
            }
            .frame(maxHeight: 200)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.3))
            )

            HStack(spacing: 12) {
                Button("全选") {
                    let allKeys = Set(configs.map { $0.key })
                    if selectedKeys == allKeys {
                        selectedKeys.removeAll()
                    } else {
                        selectedKeys = allKeys
                    }
                }

                Button("新增") {
                    let newConfig = Config.WindowLevelConfig()
                    configs.append(newConfig)
                }

                Button("删除") {
                    configs.removeAll { selectedKeys.contains($0.key) }
                    selectedKeys.removeAll()
                }
                .disabled(selectedKeys.isEmpty)
            }
            .padding(.top, 8)
        }
    }
}
