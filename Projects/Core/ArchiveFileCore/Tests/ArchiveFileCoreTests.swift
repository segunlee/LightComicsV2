import ArchiveFileCore
import XCTest

final class ArchiveFileCoreTests: XCTestCase {
  func test_init() {
    let core = ArchiveFileCore()
    XCTAssertNotNil(core)
  }
}
