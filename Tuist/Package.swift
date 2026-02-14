// swift-tools-version: 6.0
import PackageDescription

#if TUIST
  import struct ProjectDescription.PackageSettings
  import ProjectDescriptionHelpers

  let packageSetting = PackageSettings(
    productTypes: [
      "FileKit": .framework,
      "GRDB": .framework,
      "Swinject": .framework
    ],
    baseSettings: .settings(
      configurations: [
        .debug(name: .dev),
        .release(name: .prod)
      ]
    )
  )
#endif

let package = Package(
  name: "LightComics",
  dependencies: [
    .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.5.0"),
    .package(url: "https://github.com/nvzqz/FileKit.git", from: "6.0.0"),
    .package(url: "https://github.com/Swinject/Swinject.git", from: "2.8.0")
  ]
)
