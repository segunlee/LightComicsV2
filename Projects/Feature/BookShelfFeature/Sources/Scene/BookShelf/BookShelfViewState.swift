import BookDomainInterface
import Foundation

// MARK: - BookShelfSectionType

enum BookShelfSectionType: Hashable {
  case nowReading
  case read
  case folder(path: String, name: String)

  var title: String {
    switch self {
    case .nowReading:
      return "읽는 중"
    case .read:
      return "다 읽음"
    case let .folder(_, name):
      return name
    }
  }
}

// MARK: - BookShelfViewState

struct BookShelfViewState {
  var sections: [BookShelfSectionType] = []
  var itemsBySection: [BookShelfSectionType: [ReadInfo]] = [:]
  var allItems: [String: ReadInfo] = [:]
  var isLoading: Bool = false
  var errorMessage: String? = nil
}

// MARK: - BookShelfViewAction

enum BookShelfViewAction {
  case load
  case refresh
  case openItem(ReadInfo)
  case markAsRead(ReadInfo)
  case resetProgress(ReadInfo)
}
