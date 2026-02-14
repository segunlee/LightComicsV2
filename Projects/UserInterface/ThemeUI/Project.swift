import DependencyPlugin
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
  name: ModulePaths.UserInterface.ThemeUI.rawValue,
  targets: [
    .implements(module: .userInterface(.ThemeUI), product: .framework, dependencies: [
      .userInterface(target: .DesignSystem)
    ])
  ]
)
