//
//  AppConfigManager.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/7/4.
//

import Foundation
import CoreGraphics

class Config: ObservableObject, Codable {
    @Published var iSwitch: Bool
    @Published var mode: ModeType
    @Published var iDefault: [KeyMapper.KeyBinding]
    @Published var app: [AppLevelConfig]

    var trieMap: [UInt64: KeyMapper.Trie]
    var appMap: [String: AppLevelConfig]
    var allTriggerSet: Set<KeyMapper.KeyCombo>

    enum CodingKeys: String, CodingKey {
        case iSwitch, mode, iDefault, app
    }
    
    enum ModeType: String, Codable, CaseIterable {
        case disable
        case globallyEffective
        case whiteListEffective
    }
    
    enum BlacklistLevel: String, Codable, CaseIterable {
        case global
        case app
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        iSwitch = try container.decode(Bool.self, forKey: .iSwitch)
        mode = try container.decode(ModeType.self, forKey: .mode)
        iDefault = try container.decode([KeyMapper.KeyBinding].self, forKey: .iDefault)
        app = try container.decode([AppLevelConfig].self, forKey: .app)
        trieMap = [:]
        appMap = [:]
        allTriggerSet = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(iSwitch, forKey: .iSwitch)
        try container.encode(mode, forKey: .mode)
        try container.encode(iDefault, forKey: .iDefault)
        try container.encode(app, forKey: .app)
    }

    init(iSwitch: Bool, mode: ModeType, iDefault: [KeyMapper.KeyBinding], trieMap: [UInt64: KeyMapper.Trie], app: [AppLevelConfig], appMap: [String: AppLevelConfig],allTriggerSet: Set<KeyMapper.KeyCombo>) {
        self.iSwitch = iSwitch
        self.mode = mode
        self.iDefault = iDefault
        self.trieMap = trieMap
        self.app = app
        self.appMap = appMap
        self.allTriggerSet = allTriggerSet
    }
    
    init() {
        self.iSwitch = true
        self.mode = .disable
        self.iDefault = []
        self.app = []
        self.trieMap = [:]
        self.appMap = [:]
        self.allTriggerSet = []
    }

    class AppLevelConfig: ObservableObject, Codable, Identifiable {
        @Published var id = UUID()

        @Published var bundleId: String
        @Published var iSwitch: Bool
        @Published var mode: ModeType
        @Published var iDefault: [KeyMapper.KeyBinding]
        @Published var inBlacklist: Bool
        @Published var window: WindowLevelGroup

        var trieMap: [UInt64: KeyMapper.Trie]

        enum CodingKeys: String, CodingKey {
            case bundleId, iSwitch, mode, iDefault, inBlacklist, window
        }

        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            bundleId = try container.decode(String.self, forKey: .bundleId)
            iSwitch = try container.decode(Bool.self, forKey: .iSwitch)
            mode = try container.decode(ModeType.self, forKey: .mode)
            iDefault = try container.decode([KeyMapper.KeyBinding].self, forKey: .iDefault)
            inBlacklist = try container.decode(Bool.self, forKey: .inBlacklist)
            window = try container.decode(WindowLevelGroup.self, forKey: .window)
            trieMap = [:]
        }

        init(bundleId: String, iSwitch: Bool, mode: ModeType, iDefault: [KeyMapper.KeyBinding], inBlacklist: Bool, trieMap: [UInt64: KeyMapper.Trie], window: WindowLevelGroup) {
            self.bundleId = bundleId
            self.iSwitch = iSwitch
            self.mode = mode
            self.iDefault = iDefault
            self.inBlacklist = inBlacklist
            self.trieMap = trieMap
            self.window = window
        }
        
        init() {
            self.bundleId = ""
            self.iSwitch = true
            self.mode = .globallyEffective
            self.iDefault = []
            self.inBlacklist = false
            self.trieMap = [:]
            self.window = WindowLevelGroup()
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(bundleId, forKey: .bundleId)
            try container.encode(iSwitch, forKey: .iSwitch)
            try container.encode(mode, forKey: .mode)
            try container.encode(iDefault, forKey: .iDefault)
            try container.encode(inBlacklist, forKey: .inBlacklist)
            try container.encodeIfPresent(window, forKey: .window)
        }
    }

    class WindowLevelGroup: ObservableObject, Codable {
        @Published var mode: ModeType
        @Published var title: [WindowLevelConfig]
        @Published var url: [WindowLevelConfig]
        
        var titleMap: [String: WindowLevelConfig]
        var urlRadixTrie: RadixTrie

        enum CodingKeys: String, CodingKey {
            case mode, title, url
        }
        
        enum ModeType: String, Codable, CaseIterable {
            case title
            case url
        }

        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            mode = try container.decode(ModeType.self, forKey: .mode)
            title = try container.decode([WindowLevelConfig].self, forKey: .title)
            url = try container.decode([WindowLevelConfig].self, forKey: .url)
            titleMap = [:]
            urlRadixTrie = RadixTrie()
        }

        init(mode: ModeType = .title, title: [WindowLevelConfig] = [], url: [WindowLevelConfig] = [], titleMap: [String: WindowLevelConfig] = [:], urlRadixTrie: RadixTrie = RadixTrie()) {
            self.mode = mode
            self.title = title
            self.url = url
            self.titleMap = titleMap
            self.urlRadixTrie = urlRadixTrie
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(mode, forKey: .mode)
            try container.encode(title, forKey: .title)
            try container.encode(url, forKey: .url)
        }
    }

    class WindowLevelConfig: ObservableObject, Codable, Identifiable {
        @Published var id = UUID()
        
        @Published var key: String
        @Published var iSwitch: Bool
        @Published var iDefault: [KeyMapper.KeyBinding]
        @Published var inBlacklist: Bool
        @Published var blacklistLevel: BlacklistLevel
        
        var trieMap: [UInt64: KeyMapper.Trie]

        enum CodingKeys: String, CodingKey {
            case iSwitch, inBlacklist, blacklistLevel, iDefault, key
        }

        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            iSwitch = try container.decode(Bool.self, forKey: .iSwitch)
            iDefault = try container.decode([KeyMapper.KeyBinding].self, forKey: .iDefault)
            inBlacklist = try container.decode(Bool.self, forKey: .inBlacklist)
            blacklistLevel = try container.decode(BlacklistLevel.self, forKey: .blacklistLevel)
            key = try container.decode(String.self, forKey: .key)
            trieMap = [:]
        }

        init(iSwitch: Bool, iDefault: [KeyMapper.KeyBinding], inBlacklist: Bool, blacklistLevel: BlacklistLevel,key: String, trieMap: [UInt64: KeyMapper.Trie]) {
            self.iSwitch = iSwitch
            self.iDefault = iDefault
            self.inBlacklist = inBlacklist
            self.blacklistLevel = blacklistLevel
            self.key = key
            self.trieMap = trieMap
        }
        
        init() {
            self.iSwitch = true
            self.iDefault = []
            self.inBlacklist = false
            self.blacklistLevel = .app
            self.key = ""
            self.trieMap = [:]
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(iSwitch, forKey: .iSwitch)
            try container.encode(iDefault, forKey: .iDefault)
            try container.encode(inBlacklist, forKey: .inBlacklist)
            try container.encode(blacklistLevel, forKey: .blacklistLevel)
            try container.encode(key, forKey: .key)
        }
    }
    
    class RadixTrieNode {
        var key: String
        var value: Config.WindowLevelConfig?
        var children: [RadixTrieNode]

        init(key: String, value: Config.WindowLevelConfig? = nil) {
            self.key = key
            self.value = value
            self.children = []
        }
    }

    class RadixTrie {
        private let root = RadixTrieNode(key: "")

        func insert(_ url: String, value: Config.WindowLevelConfig) {
            insert(from: root, url, value)
        }

        private func insert(from node: RadixTrieNode, _ url: String, _ value: Config.WindowLevelConfig) {
            for child in node.children {
                let commonPrefix = url.commonPrefix(with: child.key)
                if commonPrefix.isEmpty { continue }

                if commonPrefix == child.key {
                    let suffix = String(url.dropFirst(commonPrefix.count))
                    insert(from: child, suffix, value)
                    return
                }

                let existingSuffix = String(child.key.dropFirst(commonPrefix.count))
                let newChild = RadixTrieNode(key: existingSuffix, value: child.value)
                newChild.children = child.children

                child.key = commonPrefix
                child.children = [newChild]
                child.value = nil

                let remainingSuffix = String(url.dropFirst(commonPrefix.count))
                if !remainingSuffix.isEmpty {
                    let anotherChild = RadixTrieNode(key: remainingSuffix, value: value)
                    child.children.append(anotherChild)
                } else {
                    child.value = value
                }
                return
            }

            node.children.append(RadixTrieNode(key: url, value: value))
        }

        func longestPrefixMatch(_ target: String) -> Config.WindowLevelConfig? {
            return longestPrefixMatch(from: root, in: target, from: target.startIndex)
        }

        func longestPrefixMatch(from node: RadixTrieNode, in target: String, from index: String.Index) -> Config.WindowLevelConfig? {
            for child in node.children {
                let keyCount = child.key.count
                let endIndex = target.index(index, offsetBy: keyCount, limitedBy: target.endIndex) ?? target.endIndex
                if target[index..<endIndex] == child.key {
                    if endIndex == target.endIndex {
                        return child.value ?? node.value
                    }
                    if let match = longestPrefixMatch(from: child, in: target, from: endIndex) {
                        return match
                    }
                }
            }
            return node.value
        }
    }
    
    static func appendTriggers(from keyBindings: [KeyMapper.KeyBinding], allTriggerSet: inout Set<KeyMapper.KeyCombo>) {
        for binding in keyBindings {
            for c in binding.trigger.keyCode {
                allTriggerSet.insert(KeyMapper.KeyCombo(keyCode: [c],modifiers: binding.trigger.modifiers))
            }
        }
    }
    
    
    static func load(from url: URL) throws -> Config {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let config = try decoder.decode(Config.self, from: data)
        
        let configKeyBindings: [KeyMapper.KeyBinding] = config.iDefault.filter { $0.iSwitch }
        
        KeyMapper.toTrieMap(keyBindings: configKeyBindings, trieMap: &config.trieMap)
        appendTriggers(from: configKeyBindings, allTriggerSet: &config.allTriggerSet)
        
        config.app.forEach { appCfg in
            let appCfgKeyBindings: [KeyMapper.KeyBinding] = appCfg.iDefault.filter { $0.iSwitch }
            
            KeyMapper.toTrieMap(keyBindings: appCfgKeyBindings, trieMap: &appCfg.trieMap)
            appendTriggers(from: appCfgKeyBindings, allTriggerSet: &config.allTriggerSet)

            appCfg.window.title.forEach { titleCfg in
                let titleCfgKeyBindings = titleCfg.iDefault.filter { $0.iSwitch }
                
                KeyMapper.toTrieMap(keyBindings: titleCfgKeyBindings, trieMap: &titleCfg.trieMap)
                appendTriggers(from: titleCfgKeyBindings, allTriggerSet: &config.allTriggerSet)

                appCfg.window.titleMap[titleCfg.key] = titleCfg
            }

            appCfg.window.url.forEach { urlCfg in
                let urlCfgKeyBindings = urlCfg.iDefault.filter { $0.iSwitch }
                
                KeyMapper.toTrieMap(keyBindings: urlCfgKeyBindings, trieMap: &urlCfg.trieMap)
                appendTriggers(from: urlCfgKeyBindings, allTriggerSet: &config.allTriggerSet)

                appCfg.window.urlRadixTrie.insert(urlCfg.key, value: urlCfg)
            }
            // 新增 appMap 初始化逻辑
            if !appCfg.bundleId.isEmpty {
                config.appMap[appCfg.bundleId] = appCfg
            }
        }

        return config
    }
    
    static func loadConfigFromFile() throws -> Config{
        let fileManager = FileManager.default

        // 1. App 支持路径
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

        // 2. App 专属子目录
        let logDirectory = baseURL.appendingPathComponent("simplevimac/data", isDirectory: true)
        if !fileManager.fileExists(atPath: logDirectory.path) {
            try fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        }
        
        let file = logDirectory.appendingPathComponent("config.json")
        
        // 3. 确保目录存在
        if !fileManager.fileExists(atPath: file.path) {
            if let bundleURL = Bundle.main.url(forResource: "config", withExtension: "json") {
                try fileManager.copyItem(at: bundleURL, to: file)
            }
        }
    
        let appConfigManage = try load(from: file)
        
        // Load iSwitch from separate file in the same directory
        let iswitchURL = logDirectory.appendingPathComponent("iswitch.json")
        
        if !fileManager.fileExists(atPath: iswitchURL.path) {
            if let bundleURL = Bundle.main.url(forResource: "iswitch", withExtension: "json") {
                try fileManager.copyItem(at: bundleURL, to: iswitchURL)
            }
        }
        
        let loadedISwitch = try loadISwitch(from: iswitchURL)
        
        // Overwrite config.iSwitch with value loaded from file
        appConfigManage.iSwitch = loadedISwitch
        
        return appConfigManage
    }
    
    static func match(trieMap: [UInt64: KeyMapper.Trie], keyCodes: [CGKeyCode], flags: CGEventFlags) -> KeyMapper.Trie.TrieSearchResult? {
        return KeyMapper.match(trieMap: trieMap, keyCodes: keyCodes, flags: flags)
    }
    
    func update(_ other: Config) {
        self.iSwitch = other.iSwitch
        self.mode = other.mode
        self.iDefault = other.iDefault
        self.app = other.app
    }
    
    func logAsJSON() {
        do {
            if let jsonString = try toJSONString(pretty: true) {
                Log.debugLog(jsonString)
            } else {
                Log.debugLog("无法将 JSON 数据转换为字符串")
            }
        } catch {
            Log.debugLog("JSON 编码失败: \(error)")
        }
    }
    
    func toJSONString(pretty: Bool = false) throws -> String?{
        let encoder = JSONEncoder()
        if pretty {
            encoder.outputFormatting = [.prettyPrinted]
        }
        encoder.outputFormatting.insert(.sortedKeys)
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8)
    }
    
    func saveToFile(_ saveISwitch: Bool = true) throws {
        let fileManager = FileManager.default

        // 1. App 支持路径
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

        // 2. App 专属子目录
        let logDirectory = baseURL.appendingPathComponent("simplevimac/data", isDirectory: true)

        do {
            try fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true, attributes: nil)
            let fileURL = logDirectory.appendingPathComponent("config.json")
            let iswitchURL = logDirectory.appendingPathComponent("iswitch.json")

            if let jsonString = try toJSONString(),
               let data = jsonString.data(using: .utf8) {
                try data.write(to: fileURL, options: [.atomic])
            } else {
                Log.debugLog("无法编码 JSON 字符串")
            }
            if saveISwitch {
                // Save iSwitch to separate file
                Self.saveISwitch(to: iswitchURL, value: self.iSwitch)
            }
        } catch {
            Log.debugLog("保存 JSON 到文件失败：\(error.localizedDescription)")
            throw AppError.unexpected("保存失败")
        }
    }
    
    func saveISwitchToFile() {
        let fileManager = FileManager.default

        // 1. App 支持路径
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

        // 2. App 专属子目录
        let logDirectory = baseURL.appendingPathComponent("simplevimac/data", isDirectory: true)

        do {
            try fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true, attributes: nil)
            let iswitchURL = logDirectory.appendingPathComponent("iswitch.json")

            // Save iSwitch to separate file
            Self.saveISwitch(to: iswitchURL, value: self.iSwitch)
        } catch {
            Log.debugLog("保存 JSON 到文件失败：\(error.localizedDescription)")
        }
    }
    

    /// Load iSwitch value from a separate JSON file. Returns true if file is missing or cannot decode.
    static func loadISwitch(from url: URL) throws -> Bool {
        let data = try Data(contentsOf: url)
        let result = try JSONDecoder().decode(Bool.self, from: data)
        return result
    }

    /// Save iSwitch value to a separate JSON file.
    static func saveISwitch(to url: URL, value: Bool) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url, options: [.atomic])
        } catch {
            Log.debugLog("保存 iswitch.json 失败：\(error.localizedDescription)")
        }
    }
}
