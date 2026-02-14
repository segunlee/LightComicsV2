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
      "No Data"
    case .noSearchResults:
      "No Search Results"
    case .error:
      "Error occurred"
    case .custom(_, let message, _):
      message
    }
  }

  var description: String? {
    switch self {
    case .noData:
      "There's nothing here yet."
    case .noSearchResults:
      "No matches for your search."
    case .error(let description):
      description
    case .custom(_, _, let description):
      description
    }
  }
}
