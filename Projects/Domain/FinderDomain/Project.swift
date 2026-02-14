import DependencyPlugin
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
  name: ModulePaths.Domain.FinderDomain.rawValue,
  targets: [
    .interface(module: .domain(.FinderDomain), dependencies: [
    ]),
    .implements(module: .domain(.FinderDomain), dependencies: [
      .domain(target: .FinderDomain, type: .interface),
      .core(target: .FileSystemCore, type: .interface),
      .shared(target: .Logger),
      .SPM.Swinject
    ]),
    .tests(module: .domain(.FinderDomain), dependencies: [
      .domain(target: .FinderDomain)
    ])
  ]
)
