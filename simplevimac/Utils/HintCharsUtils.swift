//
//  HintCharsUtils.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/20.
//


class HintCharsUtils {
    // 生成提示字母（A, B, C...Z, AA, AB...）
    static func generateHintChars(count: Int) -> [String] {
        let letters = Array("ASDFGQWERZXCV")
        var result: [String] = []
        var idx = 0
        while result.count < count {
            var s = ""
            var n = idx
            repeat {
                s = String(letters[n % letters.count]) + s
                n = n / letters.count - 1
            } while n >= 0
            result.append(s)
            idx += 1
        }
        return result
    }
}
