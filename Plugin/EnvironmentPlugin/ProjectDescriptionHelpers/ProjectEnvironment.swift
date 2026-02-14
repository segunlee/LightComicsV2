import Foundation
import ProjectDescription

// MARK: - Version

enum Version {
  static let projectVersion = "1.0.0"
  static let bundleVersion = "1"
}

// MARK: - ProjectEnvironment

public struct ProjectEnvironment {
  public let name: String
  public let organizationName: String
  public let destinations: Destinations
  public let deploymentTargets: DeploymentTargets
  public let baseSetting: SettingsDictionary
  public let baseOptions: ProjectDescription.Project.Options
}

public let env = ProjectEnvironment(
  name: "LightComics",
  organizationName: "SGIOS",
  destinations: [.iPhone, .iPad],
  deploymentTargets: .iOS("26.0"),
  baseSetting: [
    "CURRENT_PROJECT_VERSION": "\(Version.projectVersion)",
    "MARKETING_VERSION": "\(Version.projectVersion)",
    "CODE_SIGN_IDENTITY[config=DEV]": "Apple Development",
    "DEVELOPMENT_TEAM": "P4BDJKG9NM",
    "CODE_SIGN_IDENTITY[config=PROD]": "Apple Development",
    "SWIFT_VERSION": "6.0",
    "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
    "TARGETED_DEVICE_FAMILY": "1,2",
    "SUPPORTS_MACCATALYST": false,
    "ENABLE_USER_SCRIPT_SANDBOXING": false,
    "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS": true,
    "CODE_SIGN_STYLE": "Automatic",
    "PROVISIONING_PROFILE_SPECIFIER": ""
  ],
  baseOptions: .options(
    automaticSchemesOptions: .disabled,
    developmentRegion: "en",
    textSettings: .textSettings(usesTabs: false, indentWidth: 2, tabWidth: 2)
  )
)
