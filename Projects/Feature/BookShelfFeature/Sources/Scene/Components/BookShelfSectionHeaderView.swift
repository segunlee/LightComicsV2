import SwiftUI

// MARK: - BookShelfSectionHeaderView

struct BookShelfSectionHeaderView: View {
  let title: String
  let itemCount: Int

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Text(title)
        .font(.title3)
        .fontWeight(.bold)
        .foregroundStyle(.primary)

      Text("\(itemCount)")
        .font(.caption2)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(.fill.tertiary, in: Capsule())

      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.top, 20)
    .padding(.bottom, 4)
  }
}
