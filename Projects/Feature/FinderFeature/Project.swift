import DependencyPlugin
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
  name: ModulePaths.Feature.FinderFeature.rawValue,
  targets: [
    .interface(module: .feature(.FinderFeature), dependencies: []),
    .implements(module: .feature(.FinderFeature), product: .framework, dependencies: [
      .feature(target: .FinderFeature, type: .interface),
      .feature(target: .ReaderFeature, type: .interface),
      .domain(target: .FinderDomain, type: .interface),
      .userInterface(target: .SharedUIComponents),
      .shared(target: .Logger),
      .shared(target: .UserDefaultsService),
      .SPM.Swinject
    ]),
    .demo(module: .feature(.FinderFeature), dependencies: [
      .feature(target: .FinderFeature),
      .domain(target: .FinderDomain)
    ]),
    .tests(module: .feature(.FinderFeature), dependencies: [
      .feature(target: .FinderFeature)
    ])
  ]
)
