//
//  StatusItemController.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/12.
//

import Cocoa

class StatusItemController {
    static let shared = StatusItemController()
    
    var statusItem: NSStatusItem!

    private init() {
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(named: "StatusIconOff")
        }

        let menu = NSMenu()

        // 全局开关
        let globalSwitchItem = NSMenuItem(title: "全局开关", action: #selector(toggleGlobalSwitch), keyEquivalent: "")
        globalSwitchItem.target = self
        globalSwitchItem.tag = 1001
        menu.addItem(globalSwitchItem)

        // 设置
        let settingsItem = NSMenuItem(title: "设置", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        // 退出
        let quitItem = NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    /// 外部调用，用于更新菜单状态
    func updateGlobalSwitchState(isOn: Bool) {
        if let menu = statusItem.menu,
           let globalSwitchItem = menu.item(withTag: 1001) {
            globalSwitchItem.state = isOn ? .on : .off
        }
        
        if let button = statusItem.button {
            button.image = NSImage(named: isOn ? "StatusIconOn" : "StatusIconOff")
        }
    }

    @objc private func toggleGlobalSwitch() {
        AppBusinessManager.shared.toggleGlobalSwitch()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @objc private func openSettings() {
        MainWindowController.shared.showWindowAndActivate()
    }
}


