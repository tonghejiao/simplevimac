//
//  HotKeyConfig.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/12.
//

import Foundation
import CoreGraphics

class HotKeyConfig: ObservableObject, Codable {
    @Published var globalSwitch: HotKeyMetadata
    
    class HotKeyMetadata: KeySpecBase {
        var id: HotKeyID?

        enum CodingKeys: String, CodingKey {
            case id
        }

        init(id: HotKeyID? = nil, keyCode: [CGKeyCode] = [], modifiers: CGEventFlags = CGEventFlags()) {
            self.id = id
            super.init(keyCode: keyCode, modifiers: modifiers)
        }

        required init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try c.decodeIfPresent(HotKeyID.self, forKey: .id)
            try super.init(from: decoder)
        }

        override func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encodeIfPresent(id, forKey: .id)
            try super.encode(to: encoder)
        }
        
    }

    enum CodingKeys: String, CodingKey {
        case globalSwitch
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decoded = try container.decode(HotKeyMetadata.self, forKey: .globalSwitch)
        self._globalSwitch = Published(initialValue: decoded)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(globalSwitch, forKey: .globalSwitch)
    }
    
    init(globalSwitch: HotKeyMetadata = HotKeyMetadata()) {
        self.globalSwitch = globalSwitch
    }
    
    func genId(for signature: UInt32) -> UInt32 {
        var ids: [UInt32] = []
        if let id = globalSwitch.id, id.signature == signature {
            ids.append(id.id)
        }
        // 以后加更多字段...
        return (ids.max() ?? 0) + 1
    }
    
    func update(_ hotKeyConfig: HotKeyConfig) {
        self.globalSwitch = hotKeyConfig.globalSwitch
    }
    
    static func loadConfigFromFile() throws -> HotKeyConfig {
        let fileManager = FileManager.default

        // 1. App 支持路径
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

        // 2. App 专属子目录
        let logDirectory = baseURL.appendingPathComponent("simplevimac/data", isDirectory: true)

        // 3. 确保目录存在
        if !fileManager.fileExists(atPath: logDirectory.path) {
            try? fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        }
        
        let file = logDirectory.appendingPathComponent("hotkeyconfig.json")
        if !fileManager.fileExists(atPath: file.path) {
            if let bundleURL = Bundle.main.url(forResource: "hotkeyconfig", withExtension: "json") {
                try fileManager.copyItem(at: bundleURL, to: file)
            }
        }
        
        let data = try Data(contentsOf: file)

        let decoder = JSONDecoder()
        return try decoder.decode(HotKeyConfig.self, from: data)
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
    
    func saveToFile() {
        let fileManager = FileManager.default

        // 1. App 支持路径
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

        // 2. App 专属子目录
        let logDirectory = baseURL.appendingPathComponent("simplevimac/data", isDirectory: true)

        do {
            try fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true, attributes: nil)
            let fileURL = logDirectory.appendingPathComponent("hotkeyconfig.json")

            if let jsonString = try toJSONString(),
               let data = jsonString.data(using: .utf8) {
                try data.write(to: fileURL, options: [.atomic])
            } else {
                Log.debugLog("无法编码 JSON 字符串")
            }
        } catch {
            Log.debugLog("保存 JSON 到文件失败：\(error.localizedDescription)")
        }
    }
}
