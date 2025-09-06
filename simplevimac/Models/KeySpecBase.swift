//
//  KeySpecBase.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/12.
//

import CoreGraphics

class KeySpecBase: Codable {
    var keyCode: [CGKeyCode]
    var modifiers: CGEventFlags

    enum CodingKeys: String, CodingKey {
        case key
        case modifiers
    }

    init(keyCode: [CGKeyCode] = [], modifiers: CGEventFlags = []) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        var keyCode: [CGKeyCode] = []
        if let str = try c.decodeIfPresent([String].self, forKey: .key) {
            for char in str {
                guard let code = Self.keyCodeMap[char.lowercased()] else {
                    throw DecodingError.dataCorruptedError(forKey: .key, in: c,
                        debugDescription: "Invalid key: \(char)")
                }
                keyCode.append(code)
            }
        }
        self.keyCode = keyCode
        let modifiers = try c.decodeIfPresent([String].self, forKey: .modifiers) ?? []
        self.modifiers = Self.parseModifiers(modifiers)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        var str: [String] = []
        for keyCodeItem in keyCode {
            let char = Self.keyCodeToChar(keyCodeItem)
            str.append(char)
        }
        if !str.isEmpty {
            try c.encode(str, forKey: .key)
        }
        let modifiers = Self.describeModifiers(modifiers)
        if !modifiers.isEmpty {
            try c.encode(modifiers, forKey: .modifiers)
        }
    }
    
    
    func keyCodeString() -> String {
        return Self.keyCodeToString(keyCode)
    }
    
    static func keyCodeToString(_ keyCode: [CGKeyCode]) -> String{
        keyCode.compactMap { Self.keyCodeToChar($0) }.joined()
    }

    static func parseModifiers(_ names: [String]) -> CGEventFlags {
        var flags = CGEventFlags()
        for name in names {
            switch name.lowercased() {
            case "command", "cmd": flags.insert(.maskCommand)
            case "control", "ctrl": flags.insert(.maskControl)
            case "shift": flags.insert(.maskShift)
            case "option", "alt", "opt": flags.insert(.maskAlternate)
            case "fn": flags.insert(.maskSecondaryFn)
            case "caps": flags.insert(.maskAlphaShift)
            default: break
            }
        }
        return flags
    }

    static func describeModifiers(_ flags: CGEventFlags) -> [String] {
        var names: [String] = []
        if flags.contains(.maskCommand) { names.append("cmd") }
        if flags.contains(.maskControl) { names.append("ctrl") }
        if flags.contains(.maskAlternate) { names.append("opt") }
        if flags.contains(.maskShift) { names.append("shift") }
        if flags.contains(.maskSecondaryFn) { names.append("fn") }
        if flags.contains(.maskAlphaShift) { names.append("caps") }
        return names
    }
    
    static func keyCodeToChar(_ code: CGKeyCode) -> String {
        return reverseMap[code] ?? ""
    }
    
    static let keyCodeMap: [String: CGKeyCode] = [
        "a": 0,   "s": 1,   "d": 2,   "f": 3,   "h": 4,   "g": 5,   "z": 6,   "x": 7,   "c": 8,   "v": 9,
        "b": 11,  "q": 12,  "w": 13,  "e": 14,  "r": 15,  "y": 16,  "t": 17,  "1": 18,  "2": 19,  "3": 20,
        "4": 21,  "6": 22,  "5": 23,  "=": 24,  "9": 25,  "7": 26,  "-": 27,  "8": 28,  "0": 29,  "]": 30,
        "o": 31,  "u": 32,  "[": 33,  "i": 34,  "p": 35,  "enter": 36, "l": 37,  "j": 38,  "'": 39,  "k": 40,
        ";": 41,  "\\": 42, ",": 43,  "/": 44,  "n": 45,  "m": 46,  ".": 47,  "tab": 48, " ": 49,  "`": 50,
        "back": 51, "esc": 53, "f5": 96,  "f6": 97,  "f7": 98,  "f3": 99,  "f8": 100, "f9": 101, "f11": 103, "f10": 109,
        "f12": 111, "del": 117, "f4": 118, "f2": 120, "f1": 122, "left": 123, "right": 124, "down": 125, "up": 126
    ]
    
    // 反向映射表
    static var reverseMap: [CGKeyCode: String] = Dictionary(uniqueKeysWithValues: keyCodeMap.map { ($1, $0) })
}
