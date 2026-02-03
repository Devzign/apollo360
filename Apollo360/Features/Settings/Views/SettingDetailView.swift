import SwiftUI
import WebKit

struct SettingDetailView: View {
    let item: SettingItem
    let htmlContent: String?
    let isLoading: Bool
    let errorMessage: String?
    let reload: () -> Void

    var body: some View {
        ZStack {
            if let htmlContent {
                HTMLContentView(html: htmlContent)
                    .edgesIgnoringSafeArea(.bottom)
            } else if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            } else if let errorMessage {
                VStack(spacing: 14) {
                    Text(errorMessage)
                        .font(AppFont.body(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.red)
                        .multilineTextAlignment(.center)
                    Button("Retry", action: reload)
                        .font(AppFont.body(size: 15, weight: .semibold))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .background(AppColor.green)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding()
            } else {
                Text(item.kind.fallbackDetails)
                    .font(AppFont.body(size: 15))
                    .foregroundStyle(AppColor.grey)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var navigationTitle: String {
        switch item.kind {
        case .terms:
            return "Terms & Conditions"
        case .privacy:
            return "Privacy Policy"
        case .billing:
            return "Billing Statement"
        case .staticItem:
            return item.title
        case .forms:
            return "Forms"
        case .contact:
            return "Contact Us"
        case .creditCard:
            return "My Credit Card"
        case .team:
            return "Team"
        case .caregivers:
            return "Caregivers & Facilities"
        case .notifications:
            return "Notification Settings"
        case .profile:
            return "Profile Settings"
        case .logout:
            return "Logout"
        }
    }
}

private struct HTMLContentView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.showsVerticalScrollIndicator = true
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}
