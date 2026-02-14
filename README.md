# LightComics V2

Swift 6 iOS comic/ebook viewer built with Tuist microfeature architecture.

## Tech Stack

- **Swift 6.0** with strict concurrency checking
- **iOS 26.0+** deployment target
- **Tuist 4.x** for project generation
- **UIKit + SwiftUI** hybrid UI
- **MVVM + Coordinator** for feature flows
- **Swinject** for dependency injection
- **Combine** for reactive bindings
- **GRDB** for SQLite database

## Quick Start

```bash
# Install dependencies
tuist install

# Generate Xcode project
make generate

# Open workspace
open LightComics.xcworkspace

# Build: select LightComics-DEV scheme in Xcode
```

### Other Commands

```bash
make regenerate   # Clean + regenerate (use after file changes)
make reset        # Deep clean (Tuist cache + generated files)
make module       # Interactive module generator
make dependency   # Interactive dependency manager
```

## Architecture

```
Projects/
├── App/                    # Main target + DI container
├── Feature/
│   ├── FinderFeature/      # File browser
│   └── ReaderFeature/      # Comic/file reader
├── Domain/
│   ├── FinderDomain/       # File operations
│   └── BookDomain/         # Reading progress/bookmarks
├── Core/
│   ├── ArchiveFileCore/    # Archive extraction (ZIP/RAR/7z)
│   ├── DatabaseCore/       # SQLite via GRDB
│   └── FileSystemCore/     # File system operations
├── UserInterface/
│   ├── DesignSystem/
│   ├── SharedUIComponents/ # ViewControllerLifecycle, Toast
│   └── ThemeUI/
└── Shared/
    ├── Logger/
    └── UserDefaultsService/
```

Each module follows the microfeature pattern: `Interface/` (optional), `Sources/`, `Tests/`, `Demo/` (optional).

## DI Graph

```
App (AppDIContainer)
├── Core (direct registration, all via Interface protocol)
│   ├── ArchiveFileCoreInterface → ArchiveFileCore
│   ├── FileSystemCoreInterface → FileSystemCore
│   └── DatabaseCoreInterface → DatabaseCore
├── Domain (Assembly pattern)
│   ├── FinderDomainInterface → FinderDomain(fileSystemCore:)
│   └── BookDomainInterface → BookDomain(databaseCore:)
└── Feature (Assembly pattern)
    ├── FinderFeatureFactory → FinderFeatureFactoryImpl(finderDomain:, readerFactory:)
    └── ReaderFeatureFactory → ReaderFeatureFactoryImpl(bookDomain:, archiveCore:)
```

## Naming Conventions

See [NAMING_CONVENTION.md](./NAMING_CONVENTION.md) for complete rules.

| Layer | Interface | Implementation |
|-------|-----------|----------------|
| Feature | `FinderFeatureFactory` | `FinderFeatureFactoryImpl` |
| Domain | `FinderDomainInterface` | `FinderDomain` |
| Core | `FileSystemCoreInterface` | `FileSystemCore` |

## Code Style

- **SwiftFormat**: 2-space indent, 120 char max width, `// MARK:` sections
- **SwiftLint**: `Scripts/.swiftlint.yml`, runs on DEV builds
- **Configs**: DEV (Debug) / PROD (Release)

## Build Info

- Bundle ID: `SGIOS.SGComicViewer`
- Organization: SGIOS
- Team: P4BDJKG9NM
