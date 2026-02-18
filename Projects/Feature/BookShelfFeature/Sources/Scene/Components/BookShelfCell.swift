import BookDomainInterface
import SwiftUI
import UIKit

// MARK: - BookShelfCell

struct BookShelfCell: View {
  let readInfo: ReadInfo
  var onOpen: (() -> Void)? = nil

  @State private var thumbnail: UIImage?
  @State private var isLoading = false
  @State private var shimmerOffset: CGFloat = -1
  @State private var accentColor: Color = .gray

  // MARK: Private Helpers

  private enum FileKind { case text, pdf, archive, directory, other }

  private var fileKind: FileKind {
    let path = readInfo.pathString ?? ""
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
      return .directory
    }
    let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
    switch ext {
    case "txt", "text", "rtf": return .text
    case "pdf": return .pdf
    case "zip", "cbz", "rar", "cbr", "7z", "cb7", "tar", "cbt", "gz", "bz2", "xz": return .archive
    default: return .other
    }
  }

  private var fileName: String {
    guard let path = readInfo.pathString else { return readInfo.id }
    return (path as NSString).lastPathComponent
  }

  private var fileNameWithoutExtension: String {
    (fileName as NSString).deletingPathExtension
  }

  private var progressFraction: Double {
    guard readInfo.totalPage > 1 else { return readInfo.totalPage == 1 ? 1.0 : 0 }
    return Double(readInfo.readIndex) / Double(readInfo.totalPage - 1)
  }

  private var startDateText: String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateStyle = .short
    return formatter.string(from: readInfo.createDate)
  }

  private var durationText: String {
    guard let endDate = readInfo.readDate else { return "읽는 중" }
    let days = Calendar.current.dateComponents([.day], from: readInfo.createDate, to: endDate).day ?? 0
    if days == 0 { return "당일" }
    if days < 30 { return "\(days)일" }
    return "\(days / 30)개월"
  }

  // MARK: Body

  var body: some View {
    ZStack(alignment: .topTrailing) {
      VStack(spacing: 0) {
        thumbnailView
          .frame(width: 220, height: 192)
          .clipped()

        infoView
          .frame(width: 220, height: 128)
      }

      openButton
        .padding(10)
    }
    .frame(width: 220, height: 320)
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    .shadow(color: accentColor.opacity(0.45), radius: 20, x: 0, y: 10)
    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
    .contentShape(Rectangle())
    .onTapGesture { onOpen?() }
    .task(id: readInfo.id) {
      await loadThumbnail()
    }
  }

  // MARK: Thumbnail

  @ViewBuilder
  private var thumbnailView: some View {
    if fileKind == .text {
      BookTextCoverView(title: fileNameWithoutExtension)
    } else if let image = thumbnail {
      Image(uiImage: image)
        .resizable()
        .scaledToFill()
        .transition(.opacity)
    } else if isLoading {
      shimmerView
    } else {
      fallbackCoverView
    }
  }

  private var shimmerView: some View {
    Rectangle()
      .fill(.quaternary)
      .overlay {
        LinearGradient(
          stops: [
            .init(color: .clear, location: 0),
            .init(color: Color(.tertiarySystemBackground).opacity(0.7), location: 0.5),
            .init(color: .clear, location: 1)
          ],
          startPoint: UnitPoint(x: shimmerOffset - 0.3, y: 0.5),
          endPoint: UnitPoint(x: shimmerOffset + 0.3, y: 0.5)
        )
      }
      .onAppear {
        shimmerOffset = -1
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
          shimmerOffset = 2
        }
      }
      .onDisappear {
        shimmerOffset = -1
      }
  }

  private var fallbackCoverView: some View {
    LinearGradient(
      colors: [Color(.systemGray5), Color(.systemGray4)],
      startPoint: .top,
      endPoint: .bottom
    )
    .overlay {
      Image(systemName: "book.closed")
        .font(.largeTitle)
        .foregroundStyle(.secondary)
    }
  }

  // MARK: Info

  private var infoView: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(fileName)
        .font(.subheadline.bold())
        .lineLimit(2)

      Label(startDateText, systemImage: "calendar.badge.clock")
        .font(.caption2)

      Label(durationText, systemImage: "clock")
        .font(.caption2)

      Spacer(minLength: 4)

      HStack(spacing: 8) {
        GeometryReader { geo in
          ZStack(alignment: .leading) {
            Capsule()
              .fill(.white.opacity(0.25))
              .frame(height: 4)
            Capsule()
              .fill(.white.opacity(0.85))
              .frame(width: geo.size.width * progressFraction, height: 4)
          }
        }
        .frame(height: 4)

        Text("\(Int(progressFraction * 100))%")
          .font(.caption2)
          .fixedSize()
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .foregroundStyle(.white)
    .background(infoBackground)
  }

  private var infoBackground: some View {
    ZStack {
      accentColor.mix(with: Color.black, by: 0.5)
      Rectangle().fill(.ultraThinMaterial.opacity(0.25))
    }
  }

  // MARK: Open Button

  private var openButton: some View {
    Button {
      onOpen?()
    } label: {
      Image(systemName: "arrow.up.right")
        .font(.caption.bold())
        .foregroundStyle(.white)
        .frame(width: 28, height: 28)
        .background(.ultraThinMaterial, in: Circle())
    }
    .buttonStyle(.plain)
  }

  // MARK: Private Methods

  private func loadThumbnail() async {
    guard let path = readInfo.pathString else { return }
    switch fileKind {
    case .text:
      return
    case .pdf, .archive, .directory:
      isLoading = true
      let scale = await MainActor.run { UIScreen.main.scale }
      let image = await CoverImageProvider.shared.cover(for: path, size: CGSize(width: 440, height: 384), scale: scale)
      withAnimation(.easeInOut(duration: 0.3)) { thumbnail = image; isLoading = false }
      if let image { await extractDominantColor(from: image) }
    case .other:
      isLoading = true
      let scale = await MainActor.run { UIScreen.main.scale }
      let image = await ThumbnailCache.shared.thumbnail(for: path, size: CGSize(width: 440, height: 384), scale: scale)
      withAnimation(.easeInOut(duration: 0.3)) { thumbnail = image; isLoading = false }
      if let image { await extractDominantColor(from: image) }
    }
  }

  private func extractDominantColor(from image: UIImage) async {
    let color = await Task.detached(priority: .utility) {
      guard let cgImage = image.cgImage else { return Color.clear }
      let context = CGContext(
        data: nil,
        width: 1,
        height: 1,
        bitsPerComponent: 8,
        bytesPerRow: 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
      context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
      guard let data = context?.data?.assumingMemoryBound(to: UInt8.self) else { return Color.clear }
      let r = Double(data[0]) / 255
      let g = Double(data[1]) / 255
      let b = Double(data[2]) / 255
      return Color(red: r, green: g, blue: b)
    }.value
    withAnimation(.easeInOut(duration: 0.5)) {
      accentColor = color
    }
  }
}
