//
//  Logger.swift
//  UIDemo
//
//  Created by Arturo Aguilar on 7/18/25.
//


import Foundation

enum LogLevel: String {
    case debug = "🐛"
    case info = "ℹ️"
    case warning = "⚠️"
    case error = "🚨"
}

struct Logger {
    static var isEnabled: Bool = {
#if DEBUG
        return true
#else
        return false
#endif
    }()
    
    static func log(level: LogLevel = .debug,
                    tag: String? = nil,
                    _ message: @autoclosure () -> String,
                    file: String = #file,
                    function: String = #function,
                    line: Int = #line) {
        guard isEnabled else { return }
        
        let fileName = (file as NSString).lastPathComponent
        let tagString = tag.map { "[\($0)]" } ?? ""
        print("\(level.rawValue) \(tagString) [\(fileName):\(line)] \(function) — \(message())")
    }
}
