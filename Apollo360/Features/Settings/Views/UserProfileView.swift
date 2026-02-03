import SwiftUI
import PhotosUI
import UIKit

struct UserProfileView: View {
    @StateObject private var viewModel: UserProfileViewModel
    @State private var name = ""
    @State private var dob = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var avatarImage: Image?

    init(session: SessionManager) {
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(session: session))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                profileHeader

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else {
                    profileCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(AppColor.secondary.ignoresSafeArea())
        .navigationTitle("User Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let profile = viewModel.profile {
                updateFields(with: profile)
            }
        }
        .onReceive(viewModel.$profile) { profile in
            guard let profile else { return }
            updateFields(with: profile)
        }
        .onChange(of: photoPickerItem) { item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    avatarImage = Image(uiImage: uiImage)
                }
            }
        }
    }

    private var profileHeader: some View {
        Text("User Profile")
            .font(AppFont.display(size: 28, weight: .semibold))
            .foregroundStyle(AppColor.green)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var profileCard: some View {
        VStack(spacing: 20) {
            avatarView

            HStack(spacing: 12) {
                PhotosPicker(selection: $photoPickerItem, matching: .images, photoLibrary: .shared()) {
                    Text("Choose File")
                        .font(AppFont.body(size: 13, weight: .semibold))
                        .foregroundStyle(AppColor.green)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppColor.green, lineWidth: 1)
                        )
                }

                Text(photoPickerItem == nil ? "no file selected" : "file selected")
                    .font(AppFont.body(size: 13))
                    .foregroundStyle(AppColor.grey)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
            )

            VStack(spacing: 16) {
                ProfileField(label: "Name", value: name)
                ProfileField(label: "DOB *", value: dob)
                ProfileField(label: "Email", value: email)
                ProfileField(label: "Phone No.", value: phone)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 10)
        )
    }

    private var avatarView: some View {
        Group {
            if let avatarImage {
                avatarImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
            } else if let urlString = viewModel.profile?.avatarUrl,
                      let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    placeholderAvatar
                }
                .frame(width: 110, height: 110)
                .clipShape(Circle())
            } else {
                placeholderAvatar
            }
        }
    }

    private var placeholderAvatar: some View {
        Circle()
            .fill(AppColor.colorECF0F3)
            .frame(width: 110, height: 110)
            .overlay(
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(24)
                    .foregroundStyle(AppColor.green)
            )
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Text(message)
                .font(AppFont.body(size: 15, weight: .semibold))
                .foregroundStyle(AppColor.red)
                .multilineTextAlignment(.center)

            Button("Retry", action: { viewModel.loadProfile(force: true) })
                .font(AppFont.body(size: 15, weight: .semibold))
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(AppColor.green)
                .foregroundStyle(.white)
                .clipShape(Capsule())
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    private func updateFields(with profile: Profile) {
        name = profile.displayName
        dob = profile.dateOfBirth ?? ""
        email = profile.email
        phone = profile.phone ?? ""
    }
}

private struct ProfileField: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AppFont.body(size: 12, weight: .semibold))
                .foregroundStyle(AppColor.grey)

            Text(value.isEmpty ? "—" : value)
                .font(AppFont.body(size: 16))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppColor.colorECF0F3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppColor.grey.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
}
