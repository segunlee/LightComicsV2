import DatabaseCoreInterface
import Foundation
import GRDB
import Logger

// MARK: - DatabaseCore

public final class DatabaseCore: DatabaseCoreInterface, @unchecked Sendable {
  // MARK: - Properties

  public let dbQueue: DatabaseQueue

  // MARK: - Initialization

  public init(dbQueue: DatabaseQueue) {
    self.dbQueue = dbQueue
  }

  public convenience init() {
    let dbQueue = Self.makeDatabaseQueue()
    self.init(dbQueue: dbQueue)
    Self.runMigrations(on: dbQueue)
    Log.info("Database initialized")
  }

  // MARK: - Private Methods

  private static func makeDatabaseQueue() -> DatabaseQueue {
    guard let supportDirectoryURL = FileManager.createOrFindApplicationSupportDirectory() else {
      fatalError("Can't create or find the application support directory.")
    }

    let fileName = "lightcomics.sqlite"
    let dbURL = supportDirectoryURL.appendingPathComponent(fileName)
    var path = dbURL.path

    #if targetEnvironment(simulator)
      Log.info("DatabaseCore on Simulator (DEBUG MODE)")
      let homeDirectory: NSString = NSHomeDirectory() as NSString
      let paths = homeDirectory.pathComponents
      path = String(format: "%@/%@/Desktop/%@", paths[1], paths[2], fileName)
    #endif

    Log.debug("Database path: \(path)")

    do {
      return try DatabaseQueue(path: path)
    } catch {
      fatalError("DatabaseCore: Failed to open database at \(path): \(error)")
    }
  }

  private static func runMigrations(on dbQueue: DatabaseQueue) {
    do {
      let migrator = DatabaseMigrations.migrator
      try migrator.migrate(dbQueue)
      Log.debug("Database migrations completed")
    } catch {
      fatalError("DatabaseCore: Migration failed: \(error)")
    }
  }

  // MARK: - Testing

  public static func inMemory() -> DatabaseCore {
    do {
      let dbQueue = try DatabaseQueue()
      let migrator = DatabaseMigrations.migrator
      try migrator.migrate(dbQueue)
      return DatabaseCore(dbQueue: dbQueue)
    } catch {
      fatalError("DatabaseCore: Failed to create in-memory database: \(error)")
    }
  }
}

extension FileManager {
  static func createOrFindApplicationSupportDirectory() -> URL? {
    let bundleID = Bundle.main.bundleIdentifier
    let appSupportDir = self.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
    guard !appSupportDir.isEmpty else {
      return nil
    }
    guard let bundleID else { return nil }
    let dirPath = appSupportDir[0].appendingPathComponent(bundleID)
    do {
      try self.default.createDirectory(at: dirPath, withIntermediateDirectories: true, attributes: nil)
      return dirPath
    } catch {
      Log.error("Error creating Application Support directory with error: \(error)")
      return nil
    }
  }
}
