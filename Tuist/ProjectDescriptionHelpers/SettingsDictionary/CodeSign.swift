import ProjectDescription

public extension SettingsDictionary {
  static let codeSign: SettingsDictionary = [
    "CODE_SIGN_STYLE": "Automatic",
    "DEVELOPMENT_TEAM": "P4BDJKG9NM"
  ]

  static let ldFlages: SettingsDictionary = [
    "OTHER_LDFLAGS": "$(inherited)"
  ]

  static let allLoadLDFlages: SettingsDictionary = [
    "OTHER_LDFLAGS": "$(inherited) -all_load"
  ]
}
