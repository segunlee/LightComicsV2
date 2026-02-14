import Foundation
import GRDB

// MARK: - BookmarkRecord

public struct BookmarkRecord: Codable, Identifiable, FetchableRecord, MutablePersistableRecord, Sendable {
  public static let databaseTableName = "bookmark"

  // MARK: - Properties

  public var id: Int64?
  public var readInfoId: String
  public var createDate: Date
  public var hintIdentifier: String

  // MARK: - Initialization

  public init(id: Int64? = nil, readInfoId: String, createDate: Date = Date(), hintIdentifier: String) {
    self.id = id
    self.readInfoId = readInfoId
    self.createDate = createDate
    self.hintIdentifier = hintIdentifier
  }

  // MARK: - MutablePersistableRecord

  public mutating func didInsert(_ inserted: InsertionSuccess) {
    id = inserted.rowID
  }
}
