import Logger
import UIKit

// MARK: - ReaderViewController + Navigation

extension ReaderViewController {
  // MARK: - Scroll Methods

  @discardableResult
  func scroll(to index: Int, animated: Bool = true, completion: (() -> Void)? = nil) -> Bool {
    let options = viewModel.state.options

    var position: UICollectionView.ScrollPosition = .init()
    switch options.direction {
    case .toRight: position = .left
    case .toLeft: position = .right
    case .toBottom: position = .top
    }

    let totalPages = viewModel.state.totalPages
    guard totalPages > 0 else { return false }

    switch options.display {
    case .single:
      guard index >= 0, index < totalPages else {
        Log.error("Invalid index: \(index)")
        return false
      }
    case .double:
      guard index >= 0, index <= totalPages else {
        Log.error("Invalid index: \(index)")
        return false
      }
    }

    let indexPath = IndexPath(row: index, section: 0)
    let collectionView = collectionView
    guard indexPath.row < collectionView.numberOfItems(inSection: 0) else { return false }

    collectionView.scrollToItem(at: indexPath, at: position, animated: animated)
    viewModel.send(.updateCurrentIndex(index))

    var deadline = 1.0
    switch options.transition {
    case .none, .naturalScroll: deadline = 0.0
    case .pageCurl: deadline = 0.8
    case .paging: deadline = 0.4
    }

    view.isUserInteractionEnabled = false
    DispatchQueue.main.asyncAfter(deadline: .now() + deadline) { [weak self] in
      self?.view.isUserInteractionEnabled = true
      completion?()
    }
    return true
  }

  func scroll(command: ReaderScrollCommand, animated: Bool = true, completion: (() -> Void)? = nil) {
    let options = viewModel.state.options
    let increment = options.display == .double ? 2 : 1
    let currentIndex = viewModel.state.currentIndex
    let newIndex = command == .next ? currentIndex + increment : currentIndex - increment
    scroll(to: newIndex, animated: animated, completion: completion)
  }

  func scrollWithPageCurlAnimation(command: ReaderScrollCommand) {
    guard viewModel.canScroll(command: command) else { return }
    let type = command == .next ? "pageCurl" : "pageUnCurl"
    let options = viewModel.state.options

    var subtype: CATransitionSubtype = .fromLeft
    switch options.direction {
    case .toLeft: subtype = .fromLeft
    case .toRight: subtype = .fromRight
    case .toBottom: subtype = .fromBottom
    }

    UIView.animate(withDuration: 0.8) { [weak self] in
      let animation = CATransition()
      animation.duration = 0.8
      animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      animation.type = CATransitionType(rawValue: type)
      animation.subtype = subtype
      animation.fillMode = CAMediaTimingFillMode(rawValue: "extended")
      animation.isRemovedOnCompletion = true
      self?.collectionView.layer.add(animation, forKey: "PageCurlAnimation")
    }
    scroll(command: command, animated: false)
  }

  // MARK: - Gesture Handlers

  @objc func didTapCollectionView(_ sender: UITapGestureRecognizer) {
    let options = viewModel.state.options
    let point = sender.location(in: view)
    let standard = options.touchPointLR ? view.bounds.width : view.bounds.height
    let tapArea = standard * 0.25

    var command: ReaderScrollCommand = .next
    switch options.touchPointLR ? point.x : point.y {
    case 0 ... tapArea:
      if options.direction == .toRight || options.direction == .toBottom { command = .previous }

    case standard - tapArea ... standard:
      if options.direction == .toLeft { command = .previous }

    default:
      guard !collectionView.isDecelerating else { return }
      toggleNavigationBar()
      return
    }

    switch options.transition {
    case .naturalScroll:
      return
    case .pageCurl:
      scrollWithPageCurlAnimation(command: command)
    case .none:
      scroll(command: command, animated: false)
    case .paging:
      scroll(command: command, animated: true)
    }
  }

  @objc func manuallySwipeAction(_ sender: UISwipeGestureRecognizer) {
    let options = viewModel.state.options
    var command: ReaderScrollCommand = .next

    switch sender.direction {
    case .left:
      if options.direction == .toLeft { command = .previous }
    case .right:
      if options.direction == .toRight || options.direction == .toBottom { command = .previous }
    case .down:
      if options.direction == .toBottom { command = .previous }
    default:
      break
    }

    switch options.transition {
    case .pageCurl:
      scrollWithPageCurlAnimation(command: command)
    case .none:
      scroll(command: command, animated: false)
    default:
      break
    }
  }

  // MARK: - Private Methods

  private func toggleNavigationBar() {
    let isHidden = navigationController?.isNavigationBarHidden ?? false
    navigationController?.setNavigationBarHidden(!isHidden, animated: true)

    let willShow = isHidden
    UIView.animate(withDuration: 0.35) { [weak self] in
      guard let self else { return }
      toolbar.isHidden = !willShow
      pagingLabel.isHidden = willShow
      view.layoutIfNeeded()
    }
  }

}
