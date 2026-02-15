import ProjectDescription

public extension TargetScript {
  static let swiftLint = TargetScript.pre(
    path: Path.relativeToRoot("Scripts/SwiftLintRunScript.sh"),
    name: "SwiftLint",
    basedOnDependencyAnalysis: false
  )

  static let swiftFormat = TargetScript.pre(
    path: Path.relativeToRoot("Scripts/SwiftFormatRunScript.sh"),
    name: "SwiftFormat",
    basedOnDependencyAnalysis: false
  )

  static let generateStrings = TargetScript.pre(
    path: Path.relativeToRoot("Scripts/GenerateStringsRunScript.sh"),
    name: "Generate Strings",
    basedOnDependencyAnalysis: false
  )
}
