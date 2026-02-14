import DependencyPlugin
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
  name: ModulePaths.Core.ArchiveFileCore.rawValue,
  targets: [
    .interface(module: .core(.ArchiveFileCore), dependencies: []),
    .implements(module: .core(.ArchiveFileCore), dependencies: [
      .core(target: .ArchiveFileCore, type: .interface),
      .shared(target: .Logger),
      .xcframework(path: .relativeToRoot("Frameworks/libarchive.xcframework")),
      .sdk(name: "z", type: .library),
      .sdk(name: "bz2", type: .library),
      .sdk(name: "lzma", type: .library)
    ]),
    .tests(module: .core(.ArchiveFileCore), dependencies: [
      .core(target: .ArchiveFileCore)
    ])
  ]
)
