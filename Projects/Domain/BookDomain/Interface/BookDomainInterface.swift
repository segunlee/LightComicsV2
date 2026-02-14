import Foundation

// MARK: - BookDomainInterface

public protocol BookDomainInterface: Sendable {
  // MARK: - ReadInfo CRUD

  func fetchReadInfo(identifier: String) throws -> ReadInfo?
  func fetchReadInfo(pathString: String) throws -> ReadInfo?
  func fetchReadInfoOrCreate(identifier: String, pathString: String, pathExtension: String) throws -> ReadInfo
  func fetchAllReadInfos() throws -> [ReadInfo]
  func fetchUnfinishedReadInfos() throws -> [ReadInfo]
  func fetchFinishedReadInfos() throws -> [ReadInfo]
  func fetchRecentReadInfo() throws -> ReadInfo?
  func fetchMigrationCandidates() throws -> [ReadInfo]

  func insertReadInfo(_ readInfo: ReadInfo) throws
  func updateReadInfo(_ readInfo: ReadInfo) throws
  func softDeleteReadInfo(identifier: String) throws
  func hardDeleteReadInfo(identifier: String) throws
  func reviveReadInfo(identifier: String) throws

  func updateReadProgress(identifier: String, readIndex: Int) throws
  func updateTotalPage(identifier: String, totalPage: Int) throws
  func updatePageOptions(identifier: String, options: PageOptions) throws
  func updateFilePath(identifier: String, pathString: String, pathExtension: String, bookmarkData: Data?) throws
  func markAsRead(identifier: String) throws

  func deleteUnresolvedReadInfos(identifiers: [String]) throws
  func deleteAll() throws

  // MARK: - Bookmark CRUD

  func fetchBookmarks(readInfoId: String) throws -> [Bookmark]
  func fetchBookmark(readInfoId: String, hintIdentifier: String) throws -> Bookmark?
  func addBookmark(readInfoId: String, hintIdentifier: String) throws
  func deleteBookmark(readInfoId: String, hintIdentifier: String) throws
  func deleteAllBookmarks(readInfoId: String) throws

  // MARK: - Image Index

  func fetchImageIndexes(readInfoId: String) throws -> [ImageIndex]
  func updateImageIndexes(readInfoId: String, indexes: [ImageIndex]) throws

  // MARK: - String Index

  func fetchStringIndexes(readInfoId: String) throws -> [StringIndex]
  func updateStringIndexes(readInfoId: String, indexes: [StringIndex]) throws
  func deleteStringIndexes(readInfoId: String) throws
}

// MARK: - ReadInfo

public struct ReadInfo: Sendable, Identifiable {
  public let id: String
  public var pathString: String?
  public var pathExtension: String?
  public var bookmarkData: Data?
  public var readIndex: Int
  public var totalPage: Int
  public var pageOptions: PageOptions
  public var readDate: Date?
  public var createDate: Date
  public var isRead: Bool
  public var isDeleted: Bool
  public var imageCut: Int
  public var imageContentMode: Int
  public var imageFilter: Int
  public var stringEncoding: Int
  public var stringIndexSentence: String
  public var isLightProviderFile: Bool
  public var linkAccountUUID: String?

  public init(
    id: String,
    pathString: String? = nil,
    pathExtension: String? = nil,
    bookmarkData: Data? = nil,
    readIndex: Int = 0,
    totalPage: Int = 0,
    pageOptions: PageOptions = PageOptions(),
    readDate: Date? = nil,
    createDate: Date = Date(),
    isRead: Bool = false,
    isDeleted: Bool = false,
    imageCut: Int = 0,
    imageContentMode: Int = 0,
    imageFilter: Int = 0,
    stringEncoding: Int = 0,
    stringIndexSentence: String = "",
    isLightProviderFile: Bool = false,
    linkAccountUUID: String? = nil
  ) {
    self.id = id
    self.pathString = pathString
    self.pathExtension = pathExtension
    self.bookmarkData = bookmarkData
    self.readIndex = readIndex
    self.totalPage = totalPage
    self.pageOptions = pageOptions
    self.readDate = readDate
    self.createDate = createDate
    self.isRead = isRead
    self.isDeleted = isDeleted
    self.imageCut = imageCut
    self.imageContentMode = imageContentMode
    self.imageFilter = imageFilter
    self.stringEncoding = stringEncoding
    self.stringIndexSentence = stringIndexSentence
    self.isLightProviderFile = isLightProviderFile
    self.linkAccountUUID = linkAccountUUID
  }
}

// MARK: - PageOptions

public struct PageOptions: Sendable {
  public var transition: Int
  public var display: Int
  public var direction: Int
  public var contentMode: Int

  public init(transition: Int = 0, display: Int = 0, direction: Int = 0, contentMode: Int = 0) {
    self.transition = transition
    self.display = display
    self.direction = direction
    self.contentMode = contentMode
  }
}

// MARK: - Bookmark

public struct Bookmark: Sendable, Identifiable {
  public let id: Int64
  public let readInfoId: String
  public let createDate: Date
  public let hintIdentifier: String

  public init(id: Int64, readInfoId: String, createDate: Date, hintIdentifier: String) {
    self.id = id
    self.readInfoId = readInfoId
    self.createDate = createDate
    self.hintIdentifier = hintIdentifier
  }
}

// MARK: - ImageIndex

public struct ImageIndex: Sendable {
  public let imageCut: Int
  public var items: [ImageIndexItem]

  public init(imageCut: Int, items: [ImageIndexItem] = []) {
    self.imageCut = imageCut
    self.items = items
  }
}

// MARK: - ImageIndexItem

public struct ImageIndexItem: Sendable {
  public let elementIndex: Int
  public let modifyIndex: Int
  public let isFirst: Bool
  public let size: String

  public init(elementIndex: Int, modifyIndex: Int, isFirst: Bool = false, size: String = "0|0") {
    self.elementIndex = elementIndex
    self.modifyIndex = modifyIndex
    self.isFirst = isFirst
    self.size = size
  }
}

// MARK: - StringIndex

public struct StringIndex: Sendable {
  public let size: String
  public let attributes: String
  public var ranges: [String]

  public init(size: String, attributes: String, ranges: [String] = []) {
    self.size = size
    self.attributes = attributes
    self.ranges = ranges
  }
}
