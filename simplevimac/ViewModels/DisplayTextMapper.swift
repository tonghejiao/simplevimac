//
//  DisplayTextMapper.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/12.
//

class DisplayTextMapper {
    static func label(_ mode: Config.ModeType) -> String {
        switch mode {
            case .disable: return "关闭"
            case .globallyEffective: return "全局生效"
            case .whiteListEffective: return "白名单生效"
        }
    }
    
    static func label(_ level: Config.BlacklistLevel) -> String {
        switch level {
        case .global: return "全局"
        case .app: return "应用"
        }
    }
    
    static func label(_ mode: Config.WindowLevelGroup.ModeType) -> String {
        switch mode {
        case .title: return "标题"
        case .url: return "网址"
        }
    }
}
