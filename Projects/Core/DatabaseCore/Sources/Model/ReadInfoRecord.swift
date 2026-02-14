import Foundation
import GRDB

// MARK: - ReadInfoRecord

public struct ReadInfoRecord: Codable, Identifiable, FetchableRecord, PersistableRecord, Sendable {
  public static let databaseTableName = "readInfo"

  // MARK: - Properties

  public var id: String
  public var pathString: String?
  public var pathExtension: String?
  public var bookmarkData: Data?
  public var readIndex: Int
  public var totalPage: Int
  public var pageOptionTransition: Int
  public var pageOptionDisplay: Int
  public var pageOptionDirection: Int
  public var pageOptionContentMode: Int
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

  // MARK: - Initialization

  public init(
    id: String,
    pathString: String? = nil,
    pathExtension: String? = nil,
    bookmarkData: Data? = nil,
    readIndex: Int = 0,
    totalPage: Int = 0,
    pageOptionTransition: Int = 0,
    pageOptionDisplay: Int = 0,
    pageOptionDirection: Int = 0,
    pageOptionContentMode: Int = 0,
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
    self.pageOptionTransition = pageOptionTransition
    self.pageOptionDisplay = pageOptionDisplay
    self.pageOptionDirection = pageOptionDirection
    self.pageOptionContentMode = pageOptionContentMode
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
