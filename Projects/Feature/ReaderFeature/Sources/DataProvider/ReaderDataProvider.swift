import Combine
import PDFKit
import UIKit

// MARK: - ReaderContentElement

enum ReaderContentElement: @unchecked Sendable {
  case image(UIImage)
  case pdf(PDFDocument)
  case text(NSAttributedString)
}

// MARK: - ReaderDataProvider

@MainActor
protocol ReaderDataProvider: AnyObject {
  var options: ReaderOptions { get set }
  var filePath: String { get }
  var elementsCount: Int { get }
  var fetchCompleted: Bool { get }
  var progress: CurrentValueSubject<Float, Never> { get }
  var password: String? { get set }

  func fetch() async throws
  func element(at index: Int) async throws -> ReaderContentElement
  func invalidate()
}

// MARK: - ReaderDataProviderError

enum ReaderDataProviderError: Error, LocalizedError {
  case unsupported
  case notFoundIndex
  case emptyContent(String)
  case fetchInProgress
  case plainTextConvertFailure
  case cancelledByUser
  case pdfLoadFailure

  var errorDescription: String? {
    switch self {
    case .unsupported: return "Unsupported file format"
    case .notFoundIndex: return "Page not found"
    case let .emptyContent(path): return "Empty content: \(path)"
    case .fetchInProgress: return "Fetch already in progress"
    case .plainTextConvertFailure: return "Failed to convert text"
    case .cancelledByUser: return "Cancelled"
    case .pdfLoadFailure: return "Failed to load PDF"
    }
  }
}
