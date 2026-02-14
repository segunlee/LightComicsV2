import UIKit

// MARK: - ListEmptyView

@MainActor
public final class ListEmptyView: UIView {

  // MARK: - Properties

  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.tintColor = .label
    imageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      imageView.widthAnchor.constraint(equalToConstant: 80),
      imageView.heightAnchor.constraint(equalToConstant: 80)
    ])
    return imageView
  }()

  private let messageLabel: UILabel = {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .headline)
    label.textColor = .label
    label.textAlignment = .center
    label.numberOfLines = 0
    return label
  }()

  private let descriptionLabel: UILabel = {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .secondaryLabel
    label.textAlignment = .center
    label.numberOfLines = 0
    return label
  }()

  private let stackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.alignment = .center
    stackView.spacing = 8
    stackView.translatesAutoresizingMaskIntoConstraints = false
    return stackView
  }()

  // MARK: - Initialization

  public init(reason: EmptyReason) {
    super.init(frame: .zero)
    setupUI(reason: reason)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Private Methods

  private func setupUI(reason: EmptyReason) {
    imageView.image = reason.image
    messageLabel.text = reason.message

    stackView.addArrangedSubview(imageView)
    stackView.addArrangedSubview(messageLabel)

    if let description = reason.description {
      descriptionLabel.text = description
      stackView.addArrangedSubview(descriptionLabel)
    }

    addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
      stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
      stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 40),
      stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -40)
    ])
  }
}
