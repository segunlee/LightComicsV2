import BookDomainInterface
import Combine
import Foundation
import Logger
import ReaderFeatureInterface

// MARK: - ReaderViewModelDelegate

@MainActor
protocol ReaderViewModelDelegate: AnyObject {
  func readerViewModel(_ viewModel: ReaderViewModel, didRequestScrollTo index: Int, animated: Bool)
  func readerViewModelDidUpdateOptions(_ viewModel: ReaderViewModel)
}

// MARK: - ReaderViewModel

@MainActor
final class ReaderViewModel: ObservableObject {
  // MARK: - Properties

  @Published private(set) var state: ReaderViewState
  weak var delegate: ReaderViewModelDelegate?

  private let useCase: ReaderUseCase
  private let filePath: String
  private let identifier: String
  let dataProvider: ReaderDataProvider?
  private var progressCancellable: AnyCancellable?

  // MARK: - Initialization

  init(useCase: ReaderUseCase, contentType: ReaderContentType, filePath: String, dataProvider: ReaderDataProvider? = nil) {
    self.useCase = useCase
    self.filePath = filePath
    identifier = filePath
    self.dataProvider = dataProvider
    state = ReaderViewState(options: ReaderOptions(contentType: contentType))

    Log.debug("ReaderViewModel init: \(URL(fileURLWithPath: filePath).lastPathComponent), type=\(contentType)")
    loadReadInfo()
  }

  // MARK: - Actions

  func send(_ action: ReaderViewAction) {
    switch action {
    case .loadPage:
      loadReadInfo()
    case .scrollNext:
      delegate?.readerViewModel(self, didRequestScrollTo: nextIndex(), animated: true)
    case .scrollPrevious:
      delegate?.readerViewModel(self, didRequestScrollTo: previousIndex(), animated: true)
    case let .scrollTo(index):
      delegate?.readerViewModel(self, didRequestScrollTo: index, animated: true)
    case let .updateOptions(options):
      updateOptions(options)
    case let .changeSpeechState(speechState):
      state.speechState = speechState
    case let .updateCurrentIndex(index):
      updateCurrentIndex(index)
    case let .updateTotalPages(total):
      state.totalPages = total
      saveTotalPage(total)
    case .fetchContent:
      Task { await fetchContent() }
    case let .refetchForTextRotation(newSize):
      handleTextRotation(newSize: newSize)
    }
  }

  // MARK: - Content Loading

  func loadElement(at index: Int) async throws -> ReaderContentElement {
    guard let dataProvider else { throw ReaderDataProviderError.unsupported }
    return try await dataProvider.element(at: index)
  }

  private func fetchContent() async {
    guard let dataProvider else { return }
    state.loadingState = .loading
    Log.info("Fetching content...")

    progressCancellable = dataProvider.progress
      .receive(on: RunLoop.main)
      .sink { [weak self] value in
        self?.state.fetchProgress = value
      }

    dataProvider.options = state.options

    if let textProvider = dataProvider as? ReaderTextDataProvider {
      textProvider.stringEncoding = loadStringEncoding()
    }

    do {
      try await dataProvider.fetch()
      state.totalPages = dataProvider.elementsCount
      state.loadingState = .loaded
      saveTotalPage(state.totalPages)
      Log.info("Content loaded: \(state.totalPages) pages")

      let savedIndex = state.currentIndex
      if savedIndex > 0, savedIndex < state.totalPages {
        Log.debug("Restoring saved position: page \(savedIndex)")
        delegate?.readerViewModel(self, didRequestScrollTo: savedIndex, animated: false)
      } else if let dirProvider = dataProvider as? ReaderImageDirectoryDataProvider, dirProvider.initialIndex > 0 {
        state.currentIndex = dirProvider.initialIndex
        Log.debug("Starting at tapped image index: \(dirProvider.initialIndex)")
        delegate?.readerViewModel(self, didRequestScrollTo: dirProvider.initialIndex, animated: false)
      }
    } catch {
      state.loadingState = .error(error.localizedDescription)
      Log.error("Failed to fetch content: \(error)")
    }

    progressCancellable = nil
  }

  // MARK: - Text Rotation

  private func handleTextRotation(newSize: CGSize) {
    guard let textProvider = dataProvider as? ReaderTextDataProvider else { return }
    Log.debug("Text rotation: \(newSize.width)x\(newSize.height), from page \(state.currentIndex)")
    textProvider.catchBeforeRotateInfo(at: state.currentIndex)
    let newIndex = textProvider.recalculateAfterRotation(newSize: newSize)
    state.totalPages = textProvider.elementsCount
    saveTotalPage(state.totalPages)
    Log.debug("Text rotation complete: \(state.totalPages) pages, restored to page \(newIndex)")
    delegate?.readerViewModel(self, didRequestScrollTo: newIndex, animated: false)
  }

  // MARK: - Options Update with DataProvider

  private func handleOptionsChangeForDataProvider(old: ReaderOptions, new: ReaderOptions) {
    guard let dataProvider else { return }
    dataProvider.options = new

    if new.contentType == .image, old.imageCutMode != new.imageCutMode {
      Log.debug("Image cut mode changed: \(old.imageCutMode) -> \(new.imageCutMode)")
      if let imageProvider = dataProvider as? ReaderImageDataProvider {
        imageProvider.rebuildPageIndexes()
        state.totalPages = imageProvider.elementsCount
        saveTotalPage(state.totalPages)
      }
    }

    if new.contentType == .image, old.imageFilterMode != new.imageFilterMode {
      Log.debug("Image filter changed: \(old.imageFilterMode) -> \(new.imageFilterMode)")
      if let imageProvider = dataProvider as? ReaderImageDataProvider {
        imageProvider.rebuildPageIndexes()
        state.totalPages = imageProvider.elementsCount
      }
    }
  }

  // MARK: - Persistence Helpers

  func saveCurrentState() {
    Log.debug("Saving reader state: page \(state.currentIndex)/\(state.totalPages)")
    saveReadProgress(state.currentIndex)
    saveImageIndexes()
    saveStringIndexes()
  }

  private func saveImageIndexes() {
    guard let imageProvider = dataProvider as? ReaderImageDataProvider else { return }
    let pageIndexes = imageProvider.currentPageIndexes()
    let imageIndex = ImageIndex(
      imageCut: state.options.imageCutMode.rawValue,
      items: pageIndexes.map {
        ImageIndexItem(
          elementIndex: $0.elementIndex,
          modifyIndex: $0.modifyIndex,
          isFirst: $0.isFirst,
          size: "\(Int($0.size.width))|\(Int($0.size.height))"
        )
      }
    )
    do {
      try useCase.updateImageIndexes(identifier: identifier, indexes: [imageIndex])
    } catch {
      Log.error("Failed to save image indexes: \(error)")
    }
  }

  private func saveStringIndexes() {
    guard let textProvider = dataProvider as? ReaderTextDataProvider,
          let pageInfo = textProvider.currentPageInfo() else { return }
    let stringIndex = StringIndex(
      size: "\(Int(pageInfo.size.width))|\(Int(pageInfo.size.height))",
      attributes: pageInfo.attributesKey,
      ranges: pageInfo.ranges
    )
    do {
      try useCase.updateStringIndexes(identifier: identifier, indexes: [stringIndex])
    } catch {
      Log.error("Failed to save string indexes: \(error)")
    }
  }

  private func loadStringEncoding() -> Int {
    do {
      let readInfo = try useCase.fetchReadInfo(identifier: identifier)
      return readInfo?.stringEncoding ?? 0
    } catch {
      return 0
    }
  }

  // MARK: - Private Methods

  private func loadReadInfo() {
    let pathExtension = URL(fileURLWithPath: filePath).pathExtension
    do {
      let readInfo = try useCase.fetchReadInfoOrCreate(
        identifier: identifier, pathString: filePath, pathExtension: pathExtension
      )
      state.currentIndex = readInfo.readIndex
      state.totalPages = readInfo.totalPage

      let pageOptions = readInfo.pageOptions
      state.options.transition = ReaderTransition(rawValue: pageOptions.transition) ?? .paging
      state.options.display = ReaderDisplay(rawValue: pageOptions.display) ?? .single
      state.options.direction = ReaderDirection(rawValue: pageOptions.direction) ?? .toRight
      state.options.imageContentMode = ReaderImageContentMode(rawValue: pageOptions.contentMode) ?? .aspectFit
      state.options.imageCutMode = ReaderImageCutMode(rawValue: readInfo.imageCut) ?? .none
      state.options.imageFilterMode = ReaderImageFilterMode(rawValue: readInfo.imageFilter) ?? .none

      state.errorMessage = nil
      Log.debug(
        "ReadInfo loaded: page \(readInfo.readIndex)/\(readInfo.totalPage), "
          + "transition=\(state.options.transition), display=\(state.options.display)"
      )
    } catch {
      state.errorMessage = error.localizedDescription
      Log.error("Failed to load read info: \(error)")
    }
  }

  private func updateCurrentIndex(_ index: Int) {
    guard state.currentIndex != index else { return }
    state.currentIndex = index
    saveReadProgress(index)
  }

  private func updateOptions(_ options: ReaderOptions) {
    let oldOptions = state.options
    state.options = options
    savePageOptions(options)
    handleOptionsChangeForDataProvider(old: oldOptions, new: options)
    delegate?.readerViewModelDidUpdateOptions(self)
  }

  private func saveReadProgress(_ index: Int) {
    do {
      try useCase.updateReadProgress(identifier: identifier, readIndex: index)
    } catch {
      Log.error("Failed to save read progress: \(error)")
    }
  }

  private func saveTotalPage(_ total: Int) {
    do {
      try useCase.updateTotalPage(identifier: identifier, totalPage: total)
    } catch {
      Log.error("Failed to save total page: \(error)")
    }
  }

  private func savePageOptions(_ options: ReaderOptions) {
    let pageOptions = PageOptions(
      transition: options.transition.rawValue,
      display: options.display.rawValue,
      direction: options.direction.rawValue,
      contentMode: options.imageContentMode.rawValue
    )
    do {
      try useCase.updatePageOptions(identifier: identifier, options: pageOptions)
    } catch {
      Log.error("Failed to save page options: \(error)")
    }
  }

  // MARK: - Navigation Helpers

  private func nextIndex() -> Int {
    let increment = state.options.display == .double ? 2 : 1
    return state.currentIndex + increment
  }

  private func previousIndex() -> Int {
    let increment = state.options.display == .double ? 2 : 1
    return state.currentIndex - increment
  }

  func canScroll(command: ReaderScrollCommand) -> Bool {
    let targetIndex = command == .next ? nextIndex() : previousIndex()
    return targetIndex >= 0 && targetIndex < state.totalPages
  }

  func canScroll(at index: Int) -> Bool {
    index >= 0 && index < state.totalPages
  }
}
