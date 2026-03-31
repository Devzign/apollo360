//
//  FormsView.swift
//  Apollo360
//
//  Created by Amit Sinha on 11/01/26.
//

import SwiftUI

struct FormsView: View {
    let horizontalPadding: CGFloat
    @StateObject private var viewModel: FormsViewModel

    init(horizontalPadding: CGFloat, session: SessionManager) {
        self.horizontalPadding = horizontalPadding
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
                        FormDetailView(form: form)
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(form.title)
                    .font(AppFont.display(size: 24, weight: .semibold))
                    .foregroundColor(AppColor.black)

                statusRow

                descriptionSection

                Spacer(minLength: 12)
            }
            .padding(20)
            .background(AppColor.secondary.ignoresSafeArea())
        }
        .navigationTitle("Form Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusRow: some View {
        HStack(spacing: 12) {
            Label(form.signedStatusText, systemImage: form.signed ? "checkmark.seal.fill" : "doc.text")
                .font(AppFont.body(size: 15, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(form.signedStatusColor.opacity(0.18))
                .foregroundColor(form.signedStatusColor)
                .clipShape(Capsule())

            if let signedDate = form.signedDate, !signedDate.isEmpty {
                Text("Signed on \(signedDate)")
                    .font(AppFont.body(size: 14))
                    .foregroundColor(AppColor.grey)
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Description")
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundColor(AppColor.black)

            if let desc = form.description, !desc.isEmpty {
                Text(desc)
                    .font(AppFont.body(size: 14))
                    .foregroundColor(AppColor.black.opacity(0.8))
                    .multilineTextAlignment(.leading)
            } else {
                Text("No description provided.")
                    .font(AppFont.body(size: 14))
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
