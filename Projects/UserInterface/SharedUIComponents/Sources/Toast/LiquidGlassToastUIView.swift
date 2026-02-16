import UIKit

// MARK: - LiquidGlassToastUIView

final class LiquidGlassToastUIView: UIView {
  // MARK: - Properties

  private let configuration: ToastConfiguration
  private let onDismiss: () -> Void

  private let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
  private lazy var blurView = UIVisualEffectView(effect: blurEffect)

  private var iconView: LottieUIView?
  private let titleLabel = UILabel()
  private let messageLabel = UILabel()
  private lazy var actionButton: UIButton = {
    var config = UIButton.Configuration.filled()
    config.cornerStyle = .medium
    config.baseBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
    config.baseForegroundColor = .systemBlue
    config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)

    var titleAttr = AttributedString(configuration.buttonTitle ?? "")
    titleAttr.font = .systemFont(ofSize: 14, weight: .medium)
    config.attributedTitle = titleAttr

    let button = UIButton(configuration: config)
    button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    return button
  }()
  private let stackView = UIStackView()

  // MARK: - Initialization

  init(configuration: ToastConfiguration, onDismiss: @escaping () -> Void) {
    self.configuration = configuration
    self.onDismiss = onDismiss
    super.init(frame: .zero)
    setupUI()
    setupGestures()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Setup

  // swiftlint:disable:next function_body_length
  private func setupUI() {
    // Blur effect background
    blurView.translatesAutoresizingMaskIntoConstraints = false
    blurView.layer.cornerRadius = 20
    blurView.layer.cornerCurve = .continuous
    blurView.clipsToBounds = true
    addSubview(blurView)

    // Border
    layer.cornerRadius = 20
    layer.cornerCurve = .continuous
    layer.borderWidth = 0.5
    layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor

    // Shadow
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.15
    layer.shadowOffset = CGSize(width: 0, height: 10)
    layer.shadowRadius = 20

    // Icon
    let lottieIcon = LottieUIView(
      animationName: configuration.type.animationName,
      loopMode: .playOnce
    )
    lottieIcon.translatesAutoresizingMaskIntoConstraints = false
    iconView = lottieIcon

    // Text stack
    let textStack = UIStackView()
    textStack.axis = .vertical
    textStack.spacing = 4
    textStack.alignment = .leading

    // Title
    if let title = configuration.title {
      titleLabel.text = title
      titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
      titleLabel.textColor = .label
      titleLabel.numberOfLines = 1
      textStack.addArrangedSubview(titleLabel)
    }

    // Message
    messageLabel.text = configuration.message
    messageLabel.font = .systemFont(ofSize: 14, weight: .regular)
    messageLabel.textColor = .label
    messageLabel.numberOfLines = 3
    textStack.addArrangedSubview(messageLabel)

    // Main stack
    stackView.axis = .horizontal
    stackView.spacing = 12
    stackView.alignment = .center
    stackView.translatesAutoresizingMaskIntoConstraints = false

    stackView.addArrangedSubview(lottieIcon)
    stackView.addArrangedSubview(textStack)

    // Button
    if configuration.buttonTitle != nil {
      stackView.addArrangedSubview(actionButton)
    }

    blurView.contentView.addSubview(stackView)

    NSLayoutConstraint.activate([
      blurView.topAnchor.constraint(equalTo: topAnchor),
      blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
      blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
      blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

      stackView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor, constant: 16),
      stackView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -16),
      stackView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor, constant: -16),

      lottieIcon.widthAnchor.constraint(equalToConstant: 28),
      lottieIcon.heightAnchor.constraint(equalToConstant: 28)
    ])
  }

  private func setupGestures() {
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    addGestureRecognizer(panGesture)
  }

  // MARK: - Actions

  @objc private func buttonTapped() {
    configuration.buttonAction?()
    onDismiss()
  }

  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    let translation = gesture.translation(in: superview)

    switch gesture.state {
    case .changed:
      // Only allow downward drag
      if translation.y > 0 {
        transform = CGAffineTransform(translationX: 0, y: translation.y)
      }
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: superview).y
      // Dismiss with gentle swipe down (20pt or fast velocity)
      if translation.y > 20 || velocity > 300 {
        // Dismiss
        onDismiss()
      } else {
        // Bounce back
        UIView.animate(
          springDuration: 0.25,
          bounce: 0.3,
          initialSpringVelocity: 0,
          delay: 0,
          options: []
        ) {
          self.transform = .identity
        }
      }
    default:
      break
    }
  }
}
