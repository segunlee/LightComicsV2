import DependencyPlugin
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
  name: ModulePaths.Core.DatabaseCore.rawValue,
  targets: [
    .interface(module: .core(.DatabaseCore), dependencies: [
      .SPM.GRDB
    ]),
    .implements(module: .core(.DatabaseCore), dependencies: [
      .core(target: .DatabaseCore, type: .interface),
      .shared(target: .Logger),
      .SPM.GRDB
    ]),
    .tests(module: .core(.DatabaseCore), dependencies: [
      .core(target: .DatabaseCore),
      .SPM.GRDB
    ])
  ]
)
