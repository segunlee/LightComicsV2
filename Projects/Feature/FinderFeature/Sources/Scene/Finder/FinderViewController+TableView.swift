import FinderDomainInterface
import SwiftUI
import UIKit

// MARK: - FinderSection

enum FinderSection: Int, CaseIterable {
  case directories
  case files

  var title: String? {
    switch self {
    case .directories: "Directories"
    case .files: "Files"
    }
  }
}

// MARK: - FinderDataSource

final class FinderDataSource: UITableViewDiffableDataSource<FinderSection, FileItem> {
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let snapshot = snapshot()
    guard let finderSection = FinderSection(rawValue: section) else { return nil }
    return snapshot.itemIdentifiers(inSection: finderSection).isEmpty ? nil : finderSection.title
  }
}

// MARK: - FinderViewController + DataSource

extension FinderViewController {
  func configureDataSource() {
    diffableDataSource = FinderDataSource(tableView: tableView) { tableView, indexPath, item in
      let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

      cell.contentConfiguration = UIHostingConfiguration {
        FileItemCell(item: item)
      }

      cell.accessoryType = item.isDirectory ? .disclosureIndicator : .none

      return cell
    }
  }

  func applySnapshot(directories: [FileItem], files: [FileItem], animatingDifferences: Bool = true) {
    let isInitialLoad = diffableDataSource?.snapshot().numberOfItems == 0
    var snapshot = NSDiffableDataSourceSnapshot<FinderSection, FileItem>()
    snapshot.appendSections(FinderSection.allCases)
    snapshot.appendItems(directories, toSection: .directories)
    snapshot.appendItems(files, toSection: .files)
    diffableDataSource?.apply(snapshot, animatingDifferences: isInitialLoad ? false : animatingDifferences)
  }
}

// MARK: - FinderÍViewController + UITableViewDelegate

extension FinderViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard !isEditMode else { return }

    guard let item = diffableDataSource?.itemIdentifier(for: indexPath) else { return }

    commitCellAction(with: item)
  }

  func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard let item = diffableDataSource?.itemIdentifier(for: indexPath) else { return nil }

    let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
      self?.viewModel.send(.delete([item]))
      completion(true)
    }
    deleteAction.image = UIImage(systemName: "trash")

    return UISwipeActionsConfiguration(actions: [deleteAction])
  }

  func tableView(_: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    createTableRowContextMenu(indexPath: indexPath, point: point)
  }
}

extension FinderViewController {
  func commitCellAction(with item: FileItem) {
    guard !item.isDirectory else {
      router.showDirectory(item)
      return
    }

    guard router.canShowReader(item) else {
      previewItem(item)
      return
    }

    router.showReader(item)
  }
}
