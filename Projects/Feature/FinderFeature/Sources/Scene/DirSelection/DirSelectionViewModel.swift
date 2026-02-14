import FinderDomainInterface
import Foundation
import Logger

// MARK: - DirSelectionViewModel

@MainActor
final class DirSelectionViewModel: ObservableObject {
  @Published private(set) var state = DirSelectionViewState()

  private let useCase: FinderUseCase
  let currentPath: String
  private let excludedPaths: Set<String>
  private var cachedItems: [FileItem] = []
  private var loadTask: Task<Void, Never>?

  init(useCase: FinderUseCase, path: String, excludedPaths: Set<String>) {
    self.useCase = useCase
    currentPath = path
    self.excludedPaths = excludedPaths
    state.title = URL(fileURLWithPath: path).lastPathComponent
    state.sortType = UserPreferences.finderSortType
    state.sortOrder = UserPreferences.finderSortOrder
  }

  func send(_ action: DirSelectionViewAction) {
    switch action {
    case .load:
      load()
    case let .createDirectory(name):
      createDirectory(name: name)
    case let .toggleSort(type):
      toggleSort(by: type)
    }
  }

  // MARK: - Private Methods

  private func load() {
    loadTask?.cancel()
    let useCase = self.useCase
    let path = currentPath
    let excluded = excludedPaths
    loadTask = Task {
      do {
        let allFiles = try await Task.detached {
          try useCase.listFiles(at: path)
        }.value
        guard !Task.isCancelled else { return }
        cachedItems = allFiles.filter { $0.isDirectory && !excluded.contains($0.path) }
        var next = state
        next.errorMessage = nil
        next.directories = sortItems(cachedItems, state: next)
        state = next
      } catch {
        guard !Task.isCancelled else { return }
        state.errorMessage = error.localizedDescription
        Log.error("DirSelection load failed: \(error.localizedDescription)")
      }
    }
  }

  private func createDirectory(name: String) {
    guard !name.isEmpty else { return }
    let useCase = self.useCase
    let path = currentPath
    let excluded = excludedPaths
    loadTask?.cancel()
    loadTask = Task {
      do {
        try await Task.detached { try useCase.createDirectory(named: name, at: path) }.value
        guard !Task.isCancelled else { return }
        let allFiles = try await Task.detached {
          try useCase.listFiles(at: path)
        }.value
        guard !Task.isCancelled else { return }
        cachedItems = allFiles.filter { $0.isDirectory && !excluded.contains($0.path) }
        var next = state
        next.errorMessage = nil
        next.directories = sortItems(cachedItems, state: next)
        state = next
      } catch {
        guard !Task.isCancelled else { return }
        state.errorMessage = error.localizedDescription
        Log.error("Create directory '\(name)' failed: \(error.localizedDescription)")
      }
    }
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

    next.directories = sortItems(cachedItems, state: next)
    state = next
  }

  // MARK: - Helpers

  private func sortItems(_ items: [FileItem], state: DirSelectionViewState) -> [FileItem] {
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
