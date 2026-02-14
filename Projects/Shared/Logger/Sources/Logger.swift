//
//  Logger.swift
//  Logger
//
//  Created by SGIOS on 1/29/26.
//  Copyright © 2026 SGIOS. All rights reserved.
//

import Foundation

/// 사용하기 쉽게 축약한 로그
public typealias Log = Logger

// MARK: - Logger

/// 통합 로거
public class Logger: LoggerInterface {
  public nonisolated(unsafe) static let shared = Logger()

  /// 인터페이스에 받은 로거 도착지들
  private var destinations: [Destination] = [.osLog]

  /// 로거 도착지들을 실제 각 모듈로 변환시켜 반환
  private var loggers: [LoggerInterface.Type] {
    return destinations.compactMap { destination in
      switch destination {
      case .osLog:
        ConsoleLogger.self
      }
    }
  }

  public init() {}

  public static func setDestinations(_ destinations: [Destination]) {
    Logger.shared.destinations = destinations
  }

  public static func debug(_ message: Any, _ arguments: Any..., file: String, _ line: Int, _ function: String) {
    Logger.shared.loggers.forEach { $0.debug(message, arguments, file: file, line, function) }
  }

  public static func info(_ message: Any, _ arguments: Any..., file: String, _ line: Int, _ function: String) {
    Logger.shared.loggers.forEach { $0.info(message, arguments, file: file, line, function) }
  }

  public static func network(_ message: Any, _ arguments: Any..., file: String, _ line: Int, _ function: String) {
    Logger.shared.loggers.forEach { $0.network(message, arguments, file: file, line, function) }
  }

  public static func error(_ message: Any, _ arguments: Any..., file: String, _ line: Int, _ function: String) {
    Logger.shared.loggers.forEach { $0.error(message, arguments, file: file, line, function) }
  }

  public static func custom(category: String, _ message: Any, _ arguments: Any..., file: String, _ line: Int, _ function: String) {
    Logger.shared.loggers.forEach { $0.custom(category: category, message, arguments, file: file, line, function) }
  }
}
