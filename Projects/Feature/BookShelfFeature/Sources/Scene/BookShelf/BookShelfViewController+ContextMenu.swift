import BookDomainInterface
import UIKit

// MARK: - BookShelfViewController + UICollectionViewDelegate (ContextMenu)

extension BookShelfViewController {
  func collectionView(
    _ collectionView: UICollectionView,
    contextMenuConfigurationForItemAt indexPath: IndexPath,
    point: CGPoint
  ) -> UIContextMenuConfiguration? {
    guard
      let itemID = diffableDataSource?.itemIdentifier(for: indexPath),
      let readInfo = viewModel.state.allItems[itemID]
    else { return nil }

    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
      self?.makeContextMenu(for: readInfo) ?? UIMenu(children: [])
    }
  }

  // MARK: Private Methods

  private func makeContextMenu(for readInfo: ReadInfo) -> UIMenu {
    let fileName: String = {
      guard let path = readInfo.pathString else { return readInfo.id }
      return (path as NSString).lastPathComponent
    }()

    let openAction = UIAction(
      title: "열기",
      image: UIImage(systemName: "book")
    ) { [weak self] _ in
      self?.onSelectItem?(readInfo)
    }

    let markAsReadAction = UIAction(
      title: "다 읽음으로 표시",
      image: UIImage(systemName: "checkmark.circle")
    ) { [weak self] _ in
      self?.viewModel.send(.markAsRead(readInfo))
    }

    let resetProgressAction = UIAction(
      title: "읽기 진행 초기화",
      image: UIImage(systemName: "arrow.counterclockwise"),
      attributes: .destructive
    ) { [weak self] _ in
      self?.viewModel.send(.resetProgress(readInfo))
    }

    return UIMenu(title: fileName, children: [
      UIMenu(title: "", options: .displayInline, children: [openAction]),
      UIMenu(title: "", options: .displayInline, children: [markAsReadAction, resetProgressAction])
    ])
  }
}
