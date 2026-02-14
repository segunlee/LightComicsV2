import Logger
import UIKit

// MARK: - ReaderViewController + UICollectionViewDataSource

extension ReaderViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    var number = viewModel.state.totalPages
    guard number > 0 else { return 0 }

    if viewModel.state.options.display == .double, number % 2 == 1 {
      number += 1
    }
    return number
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: ReaderPageCell.identifier, for: indexPath
    ) as? ReaderPageCell else {
      return UICollectionViewCell()
    }
    cell.contentIndex = indexPath.row
    var cellOptions = viewModel.state.options
    cellOptions.hidePagingLabel = true
    cell.readerContentView.options = cellOptions
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    guard let readerCell = cell as? ReaderPageCell else { return }
    readerCell.readerContentView.beforeDecoration()

    Task { @MainActor in
      do {
        let element = try await viewModel.loadElement(at: indexPath.row)
        readerCell.readerContentView.decorate(
          with: element, at: indexPath.row, totalPages: viewModel.state.totalPages
        )
      } catch {
        readerCell.readerContentView.decorateError(error)
      }
      readerCell.readerContentView.afterDecoration()
    }
  }
}

// MARK: - ReaderViewController + UICollectionViewDelegateFlowLayout

extension ReaderViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let options = viewModel.state.options
    guard options.display.isDouble else { return view.bounds.size }
    guard indexPath.section == 0 else { return view.bounds.size }
    guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }

    if flowLayout.scrollDirection == .horizontal {
      return CGSize(width: view.bounds.width / 2, height: view.bounds.height)
    } else {
      return CGSize(width: view.bounds.width, height: view.bounds.height / 2)
    }
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    .zero
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    0
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    0
  }
}

// MARK: - ReaderViewController + UIScrollViewDelegate

extension ReaderViewController: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard scrollView.isDragging else { return }

    let collectionView = collectionView
    let options = viewModel.state.options
    let rect = CGRect(origin: scrollView.contentOffset, size: scrollView.bounds.size)
    var point = CGPoint(x: rect.minX, y: rect.midY)

    if options.display == .double {
      switch options.direction {
      case .toRight: point = CGPoint(x: rect.maxX, y: rect.midY)
      case .toLeft: point = CGPoint(x: rect.minX, y: rect.midY)
      case .toBottom: point = CGPoint(x: rect.midX, y: rect.maxY - 20)
      }
    }

    guard let indexPath = collectionView.indexPathForItem(at: point) else { return }
    viewModel.send(.updateCurrentIndex(indexPath.row))
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    let collectionView = collectionView
    let options = viewModel.state.options
    let rect = CGRect(origin: scrollView.contentOffset, size: scrollView.bounds.size)
    var point = CGPoint(x: rect.minX, y: rect.midY)

    if options.display == .double {
      switch options.direction {
      case .toRight: point = CGPoint(x: rect.maxX, y: rect.midY)
      case .toLeft: point = CGPoint(x: rect.minX, y: rect.midY)
      case .toBottom: point = CGPoint(x: rect.midX, y: rect.maxY - 20)
      }
    }

    guard let indexPath = collectionView.indexPathForItem(at: point) else { return }
    viewModel.send(.updateCurrentIndex(indexPath.row))
  }
}

// MARK: - ReaderViewController + UIGestureRecognizerDelegate

extension ReaderViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    true
  }
}

// MARK: - ReaderViewController + ReaderViewModelDelegate

extension ReaderViewController: ReaderViewModelDelegate {
  func readerViewModel(_ viewModel: ReaderViewModel, didRequestScrollTo index: Int, animated: Bool) {
    scroll(to: index, animated: animated)
  }

  func readerViewModelDidUpdateOptions(_ viewModel: ReaderViewModel) {
    let currentIndex = viewModel.state.currentIndex
    applyOptionsToCollectionView()
    scroll(to: currentIndex, animated: false)
  }
}
