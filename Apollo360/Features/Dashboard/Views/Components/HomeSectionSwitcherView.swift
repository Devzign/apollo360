import SwiftUI

struct HomeSectionSwitcherView: View {
    @Binding var selection: HomeSection

    var body: some View {
        GeometryReader { geo in
            let count = CGFloat(HomeSection.allCases.count)
            let tabW = geo.size.width / count
            let selIdx = CGFloat(HomeSection.allCases.firstIndex(of: selection) ?? 0)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColor.green)
                    .frame(width: tabW - 4, height: geo.size.height - 4)
                    .offset(x: selIdx * tabW + 2, y: 2)
                    .animation(.spring(response: 0.32, dampingFraction: 0.78), value: selection)
                    .shadow(color: AppColor.green.opacity(0.30), radius: 8, y: 3)

                HStack(spacing: 0) {
                    ForEach(HomeSection.allCases, id: \.self) { section in
                        let isSelected = selection == section
                        Button {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                selection = section
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: sectionIcon(section))
                                    .font(.system(size: 11, weight: .semibold))
                                Text(section.rawValue)
                                    .font(AppFont.body(size: 13, weight: isSelected ? .semibold : .medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundColor(isSelected ? .white : AppColor.color414141.opacity(0.50))
                            .frame(maxWidth: .infinity)
                            .frame(height: geo.size.height)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.18), value: isSelected)
                    }
                }
            }
        }
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 10, y: 3)
        )
    }

    private func sectionIcon(_ section: HomeSection) -> String {
        switch section {
        case .plans: return "list.bullet.rectangle"
        case .feeling: return "heart.fill"
        case .activities: return "bolt.fill"
        }
    }
}
