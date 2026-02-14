import Foundation

// MARK: - FinderDomainInterface

public protocol FinderDomainInterface: Sendable {
  func listFiles(at path: String) throws -> [FileItem]
  func createDirectory(named name: String, at path: String) throws
  func renameItem(at path: String, to newName: String) throws
  func deleteItems(at paths: [String]) throws
  func moveItems(at paths: [String], to destinationDirectory: String) throws
  func cloneItem(at path: String) throws
}

// MARK: - FileItem

public struct FileItem: Identifiable, Hashable, Sendable {
  public let id: UUID
  public let name: String
  public let path: String
  public let isDirectory: Bool
  public let childCount: Int?
  public let modifiedDate: Date?
  public let size: Int64?

  public init(
    id: UUID = UUID(),
    name: String,
    path: String,
    isDirectory: Bool,
    childCount: Int? = nil,
    modifiedDate: Date? = nil,
    size: Int64? = nil
  ) {
    self.id = id
    self.name = name
    self.path = path
    self.isDirectory = isDirectory
    self.childCount = childCount
    self.modifiedDate = modifiedDate
    self.size = size
  }

  // MARK: - Hashable

  public func hash(into hasher: inout Hasher) {
    hasher.combine(path)
    hasher.combine(childCount)
    hasher.combine(modifiedDate)
    hasher.combine(size)
  }

  public static func == (lhs: FileItem, rhs: FileItem) -> Bool {
    lhs.path == rhs.path
    && lhs.childCount == rhs.childCount
    && lhs.modifiedDate == rhs.modifiedDate
    && lhs.size == rhs.size
  }
}
