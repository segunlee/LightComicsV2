//
//  ConsoleLogger.swift
//  Logger
//
//  Created by SGIOS on 1/29/26.
//  Copyright © 2026 SGIOS. All rights reserved.
//

import OSLog

// MARK: - ConsoleLogger

/// OS 로그 시스템 (Xcode Console & Console.app)
enum ConsoleLogger {
  enum Level {
    case debug
    case info
    case network
    case error
    case custom(categoryName: String)

    fileprivate var category: String {
      switch self {
      case .debug:
        return "Debug"
      case .info:
        return "Info"
      case .network:
        return "Network"
      case .error:
        return "Error"
      case .custom(let categoryName):
        return categoryName
      }
    }
  }

  /// Logging
  /// - Parameters:
  ///   - message: message
  ///   - arguments: arguments
  ///   - level: level
  private static func log(_ message: Any, _ arguments: [Any], file: String, _ line: Int, _ function: String, level: Level) { // swiftlint:disable:this function_parameter_count
    let extraMessage: String = arguments.map { String(describing: $0) }.joined(separator: " ")
    let logger = os.Logger(subsystem: OSLog.subsystem, category: level.category)
    let logMessage = "\(file.components(separatedBy: "/").last ?? ""):\(line) ▶ \(function)\n\(message) \(extraMessage)"
    switch level {
    case .debug, .custom:
      logger.debug("\(logMessage, privacy: .public)")
    case .info:
      logger.info("\(logMessage, privacy: .public)")
    case .network:
      logger.log("\(logMessage, privacy: .public)")
    case .error:
      logger.error("\(logMessage, privacy: .public)")
    }
  }
}

// MARK: LoggerInterface

extension ConsoleLogger: LoggerInterface {
  static func debug(_ message: Any, _ arguments: Any..., file: String = #file, _ line: Int = #line, _ function: String = #function) {
    log(message, arguments, file: file, line, function, level: .debug)
  }

  static func info(_ message: Any, _ arguments: Any..., file: String = #file, _ line: Int = #line, _ function: String = #function) {
    log(message, arguments, file: file, line, function, level: .info)
  }

  static func network(_ message: Any, _ arguments: Any..., file: String = #file, _ line: Int = #line, _ function: String = #function) {
    log(message, arguments, file: file, line, function, level: .network)
  }

  static func error(_ message: Any, _ arguments: Any..., file: String = #file, _ line: Int = #line, _ function: String = #function) {
    log(message, arguments, file: file, line, function, level: .error)
  }

  static func custom(category: String, _ message: Any, _ arguments: Any..., file: String = #file, _ line: Int = #line, _ function: String = #function) {
    log(message, arguments, file: file, line, function, level: .custom(categoryName: category))
  }
}

// MARK: - For OSLog

extension OSLog {
  static let subsystem = Bundle.main.bundleIdentifier ?? "SGIOS.SGComicViewer"
  static let network = OSLog(subsystem: subsystem, category: "Network")
  static let debug = OSLog(subsystem: subsystem, category: "Debug")
  static let info = OSLog(subsystem: subsystem, category: "Info")
  static let error = OSLog(subsystem: subsystem, category: "Error")
}
