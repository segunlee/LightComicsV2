import Foundation
import GRDB

// MARK: - StringIndexRecord

public struct StringIndexRecord: Codable, Identifiable, FetchableRecord, MutablePersistableRecord, Sendable {
  public static let databaseTableName = "stringIndex"

  // MARK: - Properties

  public var id: Int64?
  public var readInfoId: String
  public var size: String
  public var attributes: String

  // MARK: - Initialization

  public init(id: Int64? = nil, readInfoId: String, size: String = "0|0", attributes: String = "") {
    self.id = id
    self.readInfoId = readInfoId
    self.size = size
    self.attributes = attributes
  }

  // MARK: - MutablePersistableRecord

  public mutating func didInsert(_ inserted: InsertionSuccess) {
    id = inserted.rowID
  }
}

// MARK: - StringIndexRangeRecord

public struct StringIndexRangeRecord: Codable, Identifiable, FetchableRecord, MutablePersistableRecord, Sendable {
  public static let databaseTableName = "stringIndexRange"

  // MARK: - Properties

  public var id: Int64?
  public var stringIndexId: Int64
  public var rangeValue: String
  public var sortOrder: Int

  // MARK: - Initialization

  public init(id: Int64? = nil, stringIndexId: Int64, rangeValue: String, sortOrder: Int) {
    self.id = id
    self.stringIndexId = stringIndexId
    self.rangeValue = rangeValue
    self.sortOrder = sortOrder
  }

  // MARK: - MutablePersistableRecord

  public mutating func didInsert(_ inserted: InsertionSuccess) {
    id = inserted.rowID
  }
}
