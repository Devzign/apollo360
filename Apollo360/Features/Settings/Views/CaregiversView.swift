import SwiftUI

struct CaregiversView: View {
    private let session: SessionManager
    @StateObject private var viewModel: CaregiversViewModel
    @Environment(\.openURL) private var openURL

    @State private var isPresentingAddCaregiver = false
    @State private var caregiverFirstName = ""
    @State private var caregiverLastName = ""
    @State private var caregiverEmail = ""
    @State private var caregiverPhone = ""

    @State private var isPresentingAddProvider = false
    @State private var providerName = ""
    @State private var providerEmail = ""
    @State private var providerFax = ""
    @State private var providerOrganization = ""
    @State private var providerAddress = ""
    @State private var providerPhone = ""

    init(session: SessionManager) {
        self.session = session
        _viewModel = StateObject(wrappedValue: CaregiversViewModel(session: session))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else {
                    myContactsSection
                    caregiverSection
                    providerSection
                }
                Spacer(minLength: 60)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 80)
        }
        .background(AppColor.secondary.ignoresSafeArea())
        .navigationTitle("My Caregivers")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingAddCaregiver) {
            addCaregiverSheet
        }
        .sheet(isPresented: $isPresentingAddProvider) {
            addProviderSheet
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("My Contacts")
                .font(AppFont.display(size: 28, weight: .semibold))
                .foregroundStyle(AppColor.color414141)

            Text("Manage the caregivers, providers, and permissions that collaborate on your care.")
                .font(AppFont.body(size: 14))
                .foregroundStyle(AppColor.grey)
        }
    }

    private var myContactsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.accessLevel)
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundStyle(AppColor.black)

            Text("Caregivers: \(viewModel.caregivers.count)\nHealthcare Providers: \(viewModel.providers.count)")
                .font(AppFont.body(size: 14))
                .foregroundStyle(AppColor.grey)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
        )
    }

    private var caregiverSection: some View {
        sectionContainer(title: "My Contacts", icon: "person.2.fill", action: {
            isPresentingAddCaregiver = true
        }, actionTitle: "Add Contact") {
            if viewModel.caregivers.isEmpty {
                Text("No caregivers yet.")
                    .font(AppFont.body(size: 14))
                    .foregroundStyle(AppColor.grey)
            } else {
                ForEach(viewModel.caregivers) { caregiver in
                    contactRow(
                        title: caregiver.name,
                        subtitle: caregiver.email ?? caregiver.phone ?? nil,
                        badge: caregiver.isSigned == true ? "Signed" : "Pending"
                    ) {
                        viewModel.deleteCaregiver(caregiver.key)
                    }
                }
            }
        }
    }

    private var providerSection: some View {
        sectionContainer(title: "Healthcare Providers", icon: "cross.case.fill", action: {
            isPresentingAddProvider = true
        }, actionTitle: "Add Provider") {
            if viewModel.providers.isEmpty {
                Text("No providers yet.")
                    .font(AppFont.body(size: 14))
                    .foregroundStyle(AppColor.grey)
            } else {
                ForEach(viewModel.providers) { provider in
                    contactRow(
                        title: provider.name,
                        subtitle: provider.organization ?? provider.email ?? provider.phone,
                        badge: provider.signedSend == true && provider.signedReceive == true ? "Fully Signed" : "Pending"
                    ) {
                        viewModel.deleteProvider(provider.key)
                    }
                    .contextMenu {
                        if let url = viewModel.consentURL(for: provider) {
                            Button("View Consent Form") {
                                openURL(url)
                            }
                        }
                    }
                }
            }
        }
    }

    private func sectionContainer<Content: View>(
        title: String,
        icon: String,
        action: @escaping () -> Void,
        actionTitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(AppFont.body(size: 17, weight: .semibold))
                    .foregroundStyle(AppColor.color414141)
                Spacer()
                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text(actionTitle)
                    }
                    .font(AppFont.body(size: 12, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColor.green.opacity(0.18))
                    .foregroundStyle(AppColor.green)
                    .clipShape(Capsule())
                }
            }

            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
        )
    }

    private func contactRow(title: String, subtitle: String?, badge: String, deleteAction: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundStyle(AppColor.black)
            if let subtitle {
                Text(subtitle)
                    .font(AppFont.body(size: 13))
                    .foregroundStyle(AppColor.grey)
            }
            Text(badge)
                .font(AppFont.body(size: 12, weight: .semibold))
                .foregroundStyle(AppColor.green)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .swipeActions {
            Button(role: .destructive, action: deleteAction) {
                Label("Remove", systemImage: "trash")
            }
        }
        .overlay(
            Divider()
                .offset(y: 0.5),
            alignment: .bottom
        )
    }

    private var addCaregiverSheet: some View {
        formSheet(
            title: "Add Caregiver",
            fields: [
                ("First Name", $caregiverFirstName),
                ("Last Name", $caregiverLastName),
                ("Email", $caregiverEmail),
                ("Phone", $caregiverPhone)
            ],
            submitTitle: viewModel.isAddingCaregiver ? "Adding..." : "Add",
            submitAction: {
                viewModel.addCaregiver(
                    firstName: caregiverFirstName,
                    lastName: caregiverLastName,
                    phone: caregiverPhone,
                    email: caregiverEmail
                )
                resetCaregiverFields()
                isPresentingAddCaregiver = false
            }
        )
    }

    private var addProviderSheet: some View {
        formSheet(
            title: "Add Provider",
            fields: [
                ("Name", $providerName),
                ("Email", $providerEmail),
                ("Organization", $providerOrganization),
                ("Fax", $providerFax),
                ("Address", $providerAddress),
                ("Phone", $providerPhone)
            ],
            submitTitle: viewModel.isAddingProvider ? "Adding..." : "Add",
            submitAction: {
                viewModel.addProvider(
                    name: providerName,
                    email: providerEmail,
                    fax: providerFax,
                    organization: providerOrganization,
                    address: providerAddress,
                    phone: providerPhone
                )
                resetProviderFields()
                isPresentingAddProvider = false
            }
        )
    }

    private func formSheet(
        title: String,
        fields: [(String, Binding<String>)],
        submitTitle: String,
        submitAction: @escaping () -> Void
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(AppFont.display(size: 24, weight: .semibold))
                    .foregroundStyle(AppColor.color414141)

            ForEach(fields, id: \.0) { label, binding in
                FormInputField(label: label, value: binding)
            }

                Button(submitTitle, action: submitAction)
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColor.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Spacer()
            }
            .padding()
        }
        .presentationDetents([.medium, .large])
    }

    private func resetCaregiverFields() {
        caregiverFirstName = ""
        caregiverLastName = ""
        caregiverEmail = ""
        caregiverPhone = ""
    }

    private func resetProviderFields() {
        providerName = ""
        providerEmail = ""
        providerFax = ""
        providerOrganization = ""
        providerAddress = ""
        providerPhone = ""
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Text("Couldn't load contacts")
                .font(AppFont.body(size: 18, weight: .semibold))
                .foregroundStyle(AppColor.black)
            Text(message)
                .font(AppFont.body(size: 14))
                .foregroundStyle(AppColor.red)
            Button("Retry") {
                viewModel.loadContacts(force: true)
            }
            .font(AppFont.body(size: 15, weight: .semibold))
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(AppColor.green)
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }
}

#Preview {
    NavigationStack {
        CaregiversView(session: SessionManager())
    }
}
