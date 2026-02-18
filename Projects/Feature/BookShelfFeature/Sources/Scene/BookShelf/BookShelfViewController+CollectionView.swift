import BookDomainInterface
import SwiftUI
import UIKit

// MARK: - TypeAlias

typealias BookShelfDataSource = UICollectionViewDiffableDataSource<BookShelfSectionType, String>
typealias BookShelfSnapshot = NSDiffableDataSourceSnapshot<BookShelfSectionType, String>

// MARK: - BookShelfViewController + CollectionView Setup

extension BookShelfViewController {
  func makeCollectionViewLayout() -> UICollectionViewLayout {
    UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ -> NSCollectionLayoutSection? in
      self?.makeSection(for: sectionIndex)
    }
  }

  func configureDataSource() {
    let cellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, String> { [weak self] cell, _, itemID in
      guard let self, let readInfo = viewModel.state.allItems[itemID] else { return }
      cell.contentConfiguration = UIHostingConfiguration {
        BookShelfCell(readInfo: readInfo, onOpen: { [weak self] in
          self?.onSelectItem?(readInfo)
        })
      }
      .margins(.all, 0)
    }

    let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewCell>(
      elementKind: UICollectionView.elementKindSectionHeader
    ) { [weak self] header, _, indexPath in
      guard let self else { return }
      let section = viewModel.state.sections[indexPath.section]
      let count = viewModel.state.itemsBySection[section]?.count ?? 0
      header.contentConfiguration = UIHostingConfiguration {
        BookShelfSectionHeaderView(title: section.title, itemCount: count)
      }
      .margins(.all, 0)
    }

    diffableDataSource = BookShelfDataSource(collectionView: collectionView) { collectionView, indexPath, itemID in
      collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemID)
    }

    diffableDataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
      guard kind == UICollectionView.elementKindSectionHeader else { return nil }
      return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
    }
  }

  func applySnapshot(sections: [BookShelfSectionType], itemsBySection: [BookShelfSectionType: [ReadInfo]]) {
    var snapshot = BookShelfSnapshot()
    snapshot.appendSections(sections)
    for section in sections {
      let ids = (itemsBySection[section] ?? []).map(\.id)
      snapshot.appendItems(ids, toSection: section)
    }
    diffableDataSource?.apply(snapshot, animatingDifferences: true)
  }

  // MARK: Private Layout Helpers

  private func makeSection(for sectionIndex: Int) -> NSCollectionLayoutSection {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .absolute(220),
      heightDimension: .absolute(320)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .absolute(220),
      heightDimension: .absolute(320)
    )
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

    let section = NSCollectionLayoutSection(group: group)
    section.orthogonalScrollingBehavior = .groupPagingCentered
    section.interGroupSpacing = 16
    section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 28, trailing: 20)

    let headerSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(56)
    )
    let header = NSCollectionLayoutBoundarySupplementaryItem(
      layoutSize: headerSize,
      elementKind: UICollectionView.elementKindSectionHeader,
      alignment: .top
    )
    section.boundarySupplementaryItems = [header]
    return section
  }
}

// MARK: - BookShelfViewController + UICollectionViewDelegate

extension BookShelfViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    guard
      let itemID = diffableDataSource?.itemIdentifier(for: indexPath),
      let readInfo = viewModel.state.allItems[itemID]
    else { return }
    onSelectItem?(readInfo)
  }
}
