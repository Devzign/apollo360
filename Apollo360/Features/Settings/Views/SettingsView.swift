//
//  SettingsView.swift
//  Apollo360
//
//  Created by Amit Sinha on 31/01/26.
//

import SwiftUI
import WebKit

struct SettingsView: View {
    let horizontalPadding: CGFloat
    private let session: SessionManager
    @StateObject private var viewModel: SettingsViewModel

    init(horizontalPadding: CGFloat, session: SessionManager) {
        self.horizontalPadding = horizontalPadding
        self.session = session
        _viewModel = StateObject(wrappedValue: SettingsViewModel(session: session))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header

                VStack(spacing: 16) {
                    ForEach(viewModel.items) { item in
                        NavigationLink {
                            destination(for: item)
                        } label: {
                            SettingRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .background(AppColor.secondary.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Apollo 360 Settings")
                .font(AppFont.display(size: 28, weight: .semibold))
                .foregroundStyle(AppColor.green)

            Text("Customize your experience, manage privacy, and review important agreements.")
                .font(AppFont.body(size: 16))
                .foregroundStyle(AppColor.black.opacity(0.78))
        }
    }
}

// MARK: - Row
private struct SettingRow: View {
    let item: SettingItem

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.black)
                    .lineLimit(2)

                Text(item.summary)
                    .font(AppFont.body(size: 13))
                    .foregroundStyle(AppColor.grey)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColor.black.opacity(0.6))
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Detail
private extension SettingsView {
    @ViewBuilder
    func destination(for item: SettingItem) -> some View {
        switch item.kind {
        case .terms, .privacy, .staticItem:
            SettingDetailView(
                item: item,
                htmlContent: viewModel.html(for: item.kind),
                isLoading: viewModel.isLoadingLegal,
                errorMessage: viewModel.errorMessage,
                reload: viewModel.refreshLegal
            )
        case .billing:
            BillingView(session: session)
        }
    }
}

private struct SettingDetailView: View {
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
                Text(item.fallbackDetails)
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
        }
    }
}

// MARK: - HTML Renderer
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

#Preview("Settings - iPhone", traits: .sizeThatFitsLayout) {
    NavigationStack {
        SettingsView(horizontalPadding: 20, session: SessionManager())
            .environment(\.horizontalSizeClass, .compact)
    }
}

#Preview("Settings - iPad", traits: .sizeThatFitsLayout) {
    NavigationStack {
        SettingsView(horizontalPadding: 50, session: SessionManager())
            .environment(\.horizontalSizeClass, .regular)
    }
}
