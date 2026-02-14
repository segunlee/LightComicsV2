import Foundation
import ReaderFeatureInterface

// MARK: - ReaderViewState

struct ReaderViewState {
  var currentIndex: Int = 0
  var totalPages: Int = 0
  var options: ReaderOptions
  var speechState: ReaderSpeechState = .stop
  var errorMessage: String?
  var loadingState: ReaderLoadingState = .idle
  var fetchProgress: Float = 0
}

// MARK: - ReaderLoadingState

enum ReaderLoadingState {
  case idle
  case loading
  case loaded
  case error(String)
}

// MARK: - ReaderViewAction

enum ReaderViewAction {
  case loadPage
  case scrollNext
  case scrollPrevious
  case scrollTo(Int)
  case updateOptions(ReaderOptions)
  case changeSpeechState(ReaderSpeechState)
  case updateCurrentIndex(Int)
  case updateTotalPages(Int)
  case fetchContent
  case refetchForTextRotation(CGSize)
}
