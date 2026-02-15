import FinderDomainInterface
import Foundation

// MARK: - FinderViewState

struct FinderViewState {
  var items: [FileItem] = []
  var directories: [FileItem] = []
  var files: [FileItem] = []
  var errorMessage: String?
  var searchQuery: String = ""
  var sortType: FileSortType = .name
  var sortOrder: SortOrder = .asc
  var title: String = FinderStrings.stateTitle
  var isPartialReload: Bool = false

  // MARK: - Context Menu Sorting Logic
  
  func createSortDescription(for sortType: FileSortType) -> String? {
    guard self.sortType == sortType else { return nil }
    return sortOrder == .asc ?
      FinderStrings.stateAscending : FinderStrings.stateDescending
  }
}

// MARK: - FinderViewAction

enum FinderViewAction {
  case load
  case search(String)
  case createDirectory(String)
  case rename(FileItem, String)
  case delete([FileItem])
  case move([FileItem], destination: String)
  case clone(FileItem)
  case toggleSort(FileSortType)
  case reloadItem(FileItem)
}
