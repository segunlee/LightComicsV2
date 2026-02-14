import ConfigurationPlugin
import EnvironmentPlugin
import Foundation
import ProjectDescription

public extension Project {
  static func module(
    name: String,
    options: Options = env.baseOptions,
    packages: [Package] = [],
    settings: Settings = .settings(configurations: .default),
    targets: [Target],
    fileHeaderTemplate: FileHeaderTemplate? = nil,
    additionalFiles: [FileElement] = [],
    resourceSynthesizers: [ResourceSynthesizer] = .default
  ) -> Project {
    let hasTests = targets.contains { $0.name == "\(name)Tests" }
    return Project(
      name: name,
      organizationName: env.organizationName,
      options: options,
      packages: packages,
      settings: settings,
      targets: targets,
      schemes: targets.contains { $0.product == .app } ?
        [
          .makeScheme(target: .dev, name: name, includeTests: hasTests),
          .makeDemoScheme(target: .dev, name: name, includeTests: hasTests)
        ] :
        [.makeScheme(target: .dev, name: name, includeTests: hasTests)],
      fileHeaderTemplate: fileHeaderTemplate,
      additionalFiles: additionalFiles,
      resourceSynthesizers: resourceSynthesizers
    )
  }
}
