//
//  HotKeyID.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/12.
//
import Carbon.HIToolbox

class HotKeyID: Codable, Hashable {
    var signature: UInt32
    var id: UInt32

    init(_ eventHotKeyID: EventHotKeyID) {
        self.signature = eventHotKeyID.signature
        self.id = eventHotKeyID.id
    }

    static func == (lhs: HotKeyID, rhs: HotKeyID) -> Bool {
        return lhs.signature == rhs.signature && lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(signature)
        hasher.combine(id)
    }
    
    func toEventHotKeyID() -> EventHotKeyID{
        return EventHotKeyID(signature: signature, id: id)
    }
}
