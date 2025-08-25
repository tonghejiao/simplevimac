//
//  AppLevelGroupView.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/13.
//

import SwiftUICore
import SwiftUI

struct AppLevelGroupView: View {
    @ObservedObject var config: Config
    @State private var selectedAppIds: Set<UUID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView {
                if config.app.isEmpty {
                    VStack {
                        Spacer()
                        Text("暂无应用规则")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                        Spacer()
                    }
                    .frame(minHeight: 100)
                } else {
                    ForEach($config.app, id: \.id) { appConfig in
                        let uuid = appConfig.id
                        HStack {
                            Toggle(isOn: Binding<Bool>(
                                get: { selectedAppIds.contains(uuid) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedAppIds.insert(uuid)
                                    } else {
                                        selectedAppIds.remove(uuid)
                                    }
                                })
                            ) {
                                EmptyView()
                            }
                            .labelsHidden()
                            .frame(width: 20)
                            
                            AppConfigRowView(appConfig: appConfig)
                                .padding(.vertical, 4)
                        }
                        .padding(.horizontal, 10)
                    }
                }
            }
            .frame(height: 200)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.3))
            )

            HStack(spacing: 12) {
                Button("全选") {
                    let all = Set(config.app.map { $0.id })
                    if selectedAppIds == all {
                        selectedAppIds.removeAll()
                    } else {
                        selectedAppIds = all
                    }
                }

                Button("新增") {
                    config.app.append(Config.AppLevelConfig())
                }

                Button("删除") {
                    config.app.removeAll { selectedAppIds.contains($0.id) }
                    selectedAppIds.removeAll()
                }
                .disabled(selectedAppIds.isEmpty)
            }
            .padding(.leading, 12)
        }
    }

    private func appInfo(for bundleId: String) -> (icon: NSImage?, name: String?) {
        let workspace = NSWorkspace.shared
        if let url = workspace.urlForApplication(withBundleIdentifier: bundleId),
           let bundle = Bundle(url: url) {
            let icon = workspace.icon(forFile: url.path)
            let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            return (icon, name)
        }
        return (nil, nil)
    }
}
