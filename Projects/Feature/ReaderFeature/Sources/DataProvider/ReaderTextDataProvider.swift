import Combine
import CoreText
import Foundation
import Logger
import UIKit

// MARK: - ReaderTextPageInfo

struct ReaderTextPageInfo: Sendable {
  let size: CGSize
  let attributesKey: String
  var ranges: [String]
}

// MARK: - ReaderTextDataProvider

@MainActor
final class ReaderTextDataProvider: ReaderDataProvider {
  // MARK: - Properties

  var options: ReaderOptions
  let filePath: String
  var elementsCount: Int { pageInfo?.ranges.count ?? 0 }
  private(set) var fetchCompleted: Bool = false
  let progress = CurrentValueSubject<Float, Never>(0)
  var password: String?

  var canvasSize: CGSize = .zero
  var stringEncoding: Int = 0

  private var fullText: NSAttributedString?
  private var pageInfo: ReaderTextPageInfo?
  private var beforeRotateFirstLineText: String?
  private var beforeRotateIndex: Int?

  // MARK: - Initialization

  init(filePath: String) {
    self.filePath = filePath
    options = ReaderOptions(contentType: .text)
  }

  // MARK: - ReaderDataProvider

  func fetch() async throws {
    let url = URL(fileURLWithPath: filePath)
    let fileName = url.lastPathComponent
    let data = try Data(contentsOf: url)
    Log.debug("Text file loaded: \(fileName), \(data.count) bytes")

    let encoding: String.Encoding
    if stringEncoding != 0 {
      encoding = String.Encoding(rawValue: UInt(stringEncoding))
      Log.debug("Using saved encoding: \(stringEncoding)")
    } else {
      encoding = detectEncoding(data: data)
      Log.debug("Detected encoding: \(encoding)")
    }

    guard let text = String(data: data, encoding: encoding) else {
      Log.error("Failed to decode text: \(fileName)")
      throw ReaderDataProviderError.plainTextConvertFailure
    }

    guard !text.isEmpty else {
      Log.error("Empty text file: \(fileName)")
      throw ReaderDataProviderError.emptyContent(filePath)
    }

    let fontSize: CGFloat = 16
    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: fontSize),
      .foregroundColor: UIColor.label
    ]
    fullText = NSAttributedString(string: text, attributes: attributes)

    guard canvasSize.width > 0, canvasSize.height > 0 else {
      Log.debug("Canvas size not ready, deferring pagination")
      fetchCompleted = true
      progress.send(1.0)
      return
    }

    let attributesKey = "\(canvasSize.width)|\(canvasSize.height)|\(fontSize)"
    guard let fullText else {
      fetchCompleted = true
      progress.send(1.0)
      return
    }
    let ranges = calculatePages(attributedString: fullText, canvasSize: canvasSize)

    pageInfo = ReaderTextPageInfo(size: canvasSize, attributesKey: attributesKey, ranges: ranges)
    fetchCompleted = true
    progress.send(1.0)
    Log.info("Text loaded: \(fileName), \(text.count) chars, \(ranges.count) pages")
  }

  func element(at index: Int) async throws -> ReaderContentElement {
    guard let fullText, let pageInfo else { throw ReaderDataProviderError.plainTextConvertFailure }
    guard index >= 0, index < pageInfo.ranges.count else { throw ReaderDataProviderError.notFoundIndex }

    let rangeString = pageInfo.ranges[index]
    let nsRange = NSRangeFromString(rangeString)
    let clampedLength = min(nsRange.length, fullText.length - nsRange.location)
    guard clampedLength > 0 else { throw ReaderDataProviderError.notFoundIndex }

    let substring = fullText.attributedSubstring(from: NSRange(location: nsRange.location, length: clampedLength))
    return .text(substring)
  }

  func invalidate() {
    fullText = nil
    pageInfo = nil
    fetchCompleted = false
  }

  // MARK: - Rotation Support

  func catchBeforeRotateInfo(at index: Int) {
    guard let fullText, let pageInfo, index < pageInfo.ranges.count else { return }
    beforeRotateIndex = index
    let nsRange = NSRangeFromString(pageInfo.ranges[index])
    let clampedLength = min(nsRange.length, fullText.length - nsRange.location)
    guard clampedLength > 0 else { return }
    let substring = fullText.attributedSubstring(from: NSRange(location: nsRange.location, length: clampedLength))
    beforeRotateFirstLineText = substring.string.components(separatedBy: .newlines).first
  }

  func recalculateAfterRotation(newSize: CGSize) -> Int {
    guard let fullText else { return 0 }

    canvasSize = newSize
    let fontSize: CGFloat = 16
    let attributesKey = "\(newSize.width)|\(newSize.height)|\(fontSize)"
    let ranges = calculatePages(attributedString: fullText, canvasSize: newSize)

    pageInfo = ReaderTextPageInfo(size: newSize, attributesKey: attributesKey, ranges: ranges)

    guard let beforeText = beforeRotateFirstLineText else { return 0 }

    for (i, rangeStr) in ranges.enumerated() {
      let nsRange = NSRangeFromString(rangeStr)
      let clampedLength = min(nsRange.length, fullText.length - nsRange.location)
      guard clampedLength > 0 else { continue }
      let substring = fullText.attributedSubstring(from: NSRange(location: nsRange.location, length: clampedLength))
      if substring.string.contains(beforeText) {
        return i
      }
    }

    return beforeRotateIndex ?? 0
  }

  // MARK: - Saved Page Info

  func currentPageInfo() -> ReaderTextPageInfo? {
    pageInfo
  }

  func restorePageInfo(_ info: ReaderTextPageInfo) {
    pageInfo = info
  }

  // MARK: - Private Methods

  private func calculatePages(attributedString: NSAttributedString, canvasSize: CGSize) -> [String] {
    var ranges: [String] = []
    let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
    let totalLength = attributedString.length
    var offset = 0

    while offset < totalLength {
      let path = CGPath(rect: CGRect(origin: .zero, size: canvasSize), transform: nil)
      let frameRef = CTFramesetterCreateFrame(
        framesetter,
        CFRangeMake(offset, 0),
        path,
        nil
      )
      let visibleRange = CTFrameGetVisibleStringRange(frameRef)
      guard visibleRange.length > 0 else { break }

      ranges.append(NSStringFromRange(NSRange(location: offset, length: visibleRange.length)))
      offset += visibleRange.length
    }

    return ranges
  }

  private func detectEncoding(data: Data) -> String.Encoding {
    let encodings: [String.Encoding] = [.utf8, .japaneseEUC, .shiftJIS, .isoLatin1, .windowsCP1252]
    for encoding in encodings where String(data: data, encoding: encoding) != nil {
      return encoding
    }
    return .utf8
  }
}
