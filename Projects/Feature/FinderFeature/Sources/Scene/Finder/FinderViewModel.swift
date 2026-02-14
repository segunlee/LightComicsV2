import FinderDomainInterface
import Foundation
import Logger
import UserDefaultsService

// MARK: - FileSortType

enum FileSortType: Int {
  case name
  case date
  case size
}

// MARK: - SortOrder

enum SortOrder: Int {
  case asc
  case desc
}

// MARK: - UserPreferences

@MainActor
enum UserPreferences {
  @UserDefaultRawRepresentable(key: "finder.sortType", defaultValue: .name)
  static var finderSortType: FileSortType

  @UserDefaultRawRepresentable(key: "finder.sortOrder", defaultValue: .asc)
  static var finderSortOrder: SortOrder
}

/// Documents Path
let FinderDocumentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? ""

// MARK: - FinderViewModel

@MainActor
final class FinderViewModel: ObservableObject {
  @Published private(set) var state = FinderViewState()

  private let useCase: FinderUseCase
  private(set) var currentPath: String = ""
  private var cachedItems: [FileItem] = []
  private var loadTask: Task<Void, Never>?

  init(useCase: FinderUseCase, path: String? = nil) {
    self.useCase = useCase
    currentPath = path ?? FinderDocumentsPath
    state.title = URL(fileURLWithPath: currentPath).lastPathComponent
    loadSavedSettings()
  }

  private func loadSavedSettings() {
    state.sortType = UserPreferences.finderSortType
    state.sortOrder = UserPreferences.finderSortOrder
  }

  func send(_ action: FinderViewAction) {
    switch action {
    case .load:
      load()
    case let .search(query):
      search(query: query)
    case let .createDirectory(name):
      createDirectory(name: name)
    case let .rename(item, newName):
      rename(item: item, newName: newName)
    case let .delete(items):
      delete(items: items)
    case let .move(items, destination):
      move(items: items, to: destination)
    case let .clone(item):
      clone(item: item)
    case let .toggleSort(type):
      toggleSort(by: type)
    case let .reloadItem(item):
      reloadItem(item)
    }
  }

  // MARK: - Private Methods

  private func load() {
    loadTask?.cancel()
    let useCase = self.useCase
    let path = currentPath
    loadTask = Task {
      do {
        let allFiles = try await Task.detached {
          try useCase.listFiles(at: path)
        }.value
        guard !Task.isCancelled else { return }
        cachedItems = allFiles
        var next = state
        next.errorMessage = nil
        next.isPartialReload = false
        let displayItems = next.searchQuery.isEmpty
          ? allFiles
          : allFiles.filter { $0.name.localizedCaseInsensitiveContains(next.searchQuery) }
        updateItems(displayItems, into: &next)
        state = next
        Log.debug("Finder loaded: \(next.directories.count) dirs, \(next.files.count) files")
      } catch {
        guard !Task.isCancelled else { return }
        state.errorMessage = error.localizedDescription
        Log.error("Finder load failed: \(error.localizedDescription)")
      }
    }
  }

  private func search(query: String) {
    var next = state
    next.searchQuery = query
    next.errorMessage = nil
    next.isPartialReload = false
    let source = query.isEmpty
      ? cachedItems
      : cachedItems.filter { $0.name.localizedCaseInsensitiveContains(query) }
    updateItems(source, into: &next)
    state = next
  }

  private func toggleSort(by type: FileSortType) {
    var next = state
    if next.sortType == type {
      next.sortOrder = next.sortOrder == .asc ? .desc : .asc
    } else {
      next.sortType = type
      next.sortOrder = .asc
    }

    UserPreferences.finderSortType = next.sortType
    UserPreferences.finderSortOrder = next.sortOrder
    Log.debug("Sort changed: type=\(next.sortType), order=\(next.sortOrder)")

    let source = next.searchQuery.isEmpty
      ? cachedItems
      : cachedItems.filter { $0.name.localizedCaseInsensitiveContains(next.searchQuery) }
    next.isPartialReload = false
    updateItems(source, into: &next)
    state = next
  }

  private func reloadItem(_ item: FileItem) {
    let useCase = self.useCase
    let path = currentPath
    loadTask?.cancel()
    loadTask = Task {
      do {
        let allFiles = try await Task.detached {
          try useCase.listFiles(at: path)
        }.value
        guard !Task.isCancelled else { return }
        guard let updated = allFiles.first(where: { $0.path == item.path }) else { return }
        cachedItems = allFiles
        var next = state
        if let index = next.directories.firstIndex(of: item) {
          next.directories[index] = updated
        } else if let index = next.files.firstIndex(of: item) {
          next.files[index] = updated
        }
        next.items = next.directories + next.files
        next.isPartialReload = true
        state = next
      } catch {
        Log.error("Reload item '\(item.name)' failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - Mutations

  private func createDirectory(name: String) {
    guard !name.isEmpty else { return }
    let useCase = self.useCase
    let path = currentPath
    performMutation(
      { try useCase.createDirectory(named: name, at: path) },
      errorContext: "Create directory '\(name)' failed"
    )
  }

  private func rename(item: FileItem, newName: String) {
    guard !newName.isEmpty else { return }
    let useCase = self.useCase
    performMutation(
      { try useCase.renameItem(at: item.path, to: newName) },
      errorContext: "Rename '\(item.name)' -> '\(newName)' failed"
    )
  }

  private func delete(items: [FileItem]) {
    guard !items.isEmpty else { return }
    let useCase = self.useCase
    let paths = items.map(\.path)
    performMutation(
      { try useCase.deleteItems(at: paths) },
      errorContext: "Delete \(items.count) items failed"
    )
  }

  private func move(items: [FileItem], to destinationDirectory: String) {
    guard !items.isEmpty else { return }
    let useCase = self.useCase
    let paths = items.map(\.path)
    performMutation(
      { try useCase.moveItems(at: paths, to: destinationDirectory) },
      errorContext: "Move \(items.count) items failed"
    )
  }

  private func clone(item: FileItem) {
    let useCase = self.useCase
    performMutation(
      { try useCase.cloneItem(at: item.path) },
      errorContext: "Clone '\(item.name)' failed"
    )
  }

  private func performMutation(_ operation: @escaping @Sendable () throws -> Void, errorContext: String) {
    loadTask?.cancel()
    let useCase = self.useCase
    let path = currentPath
    loadTask = Task {
      do {
        try await Task.detached { try operation() }.value
        guard !Task.isCancelled else { return }
        let allFiles = try await Task.detached {
          try useCase.listFiles(at: path)
        }.value
        guard !Task.isCancelled else { return }
        cachedItems = allFiles
        var next = state
        next.errorMessage = nil
        next.isPartialReload = false
        let displayItems = next.searchQuery.isEmpty
          ? allFiles
          : allFiles.filter { $0.name.localizedCaseInsensitiveContains(next.searchQuery) }
        updateItems(displayItems, into: &next)
        state = next
      } catch {
        guard !Task.isCancelled else { return }
        state.errorMessage = error.localizedDescription
        Log.error("\(errorContext): \(error.localizedDescription)")
      }
    }
  }

  // MARK: - Helpers

  private func updateItems(_ allFiles: [FileItem], into state: inout FinderViewState) {
    let directories = sortItems(allFiles.filter(\.isDirectory), state: state)
    let files = sortItems(allFiles.filter { !$0.isDirectory }, state: state)

    state.directories = directories
    state.files = files
    state.items = directories + files
  }

  private func sortItems(_ items: [FileItem], state: FinderViewState) -> [FileItem] {
    items.sorted { lhs, rhs in
      let comparison: Bool = switch state.sortType {
      case .name:
        lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
      case .date:
        lhs.modifiedDate ?? Date() < rhs.modifiedDate ?? Date()
      case .size:
        lhs.size ?? 0 < rhs.size ?? 0
      }
      return state.sortOrder == .asc ? comparison : !comparison
    }
  }
}
