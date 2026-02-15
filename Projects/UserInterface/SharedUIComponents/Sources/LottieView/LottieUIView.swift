import Lottie
import UIKit

// MARK: - LottieUIView

@MainActor
public final class LottieUIView: UIView {

  // MARK: - Properties

  private let animationView: LottieAnimationView

  // MARK: - Initialization

  public init(
    animationName: String,
    loopMode: LottieLoopMode = .loop,
    contentMode: UIView.ContentMode = .scaleAspectFit
  ) {
    animationView = LottieAnimationView(name: animationName, bundle: .module)
    animationView.loopMode = loopMode
    animationView.contentMode = contentMode
    animationView.translatesAutoresizingMaskIntoConstraints = false
    super.init(frame: .zero)
    setupView()
    animationView.play()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Private Methods

  private func setupView() {
    translatesAutoresizingMaskIntoConstraints = false
    addSubview(animationView)
    NSLayoutConstraint.activate([
      animationView.topAnchor.constraint(equalTo: topAnchor),
      animationView.leadingAnchor.constraint(equalTo: leadingAnchor),
      animationView.trailingAnchor.constraint(equalTo: trailingAnchor),
      animationView.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])
  }
}
