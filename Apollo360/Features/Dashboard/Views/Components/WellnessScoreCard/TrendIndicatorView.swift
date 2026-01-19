import SwiftUI

struct TrendIndicatorView: View {
    let isImproving: Bool
    @State private var isAnimating = false
    private let size: CGFloat = 32

    var body: some View {
        Image("arrow_relative")
            .resizable()
            .renderingMode(.template)
            .frame(width: 46, height: size)
            .foregroundStyle(isImproving ? AppColor.green : AppColor.red)
            .rotationEffect(isImproving ? .zero : .degrees(180))
            .offset(x: isAnimating ? 6 : 0)
            .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear { isAnimating = true }
    }
}

struct TrendIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        ViralTrendPreview()
            .padding()
            .previewLayout(.sizeThatFits)
    }

    private struct ViralTrendPreview: View {
        @State private var improving = true

        var body: some View {
            TrendIndicatorView(isImproving: improving)
                .onTapGesture {
                    improving.toggle()
                }
        }
    }
}
