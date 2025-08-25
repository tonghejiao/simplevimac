//
//  AppDelegate.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/6/28
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppBusinessManager.shared.applicationDidFinishLaunching(notification)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        AppBusinessManager.shared.applicationWillTerminate(notification)
    }
}
