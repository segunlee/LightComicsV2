import Combine
import Logger
import UIKit

// MARK: - ReaderImagePageIndex

struct ReaderImagePageIndex: Sendable {
  let elementIndex: Int
  let modifyIndex: Int
  let isFirst: Bool
  var size: CGSize

  init(elementIndex: Int, modifyIndex: Int, isFirst: Bool = false, size: CGSize = .zero) {
    self.elementIndex = elementIndex
    self.modifyIndex = modifyIndex
    self.isFirst = isFirst
    self.size = size
  }
}

// MARK: - ReaderImageDataProvider

@MainActor
class ReaderImageDataProvider: ReaderDataProvider {
  // MARK: - Properties

  var options: ReaderOptions
  let filePath: String
  var elementsCount: Int { pageIndexes.count }
  private(set) var fetchCompleted: Bool = false
  let progress = CurrentValueSubject<Float, Never>(0)
  var password: String?

  var imagePaths: [String] = []
  private var pageIndexes: [ReaderImagePageIndex] = []
  private let cache = NSCache<NSString, UIImage>()

  static let supportedExtensions: Set<String> = [
    "jpg", "jpeg", "png", "gif", "webp", "bmp", "tiff", "tif", "heic", "heif"
  ]

  // MARK: - Initialization

  init(filePath: String) {
    self.filePath = filePath
    self.options = ReaderOptions(contentType: .image)
    cache.countLimit = 6
  }

  // MARK: - ReaderDataProvider

  func fetch() async throws {
    // Subclasses must override to populate imagePaths, then call completeFetch()
  }

  func completeFetch() {
    buildPageIndexes()
    fetchCompleted = true
    progress.send(1.0)
  }

  func element(at index: Int) async throws -> ReaderContentElement {
    guard index >= 0, index < pageIndexes.count else { throw ReaderDataProviderError.notFoundIndex }

    let pageIndex = pageIndexes[index]
    let cacheKey = "\(pageIndex.elementIndex)_\(pageIndex.isFirst)" as NSString

    if let cached = cache.object(forKey: cacheKey) {
      return .image(cached)
    }

    guard pageIndex.elementIndex < imagePaths.count else { throw ReaderDataProviderError.notFoundIndex }
    let path = imagePaths[pageIndex.elementIndex]

    guard let image = UIImage(contentsOfFile: path) else {
      throw ReaderDataProviderError.emptyContent(path)
    }

    var result = image
    if options.imageCutMode != .none {
      let isReversed = options.imageCutMode == .cutAndReverse
      if pageIndex.isFirst {
        result = (isReversed ? image.cutLeftHalf : image.cutRightHalf) ?? image
      } else {
        result = (isReversed ? image.cutRightHalf : image.cutLeftHalf) ?? image
      }
    }

    if options.imageFilterMode != .none {
      result = result.applyFilter(options.imageFilterMode) ?? result
    }

    cache.setObject(result, forKey: cacheKey)
    return .image(result)
  }

  func invalidate() {
    cache.removeAllObjects()
    imagePaths = []
    pageIndexes = []
    fetchCompleted = false
  }

  // MARK: - Page Index Building

  func rebuildPageIndexes() {
    cache.removeAllObjects()
    buildPageIndexes()
    Log.debug("Page indexes rebuilt: \(pageIndexes.count) pages from \(imagePaths.count) images")
  }

  private func buildPageIndexes() {
    pageIndexes = []

    if options.imageCutMode == .none {
      for index in imagePaths.indices {
        pageIndexes.append(ReaderImagePageIndex(elementIndex: index, modifyIndex: index))
      }
    } else {
      var modifyIndex = 0
      var splitCount = 0
      for (index, path) in imagePaths.enumerated() {
        if let image = UIImage(contentsOfFile: path), image.size.width > image.size.height {
          pageIndexes.append(ReaderImagePageIndex(
            elementIndex: index, modifyIndex: modifyIndex, isFirst: true, size: image.size
          ))
          modifyIndex += 1
          pageIndexes.append(ReaderImagePageIndex(
            elementIndex: index, modifyIndex: modifyIndex, isFirst: false, size: image.size
          ))
          splitCount += 1
        } else {
          pageIndexes.append(ReaderImagePageIndex(
            elementIndex: index, modifyIndex: modifyIndex, size: .zero
          ))
        }
        modifyIndex += 1
      }
      Log.debug("Image cut: \(splitCount) wide images split")
    }
  }

  // MARK: - Saved Index Conversion

  func savedIndexToPageIndex(_ items: [ReaderImagePageIndex]) {
    pageIndexes = items
  }

  func currentPageIndexes() -> [ReaderImagePageIndex] {
    pageIndexes
  }
}
