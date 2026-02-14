import UIKit

extension FinderViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    let query = searchController.searchBar.text ?? ""
    if query.isEmpty {
      viewModel.send(.search(""))
    } else {
      searchSubject.send(query)
    }
  }
}
