@testable import BookDomain
import BookDomainInterface
import DatabaseCore
import XCTest

// MARK: - BookDomainTests

final class BookDomainTests: XCTestCase {

  // MARK: - Properties

  private var sut: BookDomainInterface!
  private var databaseCore: DatabaseCore!

  // MARK: - Setup

  override func setUp() {
    super.setUp()
    databaseCore = DatabaseCore.inMemory()
    sut = BookDomain(databaseCore: databaseCore)
  }

  override func tearDown() {
    sut = nil
    databaseCore = nil
    super.tearDown()
  }

  // MARK: - ReadInfo Tests

  func testInsertAndFetchReadInfo() throws {
    let readInfo = ReadInfo(id: "md5_1", pathString: "/test.cbz", pathExtension: "cbz")
    try sut.insertReadInfo(readInfo)

    let fetched = try sut.fetchReadInfo(identifier: "md5_1")
    XCTAssertNotNil(fetched)
    XCTAssertEqual(fetched?.id, "md5_1")
    XCTAssertEqual(fetched?.pathString, "/test.cbz")
  }

  func testFetchReadInfoByPath() throws {
    let readInfo = ReadInfo(id: "md5_path", pathString: "/comics/test.cbz", pathExtension: "cbz")
    try sut.insertReadInfo(readInfo)

    let fetched = try sut.fetchReadInfo(pathString: "/comics/test.cbz")
    XCTAssertNotNil(fetched)
    XCTAssertEqual(fetched?.id, "md5_path")
  }

  func testFetchReadInfoOrCreateExisting() throws {
    let readInfo = ReadInfo(id: "md5_existing", pathString: "/existing.cbz", pathExtension: "cbz", readIndex: 5)
    try sut.insertReadInfo(readInfo)

    let fetched = try sut.fetchReadInfoOrCreate(identifier: "md5_existing", pathString: "/new.cbz", pathExtension: "cbz")
    XCTAssertEqual(fetched.id, "md5_existing")
    XCTAssertEqual(fetched.readIndex, 5)
  }

  func testFetchReadInfoOrCreateNew() throws {
    let fetched = try sut.fetchReadInfoOrCreate(identifier: "md5_new", pathString: "/new.cbz", pathExtension: "cbz")
    XCTAssertEqual(fetched.id, "md5_new")
    XCTAssertEqual(fetched.pathString, "/new.cbz")
  }

  func testFetchAllReadInfos() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_a", readIndex: 0))
    try sut.insertReadInfo(ReadInfo(id: "md5_b", readIndex: 0))

    let all = try sut.fetchAllReadInfos()
    XCTAssertEqual(all.count, 2)
  }

  func testFetchAllReadInfosExcludesDeleted() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_active"))
    try sut.insertReadInfo(ReadInfo(id: "md5_deleted", isDeleted: true))

    let all = try sut.fetchAllReadInfos()
    XCTAssertEqual(all.count, 1)
    XCTAssertEqual(all.first?.id, "md5_active")
  }

  func testFetchUnfinishedReadInfos() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_unfinished", readDate: Date(), isRead: false))
    try sut.insertReadInfo(ReadInfo(id: "md5_finished", readDate: Date(), isRead: true))
    try sut.insertReadInfo(ReadInfo(id: "md5_unstarted"))

    let unfinished = try sut.fetchUnfinishedReadInfos()
    XCTAssertEqual(unfinished.count, 1)
    XCTAssertEqual(unfinished.first?.id, "md5_unfinished")
  }

  func testFetchFinishedReadInfos() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_fin1", readDate: Date(), isRead: true))
    try sut.insertReadInfo(ReadInfo(id: "md5_unfin", readDate: Date(), isRead: false))

    let finished = try sut.fetchFinishedReadInfos()
    XCTAssertEqual(finished.count, 1)
    XCTAssertEqual(finished.first?.id, "md5_fin1")
  }

  func testFetchRecentReadInfo() throws {
    let oldDate = Date(timeIntervalSinceNow: -3600)
    let recentDate = Date()

    try sut.insertReadInfo(ReadInfo(id: "md5_old", readDate: oldDate))
    try sut.insertReadInfo(ReadInfo(id: "md5_recent", readDate: recentDate))

    let recent = try sut.fetchRecentReadInfo()
    XCTAssertEqual(recent?.id, "md5_recent")
  }

  func testUpdateReadInfo() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_update", readIndex: 0))

    var readInfo = try sut.fetchReadInfo(identifier: "md5_update")!
    readInfo.readIndex = 10
    try sut.updateReadInfo(readInfo)

    let fetched = try sut.fetchReadInfo(identifier: "md5_update")
    XCTAssertEqual(fetched?.readIndex, 10)
  }

  func testSoftDeleteAndRevive() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_soft"))

    try sut.softDeleteReadInfo(identifier: "md5_soft")
    let deleted = try sut.fetchReadInfo(identifier: "md5_soft")
    XCTAssertEqual(deleted?.isDeleted, true)

    try sut.reviveReadInfo(identifier: "md5_soft")
    let revived = try sut.fetchReadInfo(identifier: "md5_soft")
    XCTAssertEqual(revived?.isDeleted, false)
  }

  func testHardDelete() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_hard"))

    try sut.hardDeleteReadInfo(identifier: "md5_hard")
    let fetched = try sut.fetchReadInfo(identifier: "md5_hard")
    XCTAssertNil(fetched)
  }

  func testUpdateReadProgress() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_progress"))

    try sut.updateReadProgress(identifier: "md5_progress", readIndex: 42)

    let fetched = try sut.fetchReadInfo(identifier: "md5_progress")
    XCTAssertEqual(fetched?.readIndex, 42)
    XCTAssertNotNil(fetched?.readDate)
  }

  func testUpdateTotalPage() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_total"))

    try sut.updateTotalPage(identifier: "md5_total", totalPage: 100)

    let fetched = try sut.fetchReadInfo(identifier: "md5_total")
    XCTAssertEqual(fetched?.totalPage, 100)
  }

  func testUpdatePageOptions() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_opts"))

    let options = PageOptions(transition: 1, display: 2, direction: 1, contentMode: 3)
    try sut.updatePageOptions(identifier: "md5_opts", options: options)

    let fetched = try sut.fetchReadInfo(identifier: "md5_opts")
    XCTAssertEqual(fetched?.pageOptions.transition, 1)
    XCTAssertEqual(fetched?.pageOptions.display, 2)
    XCTAssertEqual(fetched?.pageOptions.direction, 1)
    XCTAssertEqual(fetched?.pageOptions.contentMode, 3)
  }

  func testMarkAsRead() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_mark"))

    try sut.markAsRead(identifier: "md5_mark")

    let fetched = try sut.fetchReadInfo(identifier: "md5_mark")
    XCTAssertEqual(fetched?.isRead, true)
    XCTAssertNotNil(fetched?.readDate)
  }

  func testDeleteAll() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_da1"))
    try sut.insertReadInfo(ReadInfo(id: "md5_da2"))

    try sut.deleteAll()

    let all = try sut.fetchAllReadInfos()
    XCTAssertEqual(all.count, 0)
  }

  // MARK: - Bookmark Tests

  func testAddAndFetchBookmark() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_bk"))

    try sut.addBookmark(readInfoId: "md5_bk", hintIdentifier: "page_5")
    let bookmarks = try sut.fetchBookmarks(readInfoId: "md5_bk")

    XCTAssertEqual(bookmarks.count, 1)
    XCTAssertEqual(bookmarks.first?.hintIdentifier, "page_5")
  }

  func testFetchBookmarkByHint() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_bkh"))
    try sut.addBookmark(readInfoId: "md5_bkh", hintIdentifier: "page_10")

    let bookmark = try sut.fetchBookmark(readInfoId: "md5_bkh", hintIdentifier: "page_10")
    XCTAssertNotNil(bookmark)
    XCTAssertEqual(bookmark?.hintIdentifier, "page_10")
  }

  func testDeleteBookmark() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_bkd"))
    try sut.addBookmark(readInfoId: "md5_bkd", hintIdentifier: "page_3")

    try sut.deleteBookmark(readInfoId: "md5_bkd", hintIdentifier: "page_3")

    let bookmarks = try sut.fetchBookmarks(readInfoId: "md5_bkd")
    XCTAssertEqual(bookmarks.count, 0)
  }

  func testDeleteAllBookmarks() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_bkall"))
    try sut.addBookmark(readInfoId: "md5_bkall", hintIdentifier: "page_1")
    try sut.addBookmark(readInfoId: "md5_bkall", hintIdentifier: "page_2")

    try sut.deleteAllBookmarks(readInfoId: "md5_bkall")

    let bookmarks = try sut.fetchBookmarks(readInfoId: "md5_bkall")
    XCTAssertEqual(bookmarks.count, 0)
  }

  // MARK: - Image Index Tests

  func testUpdateAndFetchImageIndexes() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_img"))

    let indexes = [
      ImageIndex(imageCut: 1, items: [
        ImageIndexItem(elementIndex: 0, modifyIndex: 0, isFirst: true, size: "100|200"),
        ImageIndexItem(elementIndex: 1, modifyIndex: 1, size: "100|200")
      ])
    ]

    try sut.updateImageIndexes(readInfoId: "md5_img", indexes: indexes)

    let fetched = try sut.fetchImageIndexes(readInfoId: "md5_img")
    XCTAssertEqual(fetched.count, 1)
    XCTAssertEqual(fetched.first?.imageCut, 1)
    XCTAssertEqual(fetched.first?.items.count, 2)
    XCTAssertEqual(fetched.first?.items.first?.isFirst, true)
  }

  // MARK: - String Index Tests

  func testUpdateAndFetchStringIndexes() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_str"))

    let indexes = [
      StringIndex(size: "375|667", attributes: "Helvetica|14|20|0", ranges: ["0-100", "100-200"])
    ]

    try sut.updateStringIndexes(readInfoId: "md5_str", indexes: indexes)

    let fetched = try sut.fetchStringIndexes(readInfoId: "md5_str")
    XCTAssertEqual(fetched.count, 1)
    XCTAssertEqual(fetched.first?.size, "375|667")
    XCTAssertEqual(fetched.first?.ranges.count, 2)
    XCTAssertEqual(fetched.first?.ranges, ["0-100", "100-200"])
  }

  func testDeleteStringIndexes() throws {
    try sut.insertReadInfo(ReadInfo(id: "md5_strdel"))

    let indexes = [StringIndex(size: "375|667", attributes: "Helvetica|14|20|0", ranges: ["0-50"])]
    try sut.updateStringIndexes(readInfoId: "md5_strdel", indexes: indexes)

    try sut.deleteStringIndexes(readInfoId: "md5_strdel")

    let fetched = try sut.fetchStringIndexes(readInfoId: "md5_strdel")
    XCTAssertEqual(fetched.count, 0)
  }
}
