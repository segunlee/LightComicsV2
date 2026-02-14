import Foundation
import GRDB

// MARK: - DatabaseMigrations

enum DatabaseMigrations {
  static var migrator: DatabaseMigrator {
    var migrator = DatabaseMigrator()

    migrator.registerMigration("v1_createReadInfo") { db in
      try db.create(table: "readInfo") { t in
        t.primaryKey("id", .text).notNull()
        t.column("pathString", .text)
        t.column("pathExtension", .text)
        t.column("bookmarkData", .blob)
        t.column("readIndex", .integer).notNull().defaults(to: 0)
        t.column("totalPage", .integer).notNull().defaults(to: 0)
        t.column("pageOptionTransition", .integer).notNull().defaults(to: 0)
        t.column("pageOptionDisplay", .integer).notNull().defaults(to: 0)
        t.column("pageOptionDirection", .integer).notNull().defaults(to: 0)
        t.column("pageOptionContentMode", .integer).notNull().defaults(to: 0)
        t.column("readDate", .datetime)
        t.column("createDate", .datetime).notNull()
        t.column("isRead", .boolean).notNull().defaults(to: false)
        t.column("isDeleted", .boolean).notNull().defaults(to: false)
        t.column("imageCut", .integer).notNull().defaults(to: 0)
        t.column("imageContentMode", .integer).notNull().defaults(to: 0)
        t.column("imageFilter", .integer).notNull().defaults(to: 0)
        t.column("stringEncoding", .integer).notNull().defaults(to: 0)
        t.column("stringIndexSentence", .text).notNull().defaults(to: "")
        t.column("isLightProviderFile", .boolean).notNull().defaults(to: false)
        t.column("linkAccountUUID", .text)
      }
    }

    migrator.registerMigration("v1_createBookmark") { db in
      try db.create(table: "bookmark") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("readInfoId", .text).notNull()
          .references("readInfo", onDelete: .cascade)
        t.column("createDate", .datetime).notNull()
        t.column("hintIdentifier", .text).notNull()
      }
    }

    migrator.registerMigration("v1_createImageIndex") { db in
      try db.create(table: "imageIndex") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("readInfoId", .text).notNull()
          .references("readInfo", onDelete: .cascade)
        t.column("imageCut", .integer).notNull().defaults(to: 0)
      }

      try db.create(table: "imageIndexItem") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("imageIndexId", .integer).notNull()
          .references("imageIndex", onDelete: .cascade)
        t.column("elementIndex", .integer).notNull()
        t.column("modifyIndex", .integer).notNull()
        t.column("isFirst", .boolean).notNull().defaults(to: false)
        t.column("size", .text).notNull().defaults(to: "0|0")
      }
    }

    migrator.registerMigration("v1_createStringIndex") { db in
      try db.create(table: "stringIndex") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("readInfoId", .text).notNull()
          .references("readInfo", onDelete: .cascade)
        t.column("size", .text).notNull().defaults(to: "0|0")
        t.column("attributes", .text).notNull().defaults(to: "")
      }

      try db.create(table: "stringIndexRange") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("stringIndexId", .integer).notNull()
          .references("stringIndex", onDelete: .cascade)
        t.column("rangeValue", .text).notNull()
        t.column("sortOrder", .integer).notNull()
      }
    }

    return migrator
  }
}
