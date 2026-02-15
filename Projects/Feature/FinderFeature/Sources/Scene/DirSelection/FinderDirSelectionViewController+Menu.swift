import UIKit

extension FinderDirSelectionViewController {
  func createContextMenu() -> UIMenu {
    let state = viewModel.state
    return UIMenu(title: "", children: [
      UIMenu(title: "", options: .displayInline, children: [
        UIAction(
          title: FinderStrings.menuNewFolder,
          image: UIImage(systemName: "folder.badge.plus"),
          handler: { [weak self] _ in
            self?.showCreateDirectoryAlert()
          }
        )
      ]),

      UIMenu(title: FinderStrings.menuSort, options: .displayInline, children: [
        UIAction(
          title: FinderStrings.menuName,
          subtitle: state.createSortDescription(for: .name),
          state: state.sortType == .name ? .on : .off,
          handler: { [weak self] _ in
            self?.viewModel.send(.toggleSort(.name))
            self?.contextMenuButtonItem.menu = self?.createContextMenu()
          }
        ),
        UIAction(
          title: FinderStrings.menuDate,
          subtitle: state.createSortDescription(for: .date),
          state: state.sortType == .date ? .on : .off,
          handler: { [weak self] _ in
            self?.viewModel.send(.toggleSort(.date))
            self?.contextMenuButtonItem.menu = self?.createContextMenu()
          }
        ),
        UIAction(
          title: FinderStrings.menuSize,
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
