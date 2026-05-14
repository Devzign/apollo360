//
//  FormsView.swift
//  Apollo360
//
//  Created by Amit Sinha on 11/01/26.
//

import Combine
import SwiftUI
import Foundation

struct FormsView: View {
    let horizontalPadding: CGFloat
    private let session: SessionManager
    @StateObject private var viewModel: FormsViewModel

    init(horizontalPadding: CGFloat, session: SessionManager) {
        self.horizontalPadding = horizontalPadding
        self.session = session
        _viewModel = StateObject(wrappedValue: FormsViewModel(session: session))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header

                content

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
            Text("Apollo 360 Health Forms")
                .font(AppFont.display(size: 28, weight: .semibold))
                .foregroundColor(AppColor.green)

            Text("Please take a moment to carefully read and sign our patient forms.")
                .font(AppFont.body(size: 16))
                .foregroundColor(AppColor.black.opacity(0.78))
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            loadingPlaceholder
        } else if let error = viewModel.errorMessage {
            errorState(error)
        } else if viewModel.forms.isEmpty {
            emptyState
        } else {
            VStack(spacing: 16) {
                ForEach(viewModel.forms) { form in
                    NavigationLink {
                        FormDetailView(form: form, session: session)
                    } label: {
                        FormRow(form: form)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var loadingPlaceholder: some View {
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.white.opacity(0.92))
                        .frame(height: 88)
                        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
                        .overlay(
                            HStack(spacing: 14) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColor.secondary.opacity(0.5))
                                    .frame(width: 56, height: 56)
                                VStack(alignment: .leading, spacing: 10) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AppColor.secondary.opacity(0.5))
                                        .frame(width: 180, height: 12)
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AppColor.secondary.opacity(0.35))
                                        .frame(width: 120, height: 10)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 18)
                        )
                        .shimmer()
                }
            }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text("Couldn't load forms")
                .font(AppFont.display(size: 18, weight: .semibold))
                .foregroundColor(AppColor.black)
            Text(message)
                .font(AppFont.body(size: 14))
                .foregroundColor(AppColor.red)
            Button("Retry") {
                viewModel.refresh()
            }
            .font(AppFont.body(size: 15, weight: .semibold))
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(AppColor.green)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 32)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("No Form Data Available")
                .font(AppFont.body(size: 15, weight: .semibold))
                .foregroundColor(AppColor.black)
            Text("Check back later or pull to refresh.")
                .font(AppFont.body(size: 14))
                .foregroundColor(AppColor.grey)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 28)
    }
}

private struct FormRow: View {
    let form: PatientForm

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(form.signedStatusColor.opacity(0.14))
                .frame(width: 54, height: 54)
                .overlay(
                    Image(systemName: form.signed ? "checkmark.seal.fill" : "doc.plaintext")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(form.signed ? AppColor.green : AppColor.grey)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(form.title)
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.black)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(form.signedStatusText)
                        .font(AppFont.body(size: 12, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(form.signedStatusColor.opacity(0.15))
                        .foregroundColor(form.signedStatusColor)
                        .clipShape(Capsule())

                    if let signedDate = form.signedDate, !signedDate.isEmpty {
                        Text("Signed: \(signedDate)")
                            .font(AppFont.body(size: 12))
                            .foregroundColor(AppColor.grey)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppColor.black.opacity(0.6))
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
        )
    }
}

private struct FormDetailView: View {
    let form: PatientForm
    @StateObject private var viewModel: FormDetailViewModel

    init(form: PatientForm, session: SessionManager) {
        self.form = form
        _viewModel = StateObject(wrappedValue: FormDetailViewModel(form: form, session: session))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(form.title)
                    .font(AppFont.display(size: 24, weight: .semibold))
                    .foregroundColor(AppColor.black)

                if viewModel.isLoading {
                    ProgressView("Loading form...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
                } else if let error = viewModel.errorMessage {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(error)
                            .font(AppFont.body(size: 14))
                            .foregroundColor(AppColor.red)

                        Button("Retry") {
                            viewModel.load()
                        }
                        .font(AppFont.body(size: 14, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AppColor.green)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                } else {
                    statusRow
                    subFormsSection
                }

                Spacer(minLength: 12)
            }
            .padding(20)
            .background(AppColor.secondary.ignoresSafeArea())
        }
        .navigationTitle("Form Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
    }

    private var statusRow: some View {
        HStack(spacing: 12) {
            Label(viewModel.groupFullySigned ? "Signed" : "Pending", systemImage: viewModel.groupFullySigned ? "checkmark.seal.fill" : "doc.text")
                .font(AppFont.body(size: 15, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background((viewModel.groupFullySigned ? AppColor.green : AppColor.yellow).opacity(0.18))
                .foregroundColor(viewModel.groupFullySigned ? AppColor.green : AppColor.yellow)
                .clipShape(Capsule())

            if let signedDate = viewModel.lastSignedDate, !signedDate.isEmpty {
                Text("Signed on \(signedDate)")
                    .font(AppFont.body(size: 14))
                    .foregroundColor(AppColor.grey)
            }
        }
    }

    private var subFormsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Documents")
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundColor(AppColor.black)

            ForEach(Array(viewModel.subForms.enumerated()), id: \.element.id) { index, subForm in
                subFormCard(subForm, index: index)
            }
        }
    }

    private func subFormCard(_ subForm: PatientSubForm, index: Int) -> some View {
        NavigationLink {
            PatientSubFormDetailView(
                subForm: subForm,
                actionTitle: viewModel.buttonTitle(for: index),
                isSigning: viewModel.signingFormIDs.contains(subForm.id),
                onSign: { viewModel.sign(subForm: subForm) }
            )
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(subForm.title)
                            .font(AppFont.body(size: 16, weight: .semibold))
                            .foregroundColor(AppColor.black)

                        Text(subForm.signed ? "Signed" : "Pending")
                            .font(AppFont.body(size: 12, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background((subForm.signed ? AppColor.green : AppColor.yellow).opacity(0.15))
                            .foregroundColor(subForm.signed ? AppColor.green : AppColor.yellow)
                            .clipShape(Capsule())
                    }

                    Spacer(minLength: 12)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColor.black.opacity(0.4))
                }

                HTMLPreviewText(
                    html: subForm.body,
                    fontSize: 14,
                    textColor: UIColor(AppColor.black.opacity(0.82)),
                    lineLimit: 3
                )

                if let signedDate = subForm.signedDate, !signedDate.isEmpty {
                    Text("Signed on \(signedDate)")
                        .font(AppFont.body(size: 12))
                        .foregroundColor(AppColor.grey)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PatientSubFormDetailView: View {
    let subForm: PatientSubForm
    let actionTitle: String
    let isSigning: Bool
    let onSign: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(subForm.title)
                            .font(AppFont.display(size: 24, weight: .semibold))
                            .foregroundColor(AppColor.black)

                        Text(subForm.signed ? "Signed" : "Pending")
                            .font(AppFont.body(size: 12, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background((subForm.signed ? AppColor.green : AppColor.yellow).opacity(0.15))
                            .foregroundColor(subForm.signed ? AppColor.green : AppColor.yellow)
                            .clipShape(Capsule())
                    }

                    Spacer(minLength: 12)

                    if subForm.signatureRequired && !subForm.signed {
                        Button(actionTitle, action: onSign)
                            .font(AppFont.body(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background(AppColor.green)
                            .clipShape(Capsule())
                            .disabled(isSigning)
                            .opacity(isSigning ? 0.6 : 1)
                    }
                }

                HTMLPreviewText(
                    html: subForm.body,
                    fontSize: 14,
                    textColor: UIColor(AppColor.black.opacity(0.82))
                )

                if let signedDate = subForm.signedDate, !signedDate.isEmpty {
                    Text("Signed on \(signedDate)")
                        .font(AppFont.body(size: 12))
                        .foregroundColor(AppColor.grey)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
            )
            .padding(20)
        }
        .background(AppColor.secondary.ignoresSafeArea())
        .navigationTitle("Document Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HTMLPreviewText: View {
    let html: String
    let fontSize: CGFloat
    let textColor: UIColor
    var lineLimit: Int? = nil

    var body: some View {
        if let attributed = html.htmlAttributedString(fontSize: fontSize, textColor: textColor),
           let swiftAttributed = try? AttributedString(attributed, including: \.foundation) {
            Text(swiftAttributed)
                .lineLimit(lineLimit)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(html.htmlPlainText)
                .font(AppFont.body(size: fontSize))
                .foregroundColor(Color(textColor))
                .lineLimit(lineLimit)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private extension String {
    func htmlAttributedString(fontSize: CGFloat, textColor: UIColor) -> NSAttributedString? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let css = """
        <style>
        body { font-family: -apple-system; font-size: \(fontSize)px; color: \(textColor.hexString); margin: 0; padding: 0; }
        p { margin: 0 0 10px 0; }
        </style>
        """
        let wrappedHTML = "<html><head>\(css)</head><body>\(trimmed)</body></html>"
        guard let wrappedData = wrappedHTML.data(using: .utf8) else { return nil }

        return try? NSAttributedString(
            data: wrappedData,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
    }

    var htmlPlainText: String {
        let withBreaks = self
            .replacingOccurrences(of: "<br>", with: "\n", options: [.caseInsensitive, .regularExpression])
            .replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "</p>", with: "\n", options: [.caseInsensitive, .regularExpression])
            .replacingOccurrences(of: "<p[^>]*>", with: "", options: [.caseInsensitive, .regularExpression])
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")

        let stripped = withBreaks.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // Normalize excessive blank lines for card previews.
        let normalized = stripped.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension UIColor {
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

private struct PatientSubForm: Identifiable {
    let id: Int
    let title: String
    let body: String
    let signed: Bool
    let signedDate: String?
    let signatureRequired: Bool
}

@MainActor
private final class FormDetailViewModel: ObservableObject {
    @Published private(set) var subForms: [PatientSubForm] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var groupFullySigned = false
    @Published private(set) var lastSignedDate: String?
    @Published private(set) var signingFormIDs: Set<Int> = []
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""

    private let form: PatientForm
    private let session: SessionManager
    private let service: FormsAPIService
    private var hasLoaded = false

    init(form: PatientForm,
         session: SessionManager,
         service: FormsAPIService? = nil) {
        self.form = form
        self.session = session
        self.service = service ?? .shared
    }

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        load()
    }

    func load() {
        guard let token = session.accessToken else {
            errorMessage = "You're not signed in."
            return
        }

        isLoading = true
        errorMessage = nil
        service.fetchPatientFormDetail(id: form.id, bearerToken: token) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let group):
                self.groupFullySigned = group.groupFullySigned
                self.subForms = group.forms.map {
                    PatientSubForm(
                        id: $0.id,
                        title: $0.title,
                        body: $0.body,
                        signed: $0.signed,
                        signedDate: $0.signedDate,
                        signatureRequired: $0.signatureRequired
                    )
                }
                self.lastSignedDate = self.subForms.last(where: { $0.signed })?.signedDate
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.subForms = []
            }
        }
    }

    func sign(subForm: PatientSubForm) {
        guard let token = session.accessToken else {
            alertTitle = "Sign In Required"
            alertMessage = "You're not signed in."
            showAlert = true
            return
        }

        signingFormIDs.insert(subForm.id)
        service.signPatientForm(id: subForm.id, bearerToken: token) { [weak self] result in
            guard let self else { return }
            self.signingFormIDs.remove(subForm.id)
            switch result {
            case .success(let response):
                self.alertTitle = response.success ? "Success" : "Unable to Sign"
                self.alertMessage = response.message
                self.showAlert = true
                self.load()
            case .failure(let error):
                self.alertTitle = "Unable to Sign"
                self.alertMessage = error.localizedDescription
                self.showAlert = true
            }
        }
    }

    func buttonTitle(for index: Int) -> String {
        guard index == subForms.indices.last else { return "Initial" }
        return "Sign"
    }
}

#if DEBUG
struct FormsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                FormsView(horizontalPadding: 20, session: SessionManager())
                    .environment(\.horizontalSizeClass, .compact)
            }
            .previewDisplayName("iPhone")

            NavigationView {
                FormsView(horizontalPadding: 50, session: SessionManager())
                    .environment(\.horizontalSizeClass, .regular)
            }
            .previewDisplayName("iPad")
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
