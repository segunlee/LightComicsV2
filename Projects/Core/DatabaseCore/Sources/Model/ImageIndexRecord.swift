import Foundation
import GRDB

// MARK: - ImageIndexRecord

public struct ImageIndexRecord: Codable, Identifiable, FetchableRecord, MutablePersistableRecord, Sendable {
  public static let databaseTableName = "imageIndex"

  // MARK: - Properties

  public var id: Int64?
  public var readInfoId: String
  public var imageCut: Int

  // MARK: - Initialization

  public init(id: Int64? = nil, readInfoId: String, imageCut: Int = 0) {
    self.id = id
    self.readInfoId = readInfoId
    self.imageCut = imageCut
  }

  // MARK: - MutablePersistableRecord

  public mutating func didInsert(_ inserted: InsertionSuccess) {
    id = inserted.rowID
  }
}

// MARK: - ImageIndexItemRecord

public struct ImageIndexItemRecord: Codable, Identifiable, FetchableRecord, MutablePersistableRecord, Sendable {
  public static let databaseTableName = "imageIndexItem"

  // MARK: - Properties

  public var id: Int64?
  public var imageIndexId: Int64
  public var elementIndex: Int
  public var modifyIndex: Int
  public var isFirst: Bool
  public var size: String

  // MARK: - Initialization

  public init(
    id: Int64? = nil,
    imageIndexId: Int64,
    elementIndex: Int,
    modifyIndex: Int,
    isFirst: Bool = false,
    size: String = "0|0"
  ) {
    self.id = id
    self.imageIndexId = imageIndexId
    self.elementIndex = elementIndex
    self.modifyIndex = modifyIndex
    self.isFirst = isFirst
    self.size = size
  }

  // MARK: - MutablePersistableRecord

  public mutating func didInsert(_ inserted: InsertionSuccess) {
    id = inserted.rowID
  }
}
