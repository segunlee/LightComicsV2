import FinderDomainInterface
import UIKit

extension FinderViewController {
  func createNavigationContextMenu() -> UIMenu {
    UIMenu(title: "Document", image: nil, identifier: nil, options: .destructive, children: [
      UIMenu(title: "", options: .displayInline, children: [
        UIAction(
          title: "Select",
          image: UIImage(systemName: "checkmark.circle"),
          state: .off,
          handler: { [weak self] _ in
            self?.isEditMode = true
          }),
        UIAction(
          title: "Create Directory",
          image: UIImage(systemName: "folder.badge.plus"),
          state: .off,
          handler: { [weak self] _ in
            self?.showCreateDirectoryAlert()
          })
      ]),

      UIMenu(title: "Sort", options: .displayInline, children: [
        UIAction(
          title: "Name",
          subtitle: viewModel.state.createSortDescription(for: .name),
          state: viewModel.state.sortType == .name ? .on : .off,
          handler: { [weak self] _ in
            self?.viewModel.send(.toggleSort(.name))
            self?.contextMenuButtonItem.menu = self?.createNavigationContextMenu()
          }),
        UIAction(
          title: "Date",
          subtitle: viewModel.state.createSortDescription(for: .date),
          state: viewModel.state.sortType == .date ? .on : .off,
          handler: { [weak self] _ in
            self?.viewModel.send(.toggleSort(.date))
            self?.contextMenuButtonItem.menu = self?.createNavigationContextMenu()
          }),
        UIAction(
          title: "Size",
          subtitle: viewModel.state.createSortDescription(for: .size),
          state: viewModel.state.sortType == .size ? .on : .off,
          handler: { [weak self] _ in
            self?.viewModel.send(.toggleSort(.size))
            self?.contextMenuButtonItem.menu = self?.createNavigationContextMenu()
          })
      ])
    ])
  }

  func createTableRowContextMenu(indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    guard let item = diffableDataSource?.itemIdentifier(for: indexPath) else { return nil }

    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
      let selectAction = UIAction(title: "Select", image: UIImage(systemName: "filemenu.and.selection")) { [weak self] _ in
        if self?.isEditMode == false {
          self?.isEditMode = true
        }
        self?.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
      }

      let renameAction = UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { [weak self] _ in
        self?.showRenameAlert(for: item)
      }

//      let cloneAction = UIAction(title: "Duplicate", image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
//        self?.viewModel.send(.clone(item))
//      }

      let moveAction = UIAction(title: "Move", image: UIImage(systemName: "folder")) { [weak self] _ in
        self?.router.showDirSelection(for: [item], currnetPath: self?.viewModel.currentPath) { destination in
          self?.viewModel.send(.move([item], destination: destination))
        }
      }

      let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
        self?.viewModel.send(.delete([item]))
      }

      let shareAction = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
        self?.shareItem(item)
      }

      let previewAction = UIAction(title: "Preview", image: UIImage(systemName: "eye")) { [weak self] _ in
        self?.previewItem(item)
      }

      var menus: [UIMenu] = .init()

      menus.append(
        UIMenu(title: "", options: .displayInline, children: [
          selectAction,
          moveAction
        ])
      )

      menus.append(
        UIMenu(title: "", options: .displayInline, children: [renameAction])
      )
      
      var children: [UIAction] = [previewAction, shareAction]
      if item.isDirectory { children.removeFirst() }
      menus.append(
        UIMenu(title: "", options: .displayInline, children: children)
      )

      menus.append(
        UIMenu(title: "", options: .displayInline, children: [deleteAction])
      )

      return UIMenu(title: item.name, options: .displayInline, children: menus)
    }
  }

  // MARK: - Share

  private func shareItem(_ item: FileItem) {
    let url = URL(fileURLWithPath: item.path)
    let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)

    // For iPad support
    if let popover = activityViewController.popoverPresentationController {
      popover.sourceView = view
      popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
      popover.permittedArrowDirections = []
    }

    present(activityViewController, animated: true)
  }
}
