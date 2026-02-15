import DependencyPlugin
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
  name: ModulePaths.UserInterface.SharedUIComponents.rawValue,
  targets: [
    .implements(module: .userInterface(.SharedUIComponents), product: .framework, dependencies: [
      .userInterface(target: .DesignSystem),
      .SPM.Lottie
    ], resources: .sourceResources)
  ]
)
