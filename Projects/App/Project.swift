import ConfigurationPlugin
import DependencyPlugin
import EnvironmentPlugin
import Foundation
import ProjectDescription
import ProjectDescriptionHelpers

let configurations: [Configuration] = .default

let settings: Settings = .settings(
  base: env.baseSetting,
  configurations: configurations,
  defaultSettings: .recommended
)

let scripts: [TargetScript] = generateEnvironment.scripts

let targets: [Target] = [
  .target(
    name: env.name,
    destinations: env.destinations,
    product: .app,
    bundleId: "SGIOS.SGComicViewer",
    deploymentTargets: env.deploymentTargets,
    infoPlist: .file(path: "Support/Info.plist"),
    sources: ["Sources/**"],
    resources: ["Resources/**"],
    scripts: scripts,
    dependencies: ModulePaths.Feature.allCases.map { TargetDependency.feature(target: $0) }
      + ModulePaths.Domain.allCases.map { TargetDependency.domain(target: $0) }
      + [
        .core(target: .ArchiveFileCore),
        .core(target: .DatabaseCore),
        .core(target: .FileSystemCore),
        .userInterface(target: .DesignSystem),
        .userInterface(target: .SharedUIComponents),
        .userInterface(target: .ThemeUI),
        .shared(target: .Logger),
        .SPM.Swinject
      ],
    settings: .settings(base: env.baseSetting)
  )
]

let schemes: [Scheme] = [
  .scheme(
    name: "\(env.name)-DEV",
    shared: true,
    buildAction: .buildAction(targets: ["\(env.name)"]),
    runAction: .runAction(configuration: .dev),
    archiveAction: .archiveAction(configuration: .dev),
    profileAction: .profileAction(configuration: .dev),
    analyzeAction: .analyzeAction(configuration: .dev)
  ),
  .scheme(
    name: "\(env.name)-PROD",
    shared: true,
    buildAction: .buildAction(targets: ["\(env.name)"]),
    runAction: .runAction(configuration: .prod),
    archiveAction: .archiveAction(configuration: .prod),
    profileAction: .profileAction(configuration: .prod),
    analyzeAction: .analyzeAction(configuration: .prod)
  )
]

let project = Project(
  name: env.name,
  organizationName: env.organizationName,
  options: env.baseOptions,
  settings: settings,
  targets: targets,
  schemes: schemes
)
