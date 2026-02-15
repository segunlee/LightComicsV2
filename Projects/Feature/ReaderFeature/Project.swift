import DependencyPlugin
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
  name: ModulePaths.Feature.ReaderFeature.rawValue,
  targets: [
    .interface(module: .feature(.ReaderFeature), dependencies: []),
    .implements(module: .feature(.ReaderFeature), product: .framework, dependencies: [
      .feature(target: .ReaderFeature, type: .interface),
      .domain(target: .BookDomain, type: .interface),
      .core(target: .ArchiveFileCore, type: .interface),
      .userInterface(target: .SharedUIComponents),
      .shared(target: .Logger),
      .shared(target: .UserDefaultsService),
      .SPM.Swinject
    ], resources: .sourceResources),
    .demo(module: .feature(.ReaderFeature), dependencies: [
      .feature(target: .ReaderFeature),
      .domain(target: .BookDomain),
      .core(target: .ArchiveFileCore),
      .core(target: .DatabaseCore)
    ]),
    .tests(module: .feature(.ReaderFeature), dependencies: [
      .feature(target: .ReaderFeature)
    ])
  ]
)
