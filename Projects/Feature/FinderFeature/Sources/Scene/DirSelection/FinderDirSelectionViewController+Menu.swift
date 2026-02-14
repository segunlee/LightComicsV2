import UIKit

extension FinderDirSelectionViewController {
  func createContextMenu() -> UIMenu {
    let state = viewModel.state
    return UIMenu(title: "", children: [
      UIMenu(title: "", options: .displayInline, children: [
        UIAction(
          title: "New Folder",
          image: UIImage(systemName: "folder.badge.plus"),
          handler: { [weak self] _ in
            self?.showCreateDirectoryAlert()
          }
        )
      ]),

      UIMenu(title: "Sort", options: .displayInline, children: [
        UIAction(
          title: "Name",
          subtitle: state.createSortDescription(for: .name),
          state: state.sortType == .name ? .on : .off,
          handler: { [weak self] _ in
            self?.viewModel.send(.toggleSort(.name))
            self?.contextMenuButtonItem.menu = self?.createContextMenu()
          }
        ),
        UIAction(
          title: "Date",
          subtitle: state.createSortDescription(for: .date),
          state: state.sortType == .date ? .on : .off,
          handler: { [weak self] _ in
            self?.viewModel.send(.toggleSort(.date))
            self?.contextMenuButtonItem.menu = self?.createContextMenu()
          }
        ),
        UIAction(
          title: "Size",
          subtitle: state.createSortDescription(for: .size),
          state: state.sortType == .size ? .on : .off,
          handler: { [weak self] _ in
            self?.viewModel.send(.toggleSort(.size))
            self?.contextMenuButtonItem.menu = self?.createContextMenu()
          }
        )
      ])
    ])
  }
}
