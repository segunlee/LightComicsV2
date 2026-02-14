//
//  LoggerInterface.swift
//  Logger
//
//  Created by SGIOS on 1/29/26.
//  Copyright © 2026 SGIOS. All rights reserved.
//

// MARK: - Destination

/// 로거 도착지
public enum Destination {
  /// 콘솔 로그
  case osLog
}

// MARK: - LoggerInterface

/// 로거
public protocol LoggerInterface {
  /// 디버그 메시지
  /// - Parameters:
  ///   - message: 메시지
  ///   - arguments: 인자값
  ///   - file: File
  ///   - line: Line
  ///   - function: Function
  static func debug(_ message: Any, _ arguments: Any..., file: String, _ line: Int, _ function: String)

  /// 정보 메시지
  /// - Parameters:
  ///   - message: 메시지
  ///   - arguments: 인자값
  ///   - file: File
  ///   - line: Line
  ///   - function: Function
  static func info(_ message: Any, _ arguments: Any..., file: String, _ line: Int, _ function: String)

  /// 네트워크 메시지
  /// - Parameters:
  ///   - message: 메시지
  ///   - arguments: 인자값
  ///   - file: File
  ///   - line: Line
  ///   - function: Function
  static func network(_ message: Any, _ arguments: Any..., file: String, _ line: Int, _ function: String)

  /// 에러 메시지
  /// - Parameters:
  ///   - message: 에러
  ///   - arguments: 인자값
  ///   - file: File
  ///   - line: Line
  ///   - function: Function
  static func error(_ message: Any, _ arguments: Any..., file: String, _ line: Int, _ function: String)

  /// 커스텀 메시지
  /// - Parameters:
  ///   - category: 커스텀 카테고리
  ///   - message: 메시지
  ///   - arguments: 인자값
  ///   - file: File
  ///   - line: Line
  ///   - function: Function
  static func custom(category: String, _ message: Any, _ arguments: Any..., file: String, _ line: Int, _ function: String)
}

public extension LoggerInterface {
  static func debug(_ message: Any, _ arguments: Any..., file: String = #file, _ line: Int = #line, _ function: String = #function) {
    debug(message, arguments, file: file, line, function)
  }

  static func info(_ message: Any, _ arguments: Any..., file: String = #file, _ line: Int = #line, _ function: String = #function) {
    info(message, arguments, file: file, line, function)
  }

  static func network(_ message: Any, _ arguments: Any..., file: String = #file, _ line: Int = #line, _ function: String = #function) {
    network(message, arguments, file: file, line, function)
  }

  static func error(_ message: Any, _ arguments: Any..., file: String = #file, _ line: Int = #line, _ function: String = #function) {
    error(message, arguments, file: file, line, function)
  }

  static func custom(category: String, _ message: Any, _ arguments: Any..., file: String = #file, _ line: Int = #line, _ function: String = #function) {
    custom(category: category, message, arguments, file: file, line, function)
  }
}
