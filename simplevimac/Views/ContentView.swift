//
//  ContentView.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/6/27.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel.shared

    @StateObject private var config = AppViewModel.shared.config
    @StateObject private var hotkeyConfig = AppViewModel.shared.hotkeyConfig
    
    @State private var selectedIndex = 0

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    DispatchQueue.main.async {
                        NSApp.keyWindow?.makeFirstResponder(nil)
                    }
                }
            VStack(spacing: 0) {
                NavigationStack {
                    ToolbarSelectorView(selectedIndex: $selectedIndex)

                    if selectedIndex == 1 {
                        GlobalShortcutSettingsView(
                            metadata: $hotkeyConfig.globalSwitch,
                            onSuccess: {
                               hotkeyConfig.saveToFile()
                            },
                            onTrigger: {
                                AppBusinessManager.shared.toggleGlobalSwitch()
                            },
                            hotkeyErrorMessage: $appViewModel.globalSwitchErrorMessage
                        )
                    }

                    if selectedIndex == 0 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("默认配置")
                                .font(.headline)
                            
                            Picker("模式", selection: $config.mode) {
                                ForEach(Config.ModeType.allCases, id: \.self) { mode in
                                    Text(DisplayTextMapper.label(mode)).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            DefaultKeyBindingsView(bindings: $config.iDefault)
                            
                            Text("应用级规则")
                                .font(.headline)
                            
                            AppLevelGroupView(config: config)
                            
                            HStack {
                                Button("保存配置") {
                                    saveConfigToFile()
                                }
                            }
                            .padding(.top)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: 1000, alignment: .topLeading)
                    }
                }
            }
            .frame(maxHeight: 810, alignment: .topLeading)
        }
        .navigationTitle("simplevimac")
    }

    func saveConfigToFile() {
        // 校验全局默认配置快捷键不能为空
        let invalidBindings = config.iDefault.filter { $0.trigger.keyCode.isEmpty || ($0.action.keyCode.isEmpty && $0.action.mouse == nil && $0.action.command == nil)}
        if !invalidBindings.isEmpty {
            showAlert(message: "存在未填写快捷键的配置，保存失败")
            return
        }
        
        // 校验 bundleId 不能重复
        var seenBundleIds: Set<String> = []
        for app in config.app {
            // 校验 bundleId 非空
            if app.bundleId.trimmingCharacters(in: .whitespaces).isEmpty {
                showAlert(message: "存在应用配置未填写，保存失败")
                return
            }
            if seenBundleIds.contains(app.bundleId) {
                let appName = appInfo(for: app.bundleId).name ?? app.bundleId
                showAlert(message: "存在重复的应用配置：\(appName)")
                return
            }
            seenBundleIds.insert(app.bundleId)
            
            // 校验 app 默认配置快捷键不能为空
            let invalidAppBindings = app.iDefault.filter { $0.trigger.keyCode.isEmpty || ($0.action.keyCode.isEmpty && $0.action.mouse == nil && $0.action.command == nil)}
            if !invalidAppBindings.isEmpty {
                let appName = appInfo(for: app.bundleId).name ?? app.bundleId
                showAlert(message: "\(appName) 中存在未填写快捷键的配置，保存失败")
                return
            }
            
            let windowGroup = app.window
            // 校验 title.key 不能重复
            var titleKeys = Set<String>()
            for window in windowGroup.title {
                // 校验 window.key 非空
                if window.key.trimmingCharacters(in: .whitespaces).isEmpty {
                    let appName = appInfo(for: app.bundleId).name ?? app.bundleId
                    showAlert(message: "\(appName) 的标题窗口配置中存在未填写标识符")
                    return
                }
                if titleKeys.contains(window.key) {
                    let appName = appInfo(for: app.bundleId).name ?? app.bundleId
                    showAlert(message: "\(appName) 的标题窗口配置中存在重复标识符：\(window.key)")
                    return
                }
                titleKeys.insert(window.key)
                
                let invalidWindowBindings = window.iDefault.filter { $0.trigger.keyCode.isEmpty || ($0.action.keyCode.isEmpty && $0.action.mouse == nil && $0.action.command == nil)}
                if !invalidWindowBindings.isEmpty {
                    let appName = appInfo(for: app.bundleId).name ?? app.bundleId
                    showAlert(message: "\(appName) 的标题窗口配置中存在未填写快捷键的绑定，保存失败")
                    return
                }
            }
            
            // 校验 url.key 不能重复
            var urlKeys = Set<String>()
            for window in windowGroup.url {
                // 校验 window.key 非空
                if window.key.trimmingCharacters(in: .whitespaces).isEmpty {
                    let appName = appInfo(for: app.bundleId).name ?? app.bundleId
                    showAlert(message: "\(appName) 的网址窗口配置中存在未填写标识符")
                    return
                }
                if urlKeys.contains(window.key) {
                    let appName = appInfo(for: app.bundleId).name ?? app.bundleId
                    showAlert(message: "\(appName) 的网址窗口配置中存在重复标识符：\(window.key)")
                    return
                }
                urlKeys.insert(window.key)
                
                let invalidWindowBindings = window.iDefault.filter { $0.trigger.keyCode.isEmpty || ($0.action.keyCode.isEmpty && $0.action.mouse == nil && $0.action.command == nil)}
                if !invalidWindowBindings.isEmpty {
                    let appName = appInfo(for: app.bundleId).name ?? app.bundleId
                    showAlert(message: "\(appName) 的网址窗口配置中存在未填写快捷键的绑定，保存失败")
                    return
                }
            }
        }
        
        do {
            try config.saveToFile(false)
            AppBusinessManager.shared.config = try Config.loadConfigFromFile()
        } catch {
            showAlert(message: "保存失败")
        }
    }
    
    func appInfo(for bundleId: String) -> (icon: NSImage?, name: String?) {
        let workspace = NSWorkspace.shared
        if let url = workspace.urlForApplication(withBundleIdentifier: bundleId),
           let bundle = Bundle(url: url) {
            let icon = workspace.icon(forFile: url.path)
            let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            return (icon, name)
        }
        return (nil, nil)
    }
    
    func showAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "确定")
        alert.alertStyle = .warning
        alert.runModal()
    }
}
