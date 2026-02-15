// MARK: - EmptyReason

public enum EmptyReason: Sendable {
  case noData
  case noSearchResults
  case error(description: String)
  case custom(animationName: String? = nil, message: String, description: String? = nil)

  // MARK: - Properties

  var animationName: String? {
    switch self {
    case .noData:
      "empty_box"
    case .noSearchResults:
      "no_search_results"
    case .error:
      "error_warning"
    case .custom(let animationName, _, _):
      animationName
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
