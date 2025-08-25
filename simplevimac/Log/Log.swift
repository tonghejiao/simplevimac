//
//  Log.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/7/4.
//
import ApplicationServices

class Log {
    static func debugLog(_ message: String) {
        print(message)
//        let fileManager = FileManager.default
//
//        // 1. App 支持路径
//        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
//
//        // 2. App 专属子目录
//        let logDirectory = baseURL.appendingPathComponent("simplevimac/logs", isDirectory: true)
//
//        // 3. 确保目录存在
//        if !fileManager.fileExists(atPath: logDirectory.path) {
//            try? fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true)
//        }
//
//        // 4. 写入日志文件
//        let logFile = logDirectory.appendingPathComponent("myapp_log.txt")
//
//        let timestamp = ISO8601DateFormatter().string(from: Date())
//        let fullMessage = "[\(timestamp)] \(message)\n"
//
//        if let handle = try? FileHandle(forWritingTo: logFile) {
//            handle.seekToEndOfFile()
//            handle.write(Data(fullMessage.utf8))
//            handle.closeFile()
//        } else {
//            try? fullMessage.write(to: logFile, atomically: true, encoding: .utf8)
//        }
    }
}
