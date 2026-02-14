import Foundation

// MARK: - ReaderContentType

enum ReaderContentType: Sendable {
  case image
  case pdf
  case text
}

// MARK: - ReaderTransition

enum ReaderTransition: Int, CaseIterable, Sendable {
  case paging = 0
  case pageCurl
  case naturalScroll
  case none

  var isPaging: Bool { self == .paging }
}

// MARK: - ReaderDirection

enum ReaderDirection: Int, CaseIterable, Sendable {
  case toRight = 0
  case toLeft
  case toBottom
}

// MARK: - ReaderDisplay

enum ReaderDisplay: Int, CaseIterable, Sendable {
  case single = 0
  case double

  var isDouble: Bool { self == .double }
}

// MARK: - ReaderImageContentMode

enum ReaderImageContentMode: Int, CaseIterable, Sendable {
  case aspectFit = 0
  case aspectFill
  case scrollToFit
}

// MARK: - ReaderImageCutMode

enum ReaderImageCutMode: Int, CaseIterable, Sendable {
  case none = 0
  case cut
  case cutAndReverse
}

// MARK: - ReaderImageFilterMode

enum ReaderImageFilterMode: Int, CaseIterable, Sendable {
  case none = 0
  case contrast
  case inverted
  case grayScale
}

// MARK: - ReaderScrollCommand

enum ReaderScrollCommand: Sendable {
  case next
  case previous
}

// MARK: - ReaderSpeechState

enum ReaderSpeechState: Sendable {
  case speak
  case pause
  case stop
}
