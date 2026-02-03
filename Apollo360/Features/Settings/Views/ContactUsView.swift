import SwiftUI

struct ContactUsView: View {
    private let addressLines = [
        "Manhattan Cardiovascular Associates / Apollo 360 Health",
        "873 Broadway",
        "New York, NY 10003",
        "(Near Union Square Park)"
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer().frame(height: 16)

                Text("Contact Us")
                    .font(AppFont.display(size: 28, weight: .semibold))
                    .foregroundStyle(AppColor.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(addressLines, id: \.self) { line in
                        Text(line)
                            .font(AppFont.body(size: 16))
                            .foregroundStyle(AppColor.black)
                    }

                    Link("(212) 686-0066", destination: URL(string: "tel:2126860066")!)
                        .font(AppFont.body(size: 16, weight: .semibold))
                        .foregroundStyle(AppColor.green)
                        .underline()
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
                )
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .background(AppColor.secondary.ignoresSafeArea())
        .navigationTitle("Contact Us")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Contact Us") {
    NavigationStack {
        ContactUsView()
    }
}
