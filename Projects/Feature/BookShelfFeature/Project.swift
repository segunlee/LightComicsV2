import DependencyPlugin
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
  name: ModulePaths.Feature.BookShelfFeature.rawValue,
  targets: [
    .interface(module: .feature(.BookShelfFeature), dependencies: []),
    .implements(module: .feature(.BookShelfFeature), product: .framework, dependencies: [
      .feature(target: .BookShelfFeature, type: .interface),
      .feature(target: .ReaderFeature, type: .interface),
      .domain(target: .BookDomain, type: .interface),
      .core(target: .ArchiveFileCore, type: .interface),
      .userInterface(target: .SharedUIComponents),
      .shared(target: .Logger),
      .SPM.Swinject
    ])
  ]
)
