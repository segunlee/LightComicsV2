import Foundation

// MARK: - FileSystemCoreInterface

public protocol FileSystemCoreInterface: Sendable {
  func readDirectory(at path: String) throws -> [FileSystemItem]
  func createDirectory(named name: String, at path: String) throws
  func deleteItem(at path: String) throws
  func moveItem(from sourcePath: String, to destinationPath: String) throws
  func copyItem(from sourcePath: String, to destinationPath: String) throws
}

// MARK: - FileSystemItem

public struct FileSystemItem: Sendable {
  public let name: String
  public let path: String
  public let isDirectory: Bool
  public let childCount: Int?
  public let modifiedDate: Date?
  public let size: Int64?

  public init(
    name: String,
    path: String,
    isDirectory: Bool,
    childCount: Int? = nil,
    modifiedDate: Date? = nil,
    size: Int64? = nil
  ) {
    self.name = name
    self.path = path
    self.isDirectory = isDirectory
    self.childCount = childCount
    self.modifiedDate = modifiedDate
    self.size = size
  }
}

// MARK: - FileSystemCoreError

public enum FileSystemCoreError: Error {
  case documentsDirectoryUnavailable
  case pathOutsideDocuments
}
