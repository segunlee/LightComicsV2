import BookDomainInterface
import Foundation

// MARK: - BookShelfUseCase

protocol BookShelfUseCase: Sendable {
  func fetchNowReading() throws -> [ReadInfo]
  func fetchRead() throws -> [ReadInfo]
  func fetchAll() throws -> [ReadInfo]
  func markAsRead(identifier: String) throws
  func resetProgress(identifier: String) throws
}

// MARK: - BookShelfUseCaseImpl

final class BookShelfUseCaseImpl: BookShelfUseCase {
  private let bookDomain: BookDomainInterface

  init(bookDomain: BookDomainInterface) {
    self.bookDomain = bookDomain
  }

  func fetchNowReading() throws -> [ReadInfo] {
    try bookDomain.fetchUnfinishedReadInfos()
  }

  func fetchRead() throws -> [ReadInfo] {
    try bookDomain.fetchFinishedReadInfos()
  }

  func fetchAll() throws -> [ReadInfo] {
    try bookDomain.fetchAllReadInfos()
  }

  func markAsRead(identifier: String) throws {
    try bookDomain.markAsRead(identifier: identifier)
  }

  func resetProgress(identifier: String) throws {
    try bookDomain.updateReadProgress(identifier: identifier, readIndex: 0)
  }
}
