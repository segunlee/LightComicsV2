import FinderDomainInterface
import Foundation
import SwiftUI

// MARK: - FileItemCell

struct FileItemCell: View {
  // MARK: - Properties

  let item: FileItem

  // MARK: - Initialization

  init(item: FileItem) {
    self.item = item
  }

  // MARK: - Body

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: FileIconProvider.icon(for: item.name, isDirectory: item.isDirectory))
        .font(.title2)
        .foregroundStyle(FileIconProvider.color(for: item.name, isDirectory: item.isDirectory))
        .frame(width: 32, height: 32)

      VStack(alignment: .leading, spacing: 4) {
        Text(item.name)
          .font(.body)
          .foregroundStyle(.primary)
          .lineLimit(2)

        HStack(spacing: 4) {
          Text(itemDescription())
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(.vertical, 0)
  }

  // MARK: - Private Methods

  private func itemDescription() -> String {
    var desc = [String]()
    if let date = item.modifiedDate {
      desc.append(formattedDate(date))
    }
    if let size = item.size, !item.isDirectory {
      desc.append(formattedSize(size))
    }
    if let count = item.childCount, item.isDirectory {
      desc.append(FinderStrings.cellItemCount(count))
    }
    return desc.joined(separator: " · ")
  }
  
  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    formatter.locale = Locale.autoupdatingCurrent
    return formatter
  }()

  private static let sizeFormatter: ByteCountFormatter = {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter
  }()

  private func formattedDate(_ date: Date) -> String {
    Self.dateFormatter.string(from: date)
  }

  private func formattedSize(_ bytes: Int64) -> String {
    Self.sizeFormatter.string(fromByteCount: bytes)
  }
}

// MARK: - Preview

#Preview {
  List {
    FileItemCell(
      item: FileItem(
        name: "Documents",
        path: "/Documents",
        isDirectory: true,
        childCount: 10,
        modifiedDate: Date(),
        size: nil
      )
    )

    FileItemCell(
      item: FileItem(
        name: "Report.pdf",
        path: "/Report.pdf",
        isDirectory: false,
        modifiedDate: Date(),
        size: 1_234_567
      )
    )

    FileItemCell(
      item: FileItem(
        name: "Image.png",
        path: "/Image.png",
        isDirectory: false,
        modifiedDate: Date().addingTimeInterval(-86400),
        size: 456_789
      )
    )

    FileItemCell(
      item: FileItem(
        name: "Video.mp4",
        path: "/Video.mp4",
        isDirectory: false,
        modifiedDate: Date(),
        size: 5_234_567
      )
    )

    FileItemCell(
      item: FileItem(
        name: "Music.mp3",
        path: "/Music.mp3",
        isDirectory: false,
        modifiedDate: Date(),
        size: 3_456_789
      )
    )

    FileItemCell(
      item: FileItem(
        name: "Archive.zip",
        path: "/Archive.zip",
        isDirectory: false,
        modifiedDate: Date(),
        size: 10_234_567
      )
    )

    FileItemCell(
      item: FileItem(
        name: "Code.swift",
        path: "/Code.swift",
        isDirectory: false,
        modifiedDate: Date(),
        size: 12_345
      )
    )
  }
}
