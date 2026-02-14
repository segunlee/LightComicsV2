import DependencyPlugin
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
  name: ModulePaths.Domain.BookDomain.rawValue,
  targets: [
    .interface(module: .domain(.BookDomain), dependencies: []),
    .implements(module: .domain(.BookDomain), dependencies: [
      .domain(target: .BookDomain, type: .interface),
      .core(target: .DatabaseCore),
      .shared(target: .Logger),
      .SPM.GRDB,
      .SPM.Swinject
    ]),
    .tests(module: .domain(.BookDomain), dependencies: [
      .domain(target: .BookDomain),
      .core(target: .DatabaseCore),
      .SPM.GRDB
    ])
  ]
)
