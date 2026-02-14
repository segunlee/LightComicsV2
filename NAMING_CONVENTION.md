# Naming Convention

This document defines the naming conventions for LightComics V2 modules.

## Feature Modules

Feature modules expose a **Factory** interface for creating view controllers.

### Structure
```
Projects/Feature/<FeatureName>/
├── Interface/
│   └── <FeatureName>Factory.swift       ← Public factory protocol
└── Sources/
    ├── Assembly/
    │   └── <FeatureName>Assembly.swift   ← DI assembly
    └── Factory/
        └── <FeatureName>FactoryImpl.swift ← Factory implementation
```

### Naming Rules

| Item | Pattern | Example |
|------|---------|---------|
| **Module name** | `<BaseName>Feature` | `FinderFeature` |
| **Interface file** | `<BaseName>FeatureFactory.swift` | `FinderFeatureFactory.swift` |
| **Interface protocol** | `<BaseName>FeatureFactory` | `protocol FinderFeatureFactory` |
| **Factory file** | `<BaseName>FeatureFactoryImpl.swift` | `FinderFeatureFactoryImpl.swift` |
| **Factory class** | `<BaseName>FeatureFactoryImpl` | `final class FinderFeatureFactoryImpl` |
| **Assembly file** | `<FeatureName>Assembly.swift` | `FinderFeatureAssembly.swift` |
| **Assembly class** | `<FeatureName>Assembly` | `final class FinderFeatureAssembly` |

### Example: LibraryFeature

```swift
// Interface/LibraryFeatureFactory.swift
public protocol LibraryFeatureFactory {
  @MainActor
  func makeLibraryViewController() -> UIViewController
}

// Sources/Factory/LibraryFeatureFactoryImpl.swift
final class LibraryFeatureFactoryImpl: LibraryFeatureFactory {
  nonisolated init(...) {
    // initialization
  }

  @MainActor
  func makeLibraryViewController() -> UIViewController {
    // implementation
  }
}

// Sources/Assembly/LibraryFeatureAssembly.swift
public final class LibraryFeatureAssembly: Assembly {
  public func assemble(container: Container) {
    container.register(LibraryFeatureFactory.self) { resolver in
      LibraryFeatureFactoryImpl(...)
    }
  }
}
```

---

## Domain Modules

Domain modules expose a business logic interface.

### Structure
```
Projects/Domain/<DomainName>/
├── Interface/
│   └── <BaseName>Domain.swift           ← Public domain protocol + models
└── Sources/
    ├── Assembly/
    │   └── <DomainName>Assembly.swift   ← DI assembly
    └── <BaseName>DomainImpl.swift       ← Domain implementation
```

### Naming Rules

| Item | Pattern | Example |
|------|---------|---------|
| **Module name** | `<BaseName>Domain` | `FinderDomain` |
| **Interface file** | `<BaseName>DomainInterface.swift` | `FinderDomainInterface.swift` |
| **Interface protocol** | `<BaseName>DomainInterface` | `protocol FinderDomainInterface` |
| **Implementation file** | `<BaseName>Domain.swift` | `FinderDomain.swift` |
| **Implementation class** | `<BaseName>Domain` | `final class FinderDomain` |
| **Assembly file** | `<DomainName>Assembly.swift` | `FinderDomainAssembly.swift` |
| **Assembly class** | `<DomainName>Assembly` | `final class FinderDomainAssembly` |

### Example: LibraryDomain

```swift
// Interface/LibraryDomainInterface.swift
public protocol LibraryDomainInterface {
  func fetchLibraries() async throws -> [Library]
}

public struct Library: Identifiable {
  public let id: UUID
  public let name: String
}

// Sources/LibraryDomain.swift
final class LibraryDomain: LibraryDomainInterface {
  func fetchLibraries() async throws -> [Library] {
    // implementation
  }
}

// Sources/Assembly/LibraryDomainAssembly.swift
public final class LibraryDomainAssembly: Assembly {
  public func assemble(container: Container) {
    container.register(LibraryDomainInterface.self) { resolver in
      LibraryDomain(...)
    }
  }
}
```

---

## Core Modules

Core modules provide infrastructure services. All Core modules have an Interface target for proper DI.

### Structure
```
Projects/Core/<CoreName>/
├── Interface/
│   └── <CoreName>Interface.swift        ← Public protocol + models
└── Sources/
    └── <CoreName>.swift                 ← Implementation
```

### Naming Rules

| Item | Pattern | Example |
|------|---------|---------|
| **Module name** | `<Name>Core` | `FileSystemCore` |
| **Interface protocol** | `<CoreName>Interface` | `protocol FileSystemCoreInterface` |
| **Interface file** | `<CoreName>Interface.swift` | `FileSystemCoreInterface.swift` |
| **Implementation file** | `<CoreName>.swift` | `FileSystemCore.swift` |
| **Implementation class** | `<CoreName>` | `final class FileSystemCore` |

---

## Shared Modules

Shared utilities (Logger, Extensions, etc.) - no Interface layer.

### Structure
```
Projects/Shared/<SharedName>/
└── Sources/
    └── <SharedName>.swift
```

### Naming Rules

| Item | Pattern | Example |
|------|---------|---------|
| **Module name** | `<Name>` | `Logger` |
| **Main file** | `<Name>.swift` | `Logger.swift` |
| **Main class** | `<Name>` | `public class Logger` |

---

## Domain Interface Naming: Why "Interface" Suffix?

### Question: Why `FinderDomainInterface` instead of `FinderDomain`?

**Short answer:** To avoid naming conflicts between the Interface protocol and implementation class.

### The Difference: Feature vs Domain

**Feature modules** use a different pattern than **Domain modules** for historical and practical reasons:

#### Feature Modules (Factory Pattern)
```swift
// Interface/FinderFeatureFactory.swift
public protocol FinderFeatureFactory { ... }

// Sources/Factory/FinderFeatureFactoryImpl.swift
final class FinderFeatureFactoryImpl: FinderFeatureFactory { ... }
```
✅ **No conflict**: Protocol is `FinderFeatureFactory`, implementation is `FinderFeatureFactoryImpl`

#### Domain Modules (Direct Implementation Pattern)
```swift
// Interface/FinderDomainInterface.swift
public protocol FinderDomainInterface { ... }

// Sources/FinderDomain.swift
final class FinderDomain: FinderDomainInterface { ... }
```
✅ **Avoids conflict**: If interface was named `FinderDomain`, it would conflict with the implementation class name

### Why Not Use `FinderDomainImpl`?

We **could** use this pattern:
```swift
// Interface/FinderDomain.swift
public protocol FinderDomain { ... }

// Sources/FinderDomainImpl.swift
final class FinderDomainImpl: FinderDomain { ... }
```

**But we chose `FinderDomainInterface` because:**
1. Domain implementations are the "main" class, not just an "implementation detail"
2. `FinderDomain` better represents the actual domain logic class
3. The interface is the abstraction, so it gets the suffix
4. Consistency with existing codebase patterns

### Pattern Summary

| Layer | Interface Protocol | Implementation Class | Why? |
|-------|---------------|---------------------|------|
| **Feature** | `FinderFeatureFactory` | `FinderFeatureFactoryImpl` | Factory pattern - `Impl` suffix for implementation |
| **Domain** | `FinderDomainInterface` | `FinderDomain` | Domain pattern - implementation IS the domain |
| **Core (w/ Interface)** | `ArchiveFileCoreInterface` | `ArchiveFileCore` | Same as Domain - implementation IS the core |

---

## Why This Convention?

### ✅ Benefits

1. **Clear Layer Identification** - Immediately know if it's Feature or Domain layer
2. **No Confusion** - `FinderFeatureFactory` vs `FinderDomainInterface` are clearly different
3. **Better Searchability** - Easy to find all Feature factories or Domain interfaces
4. **Self-Documenting** - File name alone tells you the layer and purpose
5. **Scalability** - Works well as codebase grows with multiple modules

### Example Comparison

**Before (Ambiguous):**
```swift
// Interface file: FinderFactory.swift
protocol FinderFactory { ... }  // ❌ Is this Feature or Domain?

// Could be confused with:
protocol FinderDomain { ... }  // ❌ Both start with "Finder"
```

**After (Explicit):**
```swift
// Interface file: FinderFeatureFactory.swift
protocol FinderFeatureFactory { ... }  // ✅ Clearly a Feature layer factory

// vs Domain:
protocol FinderDomainInterface { ... }  // ✅ Clearly a Domain layer interface
```

---

## Why Assemblies Keep Full Module Names

### Question: Why `FinderFeatureAssembly` instead of `FinderAssembly`?

**Short answer:** To prevent naming conflicts when you have both Feature and Domain for the same concept.

### The Problem

If you have both a Feature and Domain module for the same entity:

```swift
// In AppDIContainer.swift
import FinderFeature
import FinderDomain

// ❌ If both were just "FinderAssembly", this would conflict:
FinderAssembly()  // Ambiguous! Which one? Feature or Domain?

// ✅ With full names, it's crystal clear:
FinderFeatureAssembly()  // From FinderFeature module
FinderDomainAssembly()   // From FinderDomain module
```

### Different Contexts

**Interface folder (public API):**
- Imported with module name: `import FinderFeatureInterface`
- The module name provides scoping, so `FinderFactory` is clear in context
- No ambiguity: it's obviously the factory from `FinderFeatureInterface`

**Assembly (internal implementation):**
- Multiple assemblies imported together in `AppDIContainer`
- No module-level scoping when classes are imported directly
- Need full name to distinguish between Feature and Domain assemblies

### Real-World Example

```swift
// AppDIContainer.swift
import FinderFeature
import FinderDomain
import LibraryFeature
import LibraryDomain

func assembleDependencies() {
  // All assemblies in one place - names must be unique and descriptive
  FinderDomainAssembly().assemble(container: container)
  FinderFeatureAssembly().assemble(container: container)
  LibraryDomainAssembly().assemble(container: container)
  LibraryFeatureAssembly().assemble(container: container)
}
```

If they were all just `FinderAssembly`, `LibraryAssembly`, you'd have conflicts between Feature and Domain versions.

### The Rule

| Context | Keep Full Name? | Reason |
|---------|----------------|--------|
| **Interface protocols/types** | ❌ No | Module import provides scoping |
| **Factory implementations** | ❌ No | Internal to module, no conflicts |
| **Assembly classes** | ✅ Yes | Multiple assemblies used together, need unique names |

**Summary:**
- ✅ **Use full name for clarity**: `FinderFeatureFactory`, `FinderFeatureFactoryImpl`, `FinderDomainInterface`, `FinderDomain`, `ArchiveFileCoreInterface`, `ArchiveFileCore`
- ✅ **Keep full name for assemblies**: `FinderFeatureAssembly`, `FinderDomainAssembly`

---

## Quick Reference

### When creating a new Feature:
```bash
Module: LibraryFeature
Interface: LibraryFeatureFactory.swift → protocol LibraryFeatureFactory
Factory: LibraryFeatureFactoryImpl.swift → final class LibraryFeatureFactoryImpl
Assembly: LibraryFeatureAssembly.swift → final class LibraryFeatureAssembly
```

### When creating a new Domain:
```bash
Module: LibraryDomain
Interface: LibraryDomainInterface.swift → protocol LibraryDomainInterface
Implementation: LibraryDomain.swift → final class LibraryDomain
Assembly: LibraryDomainAssembly.swift → final class LibraryDomainAssembly
```

### When creating a new Core:
```bash
Module: NetworkCore
Interface: NetworkCoreInterface.swift → protocol NetworkCoreInterface
Implementation: NetworkCore.swift → final class NetworkCore
```
