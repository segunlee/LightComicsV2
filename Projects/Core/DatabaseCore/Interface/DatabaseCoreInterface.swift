import GRDB

// MARK: - DatabaseCoreInterface

public protocol DatabaseCoreInterface: Sendable {
  var dbQueue: DatabaseQueue { get }
}
