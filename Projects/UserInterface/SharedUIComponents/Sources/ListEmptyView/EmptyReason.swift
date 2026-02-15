import UIKit

// MARK: - EmptyReason

public enum EmptyReason: Sendable {
  case noData
  case noSearchResults
  case error(description: String)
  case custom(imageName: String, message: String, description: String? = nil)

  // MARK: - Properties

  var image: UIImage? {
    switch self {
    case .noData:
      UIImage(systemName: "tray")
    case .noSearchResults:
      UIImage(systemName: "magnifyingglass")
    case .error:
      UIImage(systemName: "exclamationmark.triangle")
    case .custom(let imageName, _, _):
      UIImage(systemName: imageName) ?? UIImage(named: imageName)
    }
  }

  var message: String {
    switch self {
    case .noData:
      SharedStrings.emptyNoDataMessage
    case .noSearchResults:
      SharedStrings.emptyNoSearchResultsMessage
    case .error:
      SharedStrings.emptyErrorMessage
    case .custom(_, let message, _):
      message
    }
  }

  var description: String? {
    switch self {
    case .noData:
      SharedStrings.emptyNoDataDescription
    case .noSearchResults:
      SharedStrings.emptyNoSearchResultsDescription
    case .error(let description):
      description
    case .custom(_, _, let description):
      description
    }
  }
}
