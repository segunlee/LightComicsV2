import UIKit

// MARK: - ToastManager

public typealias Toast = ToastManager

@MainActor
public final class ToastManager {
  // MARK: - Properties

  public static let shared = ToastManager()

  private var toastWindow: UIWindow?
  private var toastView: LiquidGlassToastUIView?
  private var dismissTask: Task<Void, Never>?

  // MARK: - Initialization

  private init() {}

  // MARK: - Public Methods
  
  public static func show(_ configuration: ToastConfiguration) {
    shared.show(configuration)
  }

  public func show(_ configuration: ToastConfiguration) {
    // Cancel any existing dismiss task
    dismissTask?.cancel()

    // Remove existing toast
    if toastView != nil {
      dismiss(animated: false)
    }

    // Setup window and toast view
    setupToastWindow(with: configuration)

    // Auto-dismiss after duration
    dismissTask = Task { [weak self] in
      try? await Task.sleep(nanoseconds: UInt64(configuration.priority.duration * 1_000_000_000))
      guard !Task.isCancelled else { return }
      self?.dismiss(animated: true)
    }
  }

  public func dismiss(animated: Bool = true) {
    dismissTask?.cancel()
    dismissTask = nil

    guard let toastView else { return }

    if animated {
      // Animate down
      UIView.animate(
        springDuration: 0.25,
        bounce: 0.2,
        initialSpringVelocity: 0,
        delay: 0,
        options: []
      ) {
        toastView.transform = CGAffineTransform(translationX: 0, y: toastView.bounds.height + 100)
        toastView.alpha = 0
      } completion: { [weak self] _ in
        self?.cleanupToast()
      }
    } else {
      cleanupToast()
    }
  }

  // MARK: - Private Methods

  private func setupToastWindow(with configuration: ToastConfiguration) {
    // Find active window scene
    guard let windowScene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first(where: { $0.activationState == .foregroundActive }) else {
      return
    }

    // Create toast view
    let toast = LiquidGlassToastUIView(
      configuration: configuration,
      onDismiss: { [weak self] in
        self?.dismiss(animated: true)
      }
    )
    toast.translatesAutoresizingMaskIntoConstraints = false
    toast.alpha = 0
    toast.transform = CGAffineTransform(translationX: 0, y: 100)

    // Create window if needed
    if toastWindow == nil {
      let window = PassthroughWindow(windowScene: windowScene)
      window.backgroundColor = .clear
      window.windowLevel = .alert + 1
      window.frame = windowScene.effectiveGeometry.coordinateSpace.bounds
      toastWindow = window
    }

    guard let window = toastWindow else { return }

    // Create container view controller if needed
    if window.rootViewController == nil {
      let containerVC = PassthroughViewController()
      window.rootViewController = containerVC
    }

    guard let containerView = window.rootViewController?.view else { return }

    // Add toast to window
    containerView.addSubview(toast)

    NSLayoutConstraint.activate([
      toast.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      toast.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
      toast.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -60)
    ])

    toastView = toast
    window.isHidden = false

    // Animate in
    UIView.animate(
      springDuration: 0.25,
      bounce: 0.25,
      initialSpringVelocity: 0.5,
      delay: 0,
      options: []
    ) {
      toast.alpha = 1
      toast.transform = .identity
    }
  }

  private func cleanupToast() {
    toastView?.removeFromSuperview()
    toastView = nil
    toastWindow?.isHidden = true
  }
}

// MARK: - PassthroughWindow

/// Window that passes touches through to the underlying window
private class PassthroughWindow: UIWindow {
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let hitView = super.hitTest(point, with: event)
    // If hit view is the root view or window itself, pass through
    if hitView == rootViewController?.view || hitView == self {
      return nil
    }
    return hitView
  }
}

// MARK: - PassthroughViewController

/// View controller that allows touches to pass through
private class PassthroughViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
  }
}
