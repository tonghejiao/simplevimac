//
//  AppViewModel.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/12.
//

import Foundation

class AppViewModel: ObservableObject {
    static var shared = AppViewModel()
    
    @Published var config = Config()
    @Published var hotkeyConfig = HotKeyConfig()
    
    @Published var globalSwitchErrorMessage: String? = nil
}
