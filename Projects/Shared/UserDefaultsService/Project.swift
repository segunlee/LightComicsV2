import DependencyPlugin
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
  name: ModulePaths.Shared.UserDefaultsService.rawValue,
  targets: [
    .implements(module: .shared(.UserDefaultsService), product: .framework, dependencies: []),
    .tests(module: .shared(.UserDefaultsService), dependencies: [
      .shared(target: .UserDefaultsService)
    ])
  ]
)
