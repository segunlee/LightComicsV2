import ProjectDescription

// MARK: - TargetDependency.SPM

public extension TargetDependency {
  struct SPM {}
}

public extension TargetDependency.SPM {
  static let FileKit = TargetDependency.external(name: "FileKit")
  static let GRDB = TargetDependency.external(name: "GRDB")
  static let Lottie = TargetDependency.external(name: "Lottie")
  static let Swinject = TargetDependency.external(name: "Swinject")
}

public extension Package {}
