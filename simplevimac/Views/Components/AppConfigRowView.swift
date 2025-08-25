//
//  AppConfigRowView.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/13.
//

import SwiftUICore
import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct AppConfigRowView: View {
    @Binding var appConfig: Config.AppLevelConfig
    @State private var icon: NSImage? = nil
    @State private var name: String? = nil
    @State private var isChevronHovering = false

    var body: some View {
        HStack(spacing: 4) {
            NavigationLink(destination: AppConfigDetailView(appConfig: appConfig)) {
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
                    .frame(width: 25, height: 25)
                    .contentShape(Rectangle())
                    .onHover { isHovering in
                        isChevronHovering = isHovering
                    }
            }
            .buttonStyle(.plain)

            if let icon = icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 20, height: 20)
            }

            Button(action: {
                pickApplication()
            }) {
                HStack(spacing: 4) {
                    Text(name ?? appConfig.bundleId)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Toggle("黑名单", isOn: $appConfig.inBlacklist)

            Toggle(isOn: $appConfig.iSwitch) {
                EmptyView()
            }
            .toggleStyle(.switch)
            .labelsHidden()
            .frame(width: 50)
        }
        .onAppear {
            updateAppInfo()
        }
    }

    private func updateAppInfo() {
        let workspace = NSWorkspace.shared
        if let url = workspace.urlForApplication(withBundleIdentifier: appConfig.bundleId),
           let bundle = Bundle(url: url) {
            icon = workspace.icon(forFile: url.path)
            name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
        } else {
            icon = nil
            name = nil
        }
    }

    private func pickApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        if panel.runModal() == .OK, let url = panel.url {
            if let bundle = Bundle(url: url), let id = bundle.bundleIdentifier {
                appConfig.bundleId = id
                updateAppInfo()
            }
        }
    }
}
