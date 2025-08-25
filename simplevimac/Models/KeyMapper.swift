//
//  KeyMapper.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/6/30.
//
import Foundation
import CoreGraphics
import Carbon.HIToolbox

class KeyMapper {
    private var trieMap: [UInt64: Trie] = [:]

    class KeySpec: KeySpecBase, Identifiable {
        var id = UUID()
        var mouse: MouseAction?
        var command: Command?

        enum MouseAction: String, Codable, CaseIterable {
            case scrollUp
            case scrollDown
            case scrollToTop
            case scrollToBottom
            case mouseMoveToLeftTop
            case mouseMoveToLeftBottom
            case mouseMoveToRightTop
            case mouseMoveToRightBottom
        }
        
        enum Command :String, Codable, CaseIterable {
            case firstInputBox
            case showClickableElements
        }

        enum CodingKeys: String, CodingKey {
            case mouse
            case command
        }

        override init(keyCode: [CGKeyCode] = [], modifiers: CGEventFlags = []) {
            super.init(keyCode: keyCode, modifiers: modifiers)
        }

        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.mouse = try c.decodeIfPresent(MouseAction.self, forKey: .mouse)
            self.command = try c.decodeIfPresent(Command.self, forKey: .command)
            if self.keyCode.isEmpty && self.mouse == nil && self.command == nil {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath,
                                          debugDescription: "KeySpec must have at least a key or mouse action"))
            }
        }

        override func encode(to encoder: Encoder) throws {
            try super.encode(to: encoder)
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encodeIfPresent(mouse, forKey: .mouse)
            try c.encodeIfPresent(command, forKey: .command)
        }
    
    }

    class KeyBinding: Identifiable, Codable {
        var id = UUID()
        var iSwitch: Bool
        var trigger: KeySpec
        var action: KeySpec
        
        private enum CodingKeys: String, CodingKey {
            case iSwitch, trigger, action
        }
        
        init(iSwitch: Bool, trigger: KeySpec, action: KeySpec) {
            self.iSwitch = iSwitch
            self.trigger = trigger
            self.action = action
        }
    }
    
    class Trie {
        private class Node {
            var children: [CGKeyCode: Node] = [:]
            var value: KeyBinding? = nil
        }

        private var root: [CGKeyCode: Node] = [:]
        
        enum TrieSearchResult {
            case noMatch        // 中间某个路径不存在
            case matchedNoValue // 路径存在，但没有 value
            case matchedWithValue(KeyBinding)
        }

        // 插入一组 keyCode 映射到对应的 KeyBinding
        func insert(_ keyCodes: [CGKeyCode], value: KeyBinding) {
            guard let first = keyCodes.first else { return }

            if root[first] == nil {
                root[first] = Node()
            }

            var node = root[first]!
            for i in 1..<keyCodes.count {
                let code = keyCodes[i]
                if node.children[code] == nil {
                    node.children[code] = Node()
                }
                node = node.children[code]!
            }

            node.value = value
        }

        // 精确查找（完全匹配）
        func searchResult(_ keyCodes: [CGKeyCode]) -> TrieSearchResult {
            guard !keyCodes.isEmpty, var node = root[keyCodes[0]] else {
                return .noMatch
            }

            for i in 1..<keyCodes.count {
                guard let next = node.children[keyCodes[i]] else {
                    return .noMatch
                }
                node = next
            }

            if let value = node.value {
                return .matchedWithValue(value)
            } else {
                return .matchedNoValue
            }
        }
        
        func dumpTree() {
            func dumpNodeMap(_ nodeMap: [CGKeyCode: Node], path: [CGKeyCode]) {
                for (key, node) in nodeMap {
                    let newPath = path + [key]
                    if let value = node.value {
                        let triggerStr = newPath.map { KeySpec.keyCodeToChar($0) }.joined()
                        let actionKeys = value.action.keyCode.map { KeySpec.keyCodeToChar($0) }
                        let modNames = KeySpec.describeModifiers(value.action.modifiers).filter { !$0.isEmpty }
                        let actionStr = (modNames + actionKeys).joined(separator: "+")
                        
                        var components: [String] = []
                        components.append("Path: \(triggerStr)")
                        components.append("Action: \(actionStr)")
                        
                        if let mouse = value.action.mouse, !mouse.rawValue.isEmpty {
                            components.append("Mouse: \(mouse.rawValue)")
                        }
                        
                        Log.debugLog("🔑 " + components.joined(separator: " "))
                    } else {
                        let pathStr = newPath.map { KeySpec.keyCodeToChar($0) }.joined()
                        Log.debugLog("🔹 Path: \(pathStr) → [no value]")
                    }
                    dumpNodeMap(node.children, path: newPath)
                }
            }

            dumpNodeMap(root, path: [])
        }
        
    }
    
    struct KeyCombo: Hashable {
        let keyCode: [CGKeyCode]
        let modifiers: CGEventFlags?

        func hash(into hasher: inout Hasher) {
            hasher.combine(keyCode)
            hasher.combine(modifiers?.rawValue ?? 0)
        }

        static func == (lhs: KeyCombo, rhs: KeyCombo) -> Bool {
            return lhs.keyCode == rhs.keyCode &&
                   lhs.modifiers == rhs.modifiers
        }
    }
    
    static func toTrieMap(keyBindings: [KeyBinding], trieMap: inout [UInt64: Trie]) {
        for binding in keyBindings {
            if !binding.iSwitch {
                continue
            }
            let modifiers = binding.trigger.modifiers
            let modifierKey = modifiers.rawValue
            let keyCodes = binding.trigger.keyCode
            
            
            // 填充 trieMap（用于前缀匹配）
            if trieMap[modifierKey] == nil {
                trieMap[modifierKey] = Trie()
            }
            trieMap[modifierKey]?.insert(keyCodes, value: binding)
        }
    }
    
    static func match(trieMap: [UInt64: Trie], keyCodes: [CGKeyCode], flags: CGEventFlags) -> KeyMapper.Trie.TrieSearchResult? {
        return (trieMap[flags.rawValue]?.searchResult(keyCodes))
    }
    
    /// 按优先级合并多个 KeyBinding 列表，优先级高的在前，后面的不覆盖已有 key
    /// - Parameter lists: 按优先级排序的 KeyBinding 列表数组（优先级高的在前）
    /// - Returns: 合并后的 KeyBinding 列表，按优先级顺序，去重 combo
    static func mergeKeyBindingsWithPriority(_ lists: [[KeyMapper.KeyBinding]]) -> [KeyMapper.KeyBinding] {
        var seen: Set<KeyMapper.KeyCombo> = []
        var result: [KeyMapper.KeyBinding] = []

        for list in lists {
            for binding in list {
                let combo = KeyCombo(keyCode: binding.trigger.keyCode, modifiers: binding.trigger.modifiers)
                if !seen.contains(combo) {
                    seen.insert(combo)
                    result.append(binding)
                }
            }
        }

        return result
    }
}
