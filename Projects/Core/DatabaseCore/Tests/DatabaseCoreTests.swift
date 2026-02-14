@testable import DatabaseCore
import GRDB
import XCTest

// MARK: - DatabaseCoreTests

final class DatabaseCoreTests: XCTestCase {

  // MARK: - Properties

  private var sut: DatabaseCore!

  // MARK: - Setup

  override func setUp() {
    super.setUp()
    sut = DatabaseCore.inMemory()
  }

  override func tearDown() {
    sut = nil
    super.tearDown()
  }

  // MARK: - Migration Tests

  func testMigrationCreatesAllTables() throws {
    try sut.dbQueue.read { db in
      XCTAssertTrue(try db.tableExists("readInfo"))
      XCTAssertTrue(try db.tableExists("bookmark"))
      XCTAssertTrue(try db.tableExists("imageIndex"))
      XCTAssertTrue(try db.tableExists("imageIndexItem"))
      XCTAssertTrue(try db.tableExists("stringIndex"))
      XCTAssertTrue(try db.tableExists("stringIndexRange"))
    }
  }

  // MARK: - ReadInfoRecord Tests

  func testInsertAndFetchReadInfo() throws {
    let record = ReadInfoRecord(id: "md5_test", pathString: "/path/test.cbz", pathExtension: "cbz")

    try sut.dbQueue.write { db in
      try record.insert(db)
    }

    let fetched = try sut.dbQueue.read { db in
      try ReadInfoRecord.fetchOne(db, key: "md5_test")
    }

    XCTAssertNotNil(fetched)
    XCTAssertEqual(fetched?.id, "md5_test")
    XCTAssertEqual(fetched?.pathString, "/path/test.cbz")
    XCTAssertEqual(fetched?.pathExtension, "cbz")
    XCTAssertEqual(fetched?.readIndex, 0)
    XCTAssertEqual(fetched?.isDeleted, false)
  }

  func testUpdateReadInfo() throws {
    var record = ReadInfoRecord(id: "md5_update", pathString: "/path/original.cbz")

    try sut.dbQueue.write { db in
      try record.insert(db)
    }

    try sut.dbQueue.write { db in
      record.readIndex = 5
      record.isRead = true
      try record.update(db)
    }

    let fetched = try sut.dbQueue.read { db in
      try ReadInfoRecord.fetchOne(db, key: "md5_update")
    }

    XCTAssertEqual(fetched?.readIndex, 5)
    XCTAssertEqual(fetched?.isRead, true)
  }

  func testDeleteReadInfo() throws {
    let record = ReadInfoRecord(id: "md5_delete")

    try sut.dbQueue.write { db in
      try record.insert(db)
    }

    try sut.dbQueue.write { db in
      _ = try ReadInfoRecord.deleteOne(db, key: "md5_delete")
    }

    let fetched = try sut.dbQueue.read { db in
      try ReadInfoRecord.fetchOne(db, key: "md5_delete")
    }

    XCTAssertNil(fetched)
  }

  func testSoftDeleteReadInfo() throws {
    var record = ReadInfoRecord(id: "md5_soft")

    try sut.dbQueue.write { db in
      try record.insert(db)
    }

    try sut.dbQueue.write { db in
      record.isDeleted = true
      try record.update(db)
    }

    let fetched = try sut.dbQueue.read { db in
      try ReadInfoRecord.fetchOne(db, key: "md5_soft")
    }

    XCTAssertNotNil(fetched)
    XCTAssertEqual(fetched?.isDeleted, true)
  }

  // MARK: - BookmarkRecord Tests

  func testInsertAndFetchBookmark() throws {
    let readInfo = ReadInfoRecord(id: "md5_bookmark")

    try sut.dbQueue.write { db in
      try readInfo.insert(db)
      var bookmark = BookmarkRecord(readInfoId: "md5_bookmark", hintIdentifier: "page_5")
      try bookmark.insert(db)
    }

    let bookmarks = try sut.dbQueue.read { db in
      try BookmarkRecord.filter(Column("readInfoId") == "md5_bookmark").fetchAll(db)
    }

    XCTAssertEqual(bookmarks.count, 1)
    XCTAssertEqual(bookmarks.first?.hintIdentifier, "page_5")
    XCTAssertNotNil(bookmarks.first?.id)
  }

  func testBookmarkCascadeDelete() throws {
    let readInfo = ReadInfoRecord(id: "md5_cascade")

    try sut.dbQueue.write { db in
      try readInfo.insert(db)
      var bookmark = BookmarkRecord(readInfoId: "md5_cascade", hintIdentifier: "page_1")
      try bookmark.insert(db)
    }

    try sut.dbQueue.write { db in
      _ = try ReadInfoRecord.deleteOne(db, key: "md5_cascade")
    }

    let bookmarks = try sut.dbQueue.read { db in
      try BookmarkRecord.filter(Column("readInfoId") == "md5_cascade").fetchAll(db)
    }

    XCTAssertEqual(bookmarks.count, 0)
  }

  // MARK: - ImageIndex Tests

  func testInsertAndFetchImageIndex() throws {
    let readInfo = ReadInfoRecord(id: "md5_image")

    try sut.dbQueue.write { db in
      try readInfo.insert(db)
      var indexRecord = ImageIndexRecord(readInfoId: "md5_image", imageCut: 1)
      try indexRecord.insert(db)

      var item = ImageIndexItemRecord(imageIndexId: indexRecord.id!, elementIndex: 0, modifyIndex: 0, isFirst: true, size: "100|200")
      try item.insert(db)
    }

    let indexes = try sut.dbQueue.read { db in
      try ImageIndexRecord.filter(Column("readInfoId") == "md5_image").fetchAll(db)
    }

    XCTAssertEqual(indexes.count, 1)
    XCTAssertEqual(indexes.first?.imageCut, 1)

    let items = try sut.dbQueue.read { db in
      try ImageIndexItemRecord.filter(Column("imageIndexId") == indexes.first!.id!).fetchAll(db)
    }

    XCTAssertEqual(items.count, 1)
    XCTAssertEqual(items.first?.size, "100|200")
    XCTAssertEqual(items.first?.isFirst, true)
  }

  func testImageIndexCascadeDelete() throws {
    let readInfo = ReadInfoRecord(id: "md5_img_cascade")

    try sut.dbQueue.write { db in
      try readInfo.insert(db)
      var indexRecord = ImageIndexRecord(readInfoId: "md5_img_cascade", imageCut: 0)
      try indexRecord.insert(db)

      var item = ImageIndexItemRecord(imageIndexId: indexRecord.id!, elementIndex: 0, modifyIndex: 0)
      try item.insert(db)
    }

    try sut.dbQueue.write { db in
      _ = try ReadInfoRecord.deleteOne(db, key: "md5_img_cascade")
    }

    let allItems = try sut.dbQueue.read { db in
      try ImageIndexItemRecord.fetchAll(db)
    }

    XCTAssertEqual(allItems.count, 0)
  }

  // MARK: - StringIndex Tests

  func testInsertAndFetchStringIndex() throws {
    let readInfo = ReadInfoRecord(id: "md5_string")

    try sut.dbQueue.write { db in
      try readInfo.insert(db)
      var indexRecord = StringIndexRecord(readInfoId: "md5_string", size: "375|667", attributes: "Helvetica|14|20|0")
      try indexRecord.insert(db)

      var range = StringIndexRangeRecord(stringIndexId: indexRecord.id!, rangeValue: "0-100", sortOrder: 0)
      try range.insert(db)
    }

    let indexes = try sut.dbQueue.read { db in
      try StringIndexRecord.filter(Column("readInfoId") == "md5_string").fetchAll(db)
    }

    XCTAssertEqual(indexes.count, 1)
    XCTAssertEqual(indexes.first?.size, "375|667")

    let ranges = try sut.dbQueue.read { db in
      try StringIndexRangeRecord.filter(Column("stringIndexId") == indexes.first!.id!).fetchAll(db)
    }

    XCTAssertEqual(ranges.count, 1)
    XCTAssertEqual(ranges.first?.rangeValue, "0-100")
  }
}
