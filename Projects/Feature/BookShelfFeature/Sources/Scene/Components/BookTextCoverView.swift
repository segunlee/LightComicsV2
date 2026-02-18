import SwiftUI

// MARK: - BookTextCoverView

struct BookTextCoverView: View {
  let title: String

  private static let palettes: [[Color]] = [
    [Color(red: 0.44, green: 0.20, blue: 0.82), Color(red: 0.25, green: 0.35, blue: 0.90)],
    [Color(red: 0.95, green: 0.48, blue: 0.12), Color(red: 0.92, green: 0.20, blue: 0.45)],
    [Color(red: 0.12, green: 0.72, blue: 0.68), Color(red: 0.20, green: 0.80, blue: 0.40)],
    [Color(red: 0.88, green: 0.15, blue: 0.18), Color(red: 0.95, green: 0.48, blue: 0.12)],
    [Color(red: 0.10, green: 0.45, blue: 0.92), Color(red: 0.10, green: 0.78, blue: 0.90)]
  ]

  private var colors: [Color] {
    let index = abs(title.hashValue) % Self.palettes.count
    return Self.palettes[index]
  }

  var body: some View {
    ZStack {
      LinearGradient(
        colors: colors,
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      decorativeLines

      Text(title)
        .font(.system(.headline, design: .serif).bold())
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .lineLimit(5)
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
  }

  private var decorativeLines: some View {
    VStack(spacing: 0) {
      ForEach(0..<4, id: \.self) { index in
        Spacer()
        Rectangle()
          .fill(.white.opacity(0.12))
          .frame(height: 1)
          .padding(.horizontal, index % 2 == 0 ? 12 : 20)
      }
      Spacer()
    }
  }
}
