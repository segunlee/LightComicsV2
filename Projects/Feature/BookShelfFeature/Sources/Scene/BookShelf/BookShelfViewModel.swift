import BookDomainInterface
import Combine
import Foundation
import Logger
import SharedUIComponents

// MARK: - BookShelfViewModel

@MainActor
final class BookShelfViewModel: ObservableObject {
  @Published private(set) var state = BookShelfViewState()
  let toastEvent = PassthroughSubject<ToastConfiguration, Never>()

  private let useCase: BookShelfUseCase
  private var loadTask: Task<Void, Never>?

  init(useCase: BookShelfUseCase) {
    self.useCase = useCase
  }

  func send(_ action: BookShelfViewAction) {
    switch action {
    case .load, .refresh:
      load()
    case let .openItem(readInfo):
      Log.debug("BookShelfViewModel: openItem requested for \(readInfo.id)")
    case let .markAsRead(readInfo):
      performMutation({ [useCase] in try useCase.markAsRead(identifier: readInfo.id) }, errorContext: "markAsRead \(readInfo.id)")
    case let .resetProgress(readInfo):
      performMutation({ [useCase] in try useCase.resetProgress(identifier: readInfo.id) }, errorContext: "resetProgress \(readInfo.id)")
    }
  }

  // MARK: Private Methods

  private func load() {
    loadTask?.cancel()
    let useCase = self.useCase
    loadTask = Task {
      var next = state
      next.isLoading = true
      next.errorMessage = nil
      state = next

      do {
        let (nowReading, read, all) = try await Task.detached {
          (try useCase.fetchNowReading(), try useCase.fetchRead(), try useCase.fetchAll())
        }.value

        guard !Task.isCancelled else { return }

        state = buildState(nowReading: nowReading, read: read, all: all)
        Log.debug("BookShelf loaded: \(state.sections.count) sections, \(state.allItems.count) total items")
      } catch {
        guard !Task.isCancelled else { return }
        var updated = state
        updated.isLoading = false
        updated.errorMessage = error.localizedDescription
        state = updated
        Log.error("BookShelf load failed: \(error.localizedDescription)")
      }
    }
  }

  private func performMutation(_ operation: @escaping @Sendable () throws -> Void, errorContext: String) {
    loadTask?.cancel()
    let useCase = self.useCase
    loadTask = Task {
      do {
        try await Task.detached { try operation() }.value
        guard !Task.isCancelled else { return }
        let (nowReading, read, all) = try await Task.detached {
          (try useCase.fetchNowReading(), try useCase.fetchRead(), try useCase.fetchAll())
        }.value
        guard !Task.isCancelled else { return }
        state = buildState(nowReading: nowReading, read: read, all: all)
      } catch {
        guard !Task.isCancelled else { return }
        toastEvent.send(.init(type: .error, message: error.localizedDescription))
        Log.error("\(errorContext): \(error.localizedDescription)")
      }
    }
  }

  private func buildState(nowReading: [ReadInfo], read: [ReadInfo], all: [ReadInfo]) -> BookShelfViewState {
    var sections: [BookShelfSectionType] = []
    var itemsBySection: [BookShelfSectionType: [ReadInfo]] = [:]
    var allItems: [String: ReadInfo] = [:]

    if !nowReading.isEmpty {
      sections.append(.nowReading)
      itemsBySection[.nowReading] = nowReading
      nowReading.forEach { allItems[$0.id] = $0 }
    }

    if !read.isEmpty {
      sections.append(.read)
      itemsBySection[.read] = read
      read.forEach { allItems[$0.id] = $0 }
    }

    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      .first?.path ?? ""

    var subfolderGroups: [String: [ReadInfo]] = [:]
    for readInfo in all {
      guard let path = readInfo.pathString else { continue }
      let parent = (path as NSString).deletingLastPathComponent
      guard parent != documentsPath, parent.hasPrefix(documentsPath + "/") else { continue }
      let relative = String(parent.dropFirst(documentsPath.count + 1))
      let firstComponent = relative.split(separator: "/").first.map(String.init) ?? relative
      let subfolderPath = documentsPath + "/" + firstComponent
      subfolderGroups[subfolderPath, default: []].append(readInfo)
    }

    let sortedFolders = subfolderGroups.keys
      .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

    for folderPath in sortedFolders {
      let folderName = (folderPath as NSString).lastPathComponent
      let section = BookShelfSectionType.folder(path: folderPath, name: folderName)
      let items = subfolderGroups[folderPath] ?? []
      sections.append(section)
      itemsBySection[section] = items
      items.forEach { allItems[$0.id] = $0 }
    }

    return BookShelfViewState(
      sections: sections,
      itemsBySection: itemsBySection,
      allItems: allItems,
      isLoading: false,
      errorMessage: nil
    )
  }
}
