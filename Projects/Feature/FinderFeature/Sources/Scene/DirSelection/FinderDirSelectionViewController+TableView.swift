import FinderDomainInterface
import SwiftUI
import UIKit

extension FinderDirSelectionViewController {
  func configureDataSource() {
    diffableDataSource = UITableViewDiffableDataSource<Int, FileItem>(tableView: tableView) { tableView, indexPath, item in
      let cell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath)
      cell.contentConfiguration = UIHostingConfiguration {
        FileItemCell(item: item)
      }
      cell.accessoryType = .disclosureIndicator
      return cell
    }
  }

  func applySnapshot(_ directories: [FileItem]) {
    let isInitialLoad = diffableDataSource?.snapshot().numberOfItems == 0
    var snapshot = NSDiffableDataSourceSnapshot<Int, FileItem>()
    snapshot.appendSections([0])
    snapshot.appendItems(directories, toSection: 0)
    diffableDataSource?.apply(snapshot, animatingDifferences: !isInitialLoad)
  }
}

// MARK: - FinderDirSelectionViewController + UITableViewDelegate

extension FinderDirSelectionViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard let item = diffableDataSource?.itemIdentifier(for: indexPath) else { return }
    let nextVC = FinderDirSelectionViewController(
      useCase: useCase,
      path: item.path,
      excludedPaths: excludedPaths,
      onSelect: onSelect
    )
    navigationController?.pushViewController(nextVC, animated: true)
  }
}
