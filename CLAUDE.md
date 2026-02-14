# CLAUDE.md

## Project Overview

LightComics V2 — Swift 6 iOS comic/ebook viewer with Tuist microfeature architecture.

- Swift 6.0, strict concurrency, iOS 26.0+
- Tuist 4.x, UIKit + SwiftUI, MVVM + Coordinator
- Swinject DI, Combine bindings, GRDB (SQLite)
- Bundle ID: `SGIOS.SGComicViewer`

## Build Commands

```bash
tuist install              # Install SPM dependencies
make generate              # Generate Xcode project
make regenerate            # Clean + generate (use after file changes)
make reset                 # Deep clean (Tuist cache + generated)
make module                # Interactive module generator
make dependency            # Interactive dependency manager
open LightComics.xcworkspace
```

**Build/Test:** Use xclaude-plugin tools (see below). Fallback: `xcodebuild -workspace LightComics.xcworkspace -scheme LightComics-DEV`

**Lint:** SwiftLint runs on DEV builds. Config: `Scripts/.swiftlint.yml`. Manual: `cd Scripts && swiftlint`
**Format:** `swiftformat .` — 2-space indent, 120 char max, `// MARK:` sections

## Architecture

```
Projects/
├── App/                    # Main target + DI container
├── Feature/
│   ├── FinderFeature/      # File browser (Interface + Sources + Demo)
│   └── ReaderFeature/      # Comic/file reader (Interface + Sources + Demo)
├── Domain/
│   ├── FinderDomain/       # File operations domain
│   └── BookDomain/         # Reading progress/bookmark domain
├── Core/
│   ├── ArchiveFileCore/    # Archive extraction (ZIP/RAR/7z) — has Interface
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

**Microfeature pattern:** `Interface/` (optional) → `Sources/` → `Tests/` → `Demo/` (optional)

**Module types** in `Plugin/DependencyPlugin/ProjectDescriptionHelpers/ModulePaths.swift`:
`.feature()`, `.domain()`, `.core()`, `.shared()`, `.userInterface()`

**Target types** in `Tuist/ProjectDescriptionHelpers/Target/Target+MicroFeatures.swift`:
`.interface()`, `.implements()`, `.tests()`, `.demo()`

### DI Graph (AppDIContainer)

```
Core (direct registration, all via Interface protocol):
  ArchiveFileCoreInterface → ArchiveFileCore()
  FileSystemCoreInterface → FileSystemCore()
  DatabaseCoreInterface → DatabaseCore()
Domain (Assembly pattern):
  FinderDomainAssembly: FinderDomainInterface → FinderDomain(fileSystemCore:)
  BookDomainAssembly: BookDomainInterface → BookDomain(databaseCore:)
Feature (Assembly pattern):
  FinderFeatureAssembly: FinderFeatureFactory → FinderFeatureFactoryImpl(finderDomain:, readerFactory:)
  ReaderFeatureAssembly: ReaderFeatureFactory → ReaderFeatureFactoryImpl(bookDomain:, archiveCore:)
```

Assembly pattern: `public init() {}`, `public func assemble(container:)` in `Sources/Assembly/`.

### Build Configurations

- **DEV** (Debug) — SwiftLint enabled
- **PROD** (Release)
- Schemes: `LightComics-DEV`, `LightComics-PROD`
- Org: SGIOS, Team: P4BDJKG9NM

## Naming Conventions

See [NAMING_CONVENTION.md](./NAMING_CONVENTION.md) for complete rules.

| Layer | Interface Protocol | Implementation | Assembly |
|-------|-------------------|----------------|----------|
| Feature | `FinderFeatureFactory` | `FinderFeatureFactoryImpl` | `FinderFeatureAssembly` |
| Domain | `FinderDomainInterface` | `FinderDomain` | `FinderDomainAssembly` |
| Core | `FileSystemCoreInterface` | `FileSystemCore` | — |

## Code Style

### Formatting (SwiftFormat + SwiftLint)
- 2-space indent, 120 char max, LF line breaks
- Alphabetical imports
- `// MARK: - SectionName` for major sections, `// MARK: SectionName` for subsections
- Protocol conformances in separate extensions with `// MARK: - TypeName + ProtocolName`
- Prefer single-line calls under 120 chars; wrap `before-first` when exceeding

### Required MARK Sections
`Properties`, `Initialization`, `Lifecycle`, `ViewControllerLifecycle`, `Public Methods`, `Private Methods`, `Actions`

### Architecture Patterns
- MVVM + Coordinator, State/Action modeling in ViewModels
- UseCase layer between ViewModel and Domain
- Protocol-oriented design (Interface targets for abstractions)
- DI over singletons, Swift 6 strict concurrency (@MainActor, Sendable)
- ViewControllerLifecycle protocol: `setupUI()`, `setupBindings()`, `setupData()` in `viewDidLoad`

### Extension Patterns
- Split ViewController by feature: `VC+Alerts.swift`, `VC+Menu.swift`, `VC+TableView.swift`
- Use Associated Objects for extension-specific state (avoid modifying main class)
- Each extension file: complete feature ownership (handlers + protocol conformances + state + helpers)
- Each extension file: import all required frameworks
- Extract reusable UI logic into `Sources/Scene/Components/`

### UIMenu Structure
Group actions with `UIMenu(title: "", options: .displayInline, children: [...])` for visual separation.

## File Locations

- Tuist plugins: `Plugin/`
- Tuist helpers: `Tuist/ProjectDescriptionHelpers/`
- Module projects: `Projects/<Layer>/<ModuleName>/Project.swift`
- Scripts: `Scripts/`
- SPM deps: `Tuist/Package.swift`, add via `Plugin/DependencyPlugin/ProjectDescriptionHelpers/Dependency+SPM.swift`

## Important Rules

- **Always `make regenerate`** after creating/moving/deleting files
- For new modules not picked up: use `make reset && make generate`
- LSP errors expected until project is generated
- Do not over-engineer. Minimal correct approach first
- UseCase를 직접 주입할 수 있으면 wrapper/orchestrator 클래스를 만들지 않는다 (예: try/catch + 로깅만 감싸는 중간 클래스 금지)
- "나중에 확장될 수 있으니" 같은 가정으로 레이어를 추가하지 않는다. 실제 필요할 때 추가한다
- Keep module boundaries strict — no feature code in shared modules
- When unsure which module a file belongs in, ask

## XClaude Plugin

**Use xclaude-plugin tools for all build/test/simulator operations. Never use raw xcodebuild/simctl.**

**Defaults:**
```yaml
scheme: LightComics-DEV
destination: platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2
configuration: DEV
```

**Skills:** `xclaude-plugin:xcode-workflows`, `xclaude-plugin:ios-testing-patterns`, `xclaude-plugin:simulator-workflows`, `xclaude-plugin:ui-automation-workflows`, `xclaude-plugin:accessibility-testing`, `xclaude-plugin:crash-debugging`, `xclaude-plugin:performance-profiling`

**Accessibility-first automation:** Always `idb_check_quality` before screenshots. If rich/moderate → use `idb_describe`/`idb_find_element`/`idb_tap`. Screenshot only as last resort or final verification.
