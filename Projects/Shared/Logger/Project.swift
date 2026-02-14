import DependencyPlugin
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
  name: ModulePaths.Shared.Logger.rawValue,
  targets: [
    .implements(module: .shared(.Logger), product: .framework)
  ]
)
