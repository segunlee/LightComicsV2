import BookDomainInterface
import DatabaseCore
import DatabaseCoreInterface
import Foundation
import GRDB
import Logger

// MARK: - BookDomain

final class BookDomain: BookDomainInterface, @unchecked Sendable {

  // MARK: - Properties

  private let databaseCore: DatabaseCoreInterface

  // MARK: - Initialization

  init(databaseCore: DatabaseCoreInterface) {
    self.databaseCore = databaseCore
  }

  // MARK: - ReadInfo CRUD

  func fetchReadInfo(identifier: String) throws -> ReadInfo? {
    let result = try databaseCore.dbQueue.read { db in
      try ReadInfoRecord.fetchOne(db, key: identifier).map(Self.toReadInfo)
    }
    Log.debug("fetchReadInfo(id): \(result != nil ? "found" : "nil")")
    return result
  }

  func fetchReadInfo(pathString: String) throws -> ReadInfo? {
    let result = try databaseCore.dbQueue.read { db in
      try ReadInfoRecord
        .filter(Column("pathString") == pathString)
        .filter(Column("isDeleted") == false)
        .fetchOne(db)
        .map(Self.toReadInfo)
    }
    Log.debug("fetchReadInfo(path): \(result != nil ? "found" : "nil")")
    return result
  }

  func fetchReadInfoOrCreate(identifier: String, pathString: String, pathExtension: String) throws -> ReadInfo {
    try databaseCore.dbQueue.write { db in
      if let existing = try ReadInfoRecord.fetchOne(db, key: identifier) {
        Log.debug("fetchReadInfoOrCreate: found existing record")
        return Self.toReadInfo(existing)
      }

      let record = ReadInfoRecord(id: identifier, pathString: pathString, pathExtension: pathExtension)
      try record.insert(db)
      Log.info("Created new ReadInfo: \(URL(fileURLWithPath: pathString).lastPathComponent)")
      return Self.toReadInfo(record)
    }
  }

  func fetchAllReadInfos() throws -> [ReadInfo] {
    let results = try databaseCore.dbQueue.read { db in
      try ReadInfoRecord
        .filter(Column("isDeleted") == false)
        .order(Column("readDate").desc)
        .fetchAll(db)
        .map(Self.toReadInfo)
    }
    Log.debug("fetchAllReadInfos: \(results.count) records")
    return results
  }

  func fetchUnfinishedReadInfos() throws -> [ReadInfo] {
    try databaseCore.dbQueue.read { db in
      try ReadInfoRecord
        .filter(Column("isDeleted") == false)
        .filter(Column("isRead") == false)
        .filter(Column("readDate") != nil)
        .order(Column("readDate").desc)
        .fetchAll(db)
        .map(Self.toReadInfo)
    }
  }

  func fetchFinishedReadInfos() throws -> [ReadInfo] {
    try databaseCore.dbQueue.read { db in
      try ReadInfoRecord
        .filter(Column("isDeleted") == false)
        .filter(Column("isRead") == true)
        .order(Column("readDate").desc)
        .fetchAll(db)
        .map(Self.toReadInfo)
    }
  }

  func fetchRecentReadInfo() throws -> ReadInfo? {
    try databaseCore.dbQueue.read { db in
      try ReadInfoRecord
        .filter(Column("isDeleted") == false)
        .filter(Column("readDate") != nil)
        .order(Column("readDate").desc)
        .fetchOne(db)
        .map(Self.toReadInfo)
    }
  }

  func fetchMigrationCandidates() throws -> [ReadInfo] {
    try databaseCore.dbQueue.read { db in
      try ReadInfoRecord
        .filter(Column("isDeleted") == false)
        .filter(Column("bookmarkData") == nil)
        .filter(Column("pathString") != nil)
        .fetchAll(db)
        .map(Self.toReadInfo)
    }
  }

  func insertReadInfo(_ readInfo: ReadInfo) throws {
    try databaseCore.dbQueue.write { db in
      let record = Self.toRecord(readInfo)
      try record.insert(db)
    }
    Log.debug("insertReadInfo: \(readInfo.id)")
  }

  func updateReadInfo(_ readInfo: ReadInfo) throws {
    try databaseCore.dbQueue.write { db in
      let record = Self.toRecord(readInfo)
      try record.update(db)
    }
    Log.debug("updateReadInfo: \(readInfo.id)")
  }

  func softDeleteReadInfo(identifier: String) throws {
    try databaseCore.dbQueue.write { db in
      guard var record = try ReadInfoRecord.fetchOne(db, key: identifier) else { return }
      record.isDeleted = true
      try record.update(db)
    }
    Log.info("Soft-deleted ReadInfo: \(identifier)")
  }

  func hardDeleteReadInfo(identifier: String) throws {
    try databaseCore.dbQueue.write { db in
      _ = try ReadInfoRecord.deleteOne(db, key: identifier)
    }
    Log.info("Hard-deleted ReadInfo: \(identifier)")
  }

  func reviveReadInfo(identifier: String) throws {
    try databaseCore.dbQueue.write { db in
      guard var record = try ReadInfoRecord.fetchOne(db, key: identifier) else { return }
      record.isDeleted = false
      try record.update(db)
    }
    Log.info("Revived ReadInfo: \(identifier)")
  }

  func updateReadProgress(identifier: String, readIndex: Int) throws {
    try databaseCore.dbQueue.write { db in
      guard var record = try ReadInfoRecord.fetchOne(db, key: identifier) else { return }
      record.readIndex = readIndex
      record.readDate = Date()
      try record.update(db)
    }
    Log.debug("updateReadProgress: index=\(readIndex)")
  }

  func updateTotalPage(identifier: String, totalPage: Int) throws {
    try databaseCore.dbQueue.write { db in
      guard var record = try ReadInfoRecord.fetchOne(db, key: identifier) else { return }
      record.totalPage = totalPage
      try record.update(db)
    }
    Log.debug("updateTotalPage: \(totalPage)")
  }

  func updatePageOptions(identifier: String, options: PageOptions) throws {
    try databaseCore.dbQueue.write { db in
      guard var record = try ReadInfoRecord.fetchOne(db, key: identifier) else { return }
      record.pageOptionTransition = options.transition
      record.pageOptionDisplay = options.display
      record.pageOptionDirection = options.direction
      record.pageOptionContentMode = options.contentMode
      try record.update(db)
    }
    Log.debug("updatePageOptions: transition=\(options.transition), display=\(options.display)")
  }

  func updateFilePath(identifier: String, pathString: String, pathExtension: String, bookmarkData: Data?) throws {
    try databaseCore.dbQueue.write { db in
      guard var record = try ReadInfoRecord.fetchOne(db, key: identifier) else { return }
      record.pathString = pathString
      record.pathExtension = pathExtension
      record.bookmarkData = bookmarkData
      try record.update(db)
    }
    Log.debug("updateFilePath: \(URL(fileURLWithPath: pathString).lastPathComponent)")
  }

  func markAsRead(identifier: String) throws {
    try databaseCore.dbQueue.write { db in
      guard var record = try ReadInfoRecord.fetchOne(db, key: identifier) else { return }
      record.isRead = true
      record.readDate = Date()
      try record.update(db)
    }
    Log.info("Marked as read: \(identifier)")
  }

  func deleteUnresolvedReadInfos(identifiers: [String]) throws {
    try databaseCore.dbQueue.write { db in
      _ = try ReadInfoRecord.filter(identifiers.contains(Column("id"))).deleteAll(db)
    }
    Log.info("Deleted \(identifiers.count) unresolved ReadInfos")
  }

  func deleteAll() throws {
    try databaseCore.dbQueue.write { db in
      _ = try ReadInfoRecord.deleteAll(db)
    }
    Log.info("Deleted all ReadInfos")
  }

  // MARK: - Bookmark CRUD

  func fetchBookmarks(readInfoId: String) throws -> [Bookmark] {
    try databaseCore.dbQueue.read { db in
      try BookmarkRecord
        .filter(Column("readInfoId") == readInfoId)
        .order(Column("createDate").desc)
        .fetchAll(db)
        .compactMap(Self.toBookmark)
    }
  }

  func fetchBookmark(readInfoId: String, hintIdentifier: String) throws -> Bookmark? {
    try databaseCore.dbQueue.read { db in
      try BookmarkRecord
        .filter(Column("readInfoId") == readInfoId)
        .filter(Column("hintIdentifier") == hintIdentifier)
        .fetchOne(db)
        .flatMap(Self.toBookmark)
    }
  }

  func addBookmark(readInfoId: String, hintIdentifier: String) throws {
    try databaseCore.dbQueue.write { db in
      var record = BookmarkRecord(readInfoId: readInfoId, hintIdentifier: hintIdentifier)
      try record.insert(db)
    }
    Log.info("Added bookmark: hint=\(hintIdentifier)")
  }

  func deleteBookmark(readInfoId: String, hintIdentifier: String) throws {
    try databaseCore.dbQueue.write { db in
      _ = try BookmarkRecord
        .filter(Column("readInfoId") == readInfoId)
        .filter(Column("hintIdentifier") == hintIdentifier)
        .deleteAll(db)
    }
    Log.debug("Deleted bookmark: hint=\(hintIdentifier)")
  }

  func deleteAllBookmarks(readInfoId: String) throws {
    try databaseCore.dbQueue.write { db in
      _ = try BookmarkRecord
        .filter(Column("readInfoId") == readInfoId)
        .deleteAll(db)
    }
    Log.debug("Deleted all bookmarks for readInfoId=\(readInfoId)")
  }

  // MARK: - Image Index

  func fetchImageIndexes(readInfoId: String) throws -> [ImageIndex] {
    try databaseCore.dbQueue.read { db in
      let records = try ImageIndexRecord
        .filter(Column("readInfoId") == readInfoId)
        .fetchAll(db)

      return try records.compactMap { record in
        guard let recordId = record.id else { return nil }
        let items = try ImageIndexItemRecord
          .filter(Column("imageIndexId") == recordId)
          .order(Column("elementIndex").asc)
          .fetchAll(db)
          .map { Self.toImageIndexItem($0) }
        return ImageIndex(imageCut: record.imageCut, items: items)
      }
    }
  }

  func updateImageIndexes(readInfoId: String, indexes: [ImageIndex]) throws {
    try databaseCore.dbQueue.write { db in
      _ = try ImageIndexRecord
        .filter(Column("readInfoId") == readInfoId)
        .deleteAll(db)

      for index in indexes {
        var indexRecord = ImageIndexRecord(readInfoId: readInfoId, imageCut: index.imageCut)
        try indexRecord.insert(db)

        guard let indexRecordId = indexRecord.id else { continue }
        for item in index.items {
          var itemRecord = ImageIndexItemRecord(
            imageIndexId: indexRecordId,
            elementIndex: item.elementIndex,
            modifyIndex: item.modifyIndex,
            isFirst: item.isFirst,
            size: item.size
          )
          try itemRecord.insert(db)
        }
      }
    }
    let totalItems = indexes.reduce(0) { $0 + $1.items.count }
    Log.debug("updateImageIndexes: \(indexes.count) indexes, \(totalItems) items")
  }

  // MARK: - String Index

  func fetchStringIndexes(readInfoId: String) throws -> [StringIndex] {
    try databaseCore.dbQueue.read { db in
      let records = try StringIndexRecord
        .filter(Column("readInfoId") == readInfoId)
        .fetchAll(db)

      return try records.compactMap { record in
        guard let recordId = record.id else { return nil }
        let rangeRecords = try StringIndexRangeRecord
          .filter(Column("stringIndexId") == recordId)
          .order(Column("sortOrder").asc)
          .fetchAll(db)
        let ranges = rangeRecords.map(\.rangeValue)
        return StringIndex(size: record.size, attributes: record.attributes, ranges: ranges)
      }
    }
  }

  func updateStringIndexes(readInfoId: String, indexes: [StringIndex]) throws {
    try databaseCore.dbQueue.write { db in
      _ = try StringIndexRecord
        .filter(Column("readInfoId") == readInfoId)
        .deleteAll(db)

      for index in indexes {
        var indexRecord = StringIndexRecord(readInfoId: readInfoId, size: index.size, attributes: index.attributes)
        try indexRecord.insert(db)

        guard let indexRecordId = indexRecord.id else { continue }
        for (order, rangeValue) in index.ranges.enumerated() {
          var rangeRecord = StringIndexRangeRecord(
            stringIndexId: indexRecordId,
            rangeValue: rangeValue,
            sortOrder: order
          )
          try rangeRecord.insert(db)
        }
      }
    }
    let totalRanges = indexes.reduce(0) { $0 + $1.ranges.count }
    Log.debug("updateStringIndexes: \(indexes.count) indexes, \(totalRanges) ranges")
  }

  func deleteStringIndexes(readInfoId: String) throws {
    try databaseCore.dbQueue.write { db in
      _ = try StringIndexRecord
        .filter(Column("readInfoId") == readInfoId)
        .deleteAll(db)
    }
    Log.debug("deleteStringIndexes: readInfoId=\(readInfoId)")
  }

  // MARK: - Private Methods

  private static func toReadInfo(_ record: ReadInfoRecord) -> ReadInfo {
    ReadInfo(
      id: record.id,
      pathString: record.pathString,
      pathExtension: record.pathExtension,
      bookmarkData: record.bookmarkData,
      readIndex: record.readIndex,
      totalPage: record.totalPage,
      pageOptions: PageOptions(
        transition: record.pageOptionTransition,
        display: record.pageOptionDisplay,
        direction: record.pageOptionDirection,
        contentMode: record.pageOptionContentMode
      ),
      readDate: record.readDate,
      createDate: record.createDate,
      isRead: record.isRead,
      isDeleted: record.isDeleted,
      imageCut: record.imageCut,
      imageContentMode: record.imageContentMode,
      imageFilter: record.imageFilter,
      stringEncoding: record.stringEncoding,
      stringIndexSentence: record.stringIndexSentence,
      isLightProviderFile: record.isLightProviderFile,
      linkAccountUUID: record.linkAccountUUID
    )
  }

  private static func toRecord(_ readInfo: ReadInfo) -> ReadInfoRecord {
    ReadInfoRecord(
      id: readInfo.id,
      pathString: readInfo.pathString,
      pathExtension: readInfo.pathExtension,
      bookmarkData: readInfo.bookmarkData,
      readIndex: readInfo.readIndex,
      totalPage: readInfo.totalPage,
      pageOptionTransition: readInfo.pageOptions.transition,
      pageOptionDisplay: readInfo.pageOptions.display,
      pageOptionDirection: readInfo.pageOptions.direction,
      pageOptionContentMode: readInfo.pageOptions.contentMode,
      readDate: readInfo.readDate,
      createDate: readInfo.createDate,
      isRead: readInfo.isRead,
      isDeleted: readInfo.isDeleted,
      imageCut: readInfo.imageCut,
      imageContentMode: readInfo.imageContentMode,
      imageFilter: readInfo.imageFilter,
      stringEncoding: readInfo.stringEncoding,
      stringIndexSentence: readInfo.stringIndexSentence,
      isLightProviderFile: readInfo.isLightProviderFile,
      linkAccountUUID: readInfo.linkAccountUUID
    )
  }

  private static func toBookmark(_ record: BookmarkRecord) -> Bookmark? {
    guard let id = record.id else { return nil }
    return Bookmark(
      id: id,
      readInfoId: record.readInfoId,
      createDate: record.createDate,
      hintIdentifier: record.hintIdentifier
    )
  }

  private static func toImageIndexItem(_ record: ImageIndexItemRecord) -> ImageIndexItem {
    ImageIndexItem(
      elementIndex: record.elementIndex,
      modifyIndex: record.modifyIndex,
      isFirst: record.isFirst,
      size: record.size
    )
  }
}
