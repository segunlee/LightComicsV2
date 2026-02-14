import Combine
import Logger
import PDFKit

// MARK: - ReaderPDFDataProvider

@MainActor
final class ReaderPDFDataProvider: ReaderDataProvider {
  // MARK: - Properties

  var options: ReaderOptions
  let filePath: String
  private(set) var elementsCount: Int = 0
  private(set) var fetchCompleted: Bool = false
  let progress = CurrentValueSubject<Float, Never>(0)
  var password: String?

  private var pdfDocument: PDFDocument?

  // MARK: - Initialization

  init(filePath: String) {
    self.filePath = filePath
    options = ReaderOptions(contentType: .pdf)
  }

  // MARK: - ReaderDataProvider

  func fetch() async throws {
    let url = URL(fileURLWithPath: filePath)
    let fileName = url.lastPathComponent
    guard let document = PDFDocument(url: url) else {
      Log.error("Failed to load PDF: \(fileName)")
      throw ReaderDataProviderError.pdfLoadFailure
    }

    if document.isLocked {
      if let password, document.unlock(withPassword: password) {
        Log.debug("PDF unlocked with password: \(fileName)")
      } else {
        Log.error("PDF locked and cannot unlock: \(fileName)")
        throw ReaderDataProviderError.pdfLoadFailure
      }
    }

    pdfDocument = document
    elementsCount = document.pageCount
    fetchCompleted = true
    progress.send(1.0)
    Log.info("PDF loaded: \(fileName), \(document.pageCount) pages")
  }

  func element(at index: Int) async throws -> ReaderContentElement {
    guard let pdfDocument else { throw ReaderDataProviderError.pdfLoadFailure }
    guard index >= 0, index < pdfDocument.pageCount else { throw ReaderDataProviderError.notFoundIndex }
    guard let page = pdfDocument.page(at: index)?.copy() as? PDFPage else {
      throw ReaderDataProviderError.notFoundIndex
    }

    let singlePageDoc = PDFDocument()
    singlePageDoc.insert(page, at: 0)
    return .pdf(singlePageDoc)
  }

  func invalidate() {
    pdfDocument = nil
    elementsCount = 0
    fetchCompleted = false
  }

  // MARK: - Memory Management

  func recreatePDFDocument() {
    guard fetchCompleted else { return }
    Log.debug("Recreating PDF document after memory warning")
    let url = URL(fileURLWithPath: filePath)
    guard let document = PDFDocument(url: url) else {
      Log.error("Failed to recreate PDF document")
      return
    }

    if document.isLocked, let password {
      document.unlock(withPassword: password)
    }

    pdfDocument = document
    Log.debug("PDF document recreated successfully")
  }
}
