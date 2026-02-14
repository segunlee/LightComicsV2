import BookDomainInterface

// MARK: - ReaderUseCase

protocol ReaderUseCase: Sendable {
  func fetchReadInfo(identifier: String) throws -> ReadInfo?
  func fetchReadInfoOrCreate(identifier: String, pathString: String, pathExtension: String) throws -> ReadInfo
  func updateReadProgress(identifier: String, readIndex: Int) throws
  func updateTotalPage(identifier: String, totalPage: Int) throws
  func updatePageOptions(identifier: String, options: PageOptions) throws
  func fetchImageIndexes(identifier: String) throws -> [ImageIndex]
  func updateImageIndexes(identifier: String, indexes: [ImageIndex]) throws
  func fetchStringIndexes(identifier: String) throws -> [StringIndex]
  func updateStringIndexes(identifier: String, indexes: [StringIndex]) throws
}

// MARK: - ReaderUseCaseImpl

final class ReaderUseCaseImpl: ReaderUseCase {
  private let bookDomain: BookDomainInterface

  init(bookDomain: BookDomainInterface) {
    self.bookDomain = bookDomain
  }

  func fetchReadInfo(identifier: String) throws -> ReadInfo? {
    try bookDomain.fetchReadInfo(identifier: identifier)
  }

  func fetchReadInfoOrCreate(identifier: String, pathString: String, pathExtension: String) throws -> ReadInfo {
    try bookDomain.fetchReadInfoOrCreate(identifier: identifier, pathString: pathString, pathExtension: pathExtension)
  }

  func updateReadProgress(identifier: String, readIndex: Int) throws {
    try bookDomain.updateReadProgress(identifier: identifier, readIndex: readIndex)
  }

  func updateTotalPage(identifier: String, totalPage: Int) throws {
    try bookDomain.updateTotalPage(identifier: identifier, totalPage: totalPage)
  }

  func updatePageOptions(identifier: String, options: PageOptions) throws {
    try bookDomain.updatePageOptions(identifier: identifier, options: options)
  }

  func fetchImageIndexes(identifier: String) throws -> [ImageIndex] {
    try bookDomain.fetchImageIndexes(readInfoId: identifier)
  }

  func updateImageIndexes(identifier: String, indexes: [ImageIndex]) throws {
    try bookDomain.updateImageIndexes(readInfoId: identifier, indexes: indexes)
  }

  func fetchStringIndexes(identifier: String) throws -> [StringIndex] {
    try bookDomain.fetchStringIndexes(readInfoId: identifier)
  }

  func updateStringIndexes(identifier: String, indexes: [StringIndex]) throws {
    try bookDomain.updateStringIndexes(readInfoId: identifier, indexes: indexes)
  }
}
