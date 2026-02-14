import FinderDomainInterface
import Foundation

// MARK: - DirSelectionViewState

struct DirSelectionViewState {
  var directories: [FileItem] = []
  var sortType: FileSortType = .name
  var sortOrder: SortOrder = .asc
  var errorMessage: String?
  var title: String = ""

  func createSortDescription(for sortType: FileSortType) -> String? {
    guard self.sortType == sortType else { return nil }
    return sortOrder == .asc ? "ascending" : "descending"
  }
}

// MARK: - DirSelectionViewAction

enum DirSelectionViewAction {
  case load
  case createDirectory(String)
  case toggleSort(FileSortType)
}
