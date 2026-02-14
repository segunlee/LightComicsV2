import SwiftUI

// MARK: - FileIconProvider

struct FileIconProvider {
  // MARK: - Icon Mapping

  // swiftlint:disable:next function_body_length
  static func icon(for fileName: String, isDirectory: Bool) -> String {
    if isDirectory {
      return "folder.fill"
    }

    let fileExtension = (fileName as NSString).pathExtension.lowercased()

    switch fileExtension {
    // MARK: Documents

    case "pdf":
      return "doc.fill"
    case "doc", "docx":
      return "doc.text.fill"
    case "txt", "rtf":
      return "doc.plaintext.fill"
    case "pages":
      return "doc.richtext.fill"
    case "xls", "xlsx", "numbers":
      return "tablecells.fill"
    case "ppt", "pptx", "key":
      return "rectangle.on.rectangle.angled.fill"

    // MARK: Images

    case "jpg", "jpeg", "png", "gif", "heic", "heif":
      return "photo.fill"
    case "svg":
      return "photo.artframe"
    case "psd":
      return "camera.filters"
    case "bmp":
      return "photo"

    // MARK: Videos

    case "mp4", "mov", "avi", "mkv", "m4v":
      return "video.fill"
    case "webm":
      return "play.rectangle.fill"

    // MARK: Audio

    case "mp3", "wav", "aac", "m4a", "flac":
      return "music.note"
    case "aiff":
      return "waveform"

    // MARK: Archives

    case "zip", "cbz", "rar", "cbr", "7z", "cb7", "tar", "cbt", "gz", "bz2", "xz":
      return "doc.zipper"

    // MARK: Code

    case "swift":
      return "swift"
    case "m", "h", "mm":
      return "curlybraces"
    case "cpp", "c", "cc", "hpp":
      return "chevron.left.forwardslash.chevron.right"
    case "py":
      return "terminal.fill"
    case "js", "jsx":
      return "chevron.left.forwardslash.chevron.right"
    case "ts", "tsx":
      return "chevron.left.forwardslash.chevron.right"
    case "html", "htm":
      return "globe"
    case "css", "scss", "sass":
      return "paintbrush.fill"
    case "json":
      return "curlybraces.square.fill"
    case "xml", "plist":
      return "doc.text.image"
    case "md", "markdown":
      return "doc.richtext"

    // MARK: Books

    case "epub", "mobi":
      return "book.fill"

    // MARK: Fonts

    case "ttf", "otf", "woff", "woff2":
      return "textformat"

    // MARK: Database

    case "db", "sqlite", "sql":
      return "cylinder.fill"

    // MARK: System

    case "app", "ipa":
      return "app.fill"
    case "dmg", "pkg":
      return "shippingbox.fill"

    // MARK: Default

    default:
      return "doc.fill"
    }
  }

  // MARK: - Color Mapping

  static func color(for fileName: String, isDirectory: Bool) -> Color {
    if isDirectory {
      return .blue
    }

    let fileExtension = (fileName as NSString).pathExtension.lowercased()

    switch fileExtension {
    // Documents
    case "pdf":
      return .red
    case "doc", "docx", "txt", "rtf", "pages":
      return .blue
    case "xls", "xlsx", "numbers":
      return .green
    case "ppt", "pptx", "key":
      return .orange

    // Images
    case "jpg", "jpeg", "png", "gif", "heic", "heif", "svg", "psd", "bmp":
      return .orange

    // Videos
    case "mp4", "mov", "avi", "mkv", "m4v", "webm":
      return .purple

    // Audio
    case "mp3", "wav", "aac", "m4a", "flac", "aiff":
      return .pink

    // Archives
    case "zip", "cbz", "rar", "cbr", "7z", "cb7", "tar", "cbt", "gz", "bz2", "xz":
      return .gray

    // Code
    case "swift", "m", "h", "mm", "cpp", "c", "cc", "hpp":
      return .orange
    case "py":
      return .blue
    case "js", "jsx", "ts", "tsx":
      return .yellow
    case "html", "htm", "css", "scss", "sass":
      return .cyan
    case "json", "xml", "plist":
      return .green
    case "md", "markdown":
      return .gray

    // Books
    case "epub", "mobi":
      return .brown

    // Fonts
    case "ttf", "otf", "woff", "woff2":
      return .indigo

    // Database
    case "db", "sqlite", "sql":
      return .blue

    // System
    case "app", "ipa", "dmg", "pkg":
      return .blue

    // Default
    default:
      return .gray
    }
  }
}
