import DependencyPlugin
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
  name: ModulePaths.Core.FileSystemCore.rawValue,
  targets: [
    .interface(module: .core(.FileSystemCore), dependencies: []),
    .implements(module: .core(.FileSystemCore), dependencies: [
      .core(target: .FileSystemCore, type: .interface),
      .shared(target: .Logger),
      .SPM.FileKit
    ]),
    .tests(module: .core(.FileSystemCore), dependencies: [
      .core(target: .FileSystemCore)
    ])
  ]
)
