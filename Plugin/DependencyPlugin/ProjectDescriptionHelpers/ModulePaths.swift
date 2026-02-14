import Foundation

// MARK: - ModulePaths

public enum ModulePaths {
  case feature(Feature)
  case domain(Domain)
  case core(Core)
  case shared(Shared)
  case userInterface(UserInterface)
}

// MARK: MicroTargetPathConvertable

extension ModulePaths: MicroTargetPathConvertable {
  public func targetName(type: MicroTargetType) -> String {
    switch self {
    case let .feature(module as any MicroTargetPathConvertable),
         let .domain(module as any MicroTargetPathConvertable),
         let .core(module as any MicroTargetPathConvertable),
         let .shared(module as any MicroTargetPathConvertable),
         let .userInterface(module as any MicroTargetPathConvertable):
      return module.targetName(type: type)
    }
  }
}

// MARK: ModulePaths.Feature

public extension ModulePaths {
  enum Feature: String, MicroTargetPathConvertable {
    case FinderFeature
    case ReaderFeature
  }
}

// MARK: ModulePaths.Domain

public extension ModulePaths {
  enum Domain: String, MicroTargetPathConvertable {
    case BookDomain
    case FinderDomain
  }
}

// MARK: ModulePaths.Core

public extension ModulePaths {
  enum Core: String, MicroTargetPathConvertable {
    case ArchiveFileCore
    case DatabaseCore
    case FileSystemCore
  }
}

// MARK: ModulePaths.Shared

public extension ModulePaths {
  enum Shared: String, MicroTargetPathConvertable {
    case Logger
    case UserDefaultsService
  }
}

// MARK: ModulePaths.UserInterface

public extension ModulePaths {
  enum UserInterface: String, MicroTargetPathConvertable {
    case DesignSystem
    case SharedUIComponents
    case ThemeUI
  }
}

// MARK: - MicroTargetType

public enum MicroTargetType: String {
  case interface = "Interface"
  case sources = ""
  case testing = "Testing"
  case unitTest = "Tests"
  case demo = "Demo"
}

// MARK: - MicroTargetPathConvertable

public protocol MicroTargetPathConvertable {
  func targetName(type: MicroTargetType) -> String
}

public extension MicroTargetPathConvertable where Self: RawRepresentable {
  func targetName(type: MicroTargetType) -> String {
    "\(rawValue)\(type.rawValue)"
  }
}

// MARK: - ModulePaths.Domain + CaseIterable

extension ModulePaths.Domain: CaseIterable {}

// MARK: - ModulePaths.Feature + CaseIterable

extension ModulePaths.Feature: CaseIterable {}

// MARK: - ModulePaths.Core + CaseIterable

extension ModulePaths.Core: CaseIterable {}

// MARK: - ModulePaths.Shared + CaseIterable

extension ModulePaths.Shared: CaseIterable {}

// MARK: - ModulePaths.UserInterface + CaseIterable

extension ModulePaths.UserInterface: CaseIterable {}
