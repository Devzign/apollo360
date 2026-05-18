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

    @State private var isCaregiverExpanded = true
    @State private var isProviderExpanded = true
    @State private var sheetCaregiverError: String?
    @State private var sheetProviderError: String?

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
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isPresentingAddProvider) {
            addProviderSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("My Contacts")
                .font(AppFont.display(size: 28, weight: .semibold))
                .foregroundColor(AppColor.color414141)

            Text("Manage the caregivers, providers, and permissions that collaborate on your care.")
                .font(AppFont.body(size: 14))
                .foregroundColor(AppColor.grey)
        }
    }

    private var myContactsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.accessLevel)
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundColor(AppColor.black)

            Text("Caregivers: \(viewModel.caregivers.count)\nHealthcare Providers: \(viewModel.providers.count)")
                .font(AppFont.body(size: 14))
                .foregroundColor(AppColor.grey)
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
        sectionContainer(
            title: "My Contacts",
            icon: "person.2.fill",
            isExpanded: isCaregiverExpanded,
            toggleExpansion: { withAnimation { isCaregiverExpanded.toggle() } },
            collapsedInfo: countDescription(viewModel.caregivers.count, singular: "contact"),
            action: {
                isPresentingAddCaregiver = true
            },
            actionTitle: "Add Contact"
        ) {
            if viewModel.caregivers.isEmpty {
                Text("No caregivers yet.")
                    .font(AppFont.body(size: 14))
                    .foregroundColor(AppColor.grey)
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
        sectionContainer(
            title: "Healthcare Providers",
            icon: "cross.case.fill",
            isExpanded: isProviderExpanded,
            toggleExpansion: { withAnimation { isProviderExpanded.toggle() } },
            collapsedInfo: countDescription(viewModel.providers.count, singular: "provider"),
            action: {
                isPresentingAddProvider = true
            },
            actionTitle: "Add Provider"
        ) {
            if viewModel.providers.isEmpty {
                Text("No providers yet.")
                    .font(AppFont.body(size: 14))
                    .foregroundColor(AppColor.grey)
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
                        Button(viewModel.isSigningConsent ? "Signing..." : "Sign Consent Form") {
                            viewModel.signConsent(for: provider)
                        }
                        .disabled(viewModel.isSigningConsent)
                    }
                }
            }
        }
    }

    private func sectionContainer<Content: View>(
        title: String,
        icon: String,
        isExpanded: Bool,
        toggleExpansion: @escaping () -> Void,
        collapsedInfo: String?,
        action: @escaping () -> Void,
        actionTitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: toggleExpansion) {
                    HStack(spacing: 6) {
                        Label(title, systemImage: icon)
                            .font(AppFont.body(size: 17, weight: .semibold))
                            .foregroundColor(AppColor.color414141)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(AppFont.body(size: 12, weight: .semibold))
                            .foregroundColor(AppColor.grey)
                    }
                }
                .buttonStyle(.plain)
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
                    .foregroundColor(AppColor.green)
                    .clipShape(Capsule())
                }
            }

            if isExpanded {
                content()
            } else if let collapsedInfo {
                Text(collapsedInfo)
                    .font(AppFont.body(size: 14))
                    .foregroundColor(AppColor.grey)
            }
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
                .foregroundColor(AppColor.black)
            if let subtitle {
                Text(subtitle)
                    .font(AppFont.body(size: 13))
                    .foregroundColor(AppColor.grey)
            }
            Text(badge)
                .font(AppFont.body(size: 12, weight: .semibold))
                .foregroundColor(AppColor.green)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: deleteAction) {
                Label("Remove", systemImage: "trash")
            }
        }
        .overlay(
            Divider()
                .offset(y: 0.5),
            alignment: .bottom
        )
    }

    private func countDescription(_ count: Int, singular: String) -> String {
        "\(count) \(singular)\(count == 1 ? "" : "s")"
    }

    private var addCaregiverSheet: some View {
        formSheet(
            title: "Add Caregiver",
            icon: "person.badge.plus",
            headerColor: AppColor.green,
            fields: [
                ("First Name", $caregiverFirstName),
                ("Last Name",  $caregiverLastName),
                ("Email",      $caregiverEmail),
                ("Phone",      $caregiverPhone)
            ],
            submitTitle: "Add Caregiver",
            isSubmitting: viewModel.isAddingCaregiver,
            inlineError: sheetCaregiverError,
            onDismiss: { isPresentingAddCaregiver = false },
            submitAction: {
                sheetCaregiverError = nil
                viewModel.addCaregiver(
                    firstName: caregiverFirstName,
                    lastName: caregiverLastName,
                    phone: caregiverPhone,
                    email: caregiverEmail,
                    onSuccess: {
                        resetCaregiverFields()
                        sheetCaregiverError = nil
                        isPresentingAddCaregiver = false
                    }
                )
            }
        )
        .onChange(of: viewModel.errorMessage) { msg in
            if isPresentingAddCaregiver { sheetCaregiverError = msg }
        }
    }

    private var addProviderSheet: some View {
        formSheet(
            title: "Add Healthcare Provider",
            icon: "cross.case.fill",
            headerColor: Color(red: 0.22, green: 0.54, blue: 0.78),
            fields: [
                ("Name",         $providerName),
                ("Email",        $providerEmail),
                ("Organization", $providerOrganization),
                ("Fax",          $providerFax),
                ("Address",      $providerAddress),
                ("Phone",        $providerPhone)
            ],
            submitTitle: "Add Provider",
            isSubmitting: viewModel.isAddingProvider,
            inlineError: sheetProviderError,
            onDismiss: { isPresentingAddProvider = false },
            submitAction: {
                sheetProviderError = nil
                viewModel.addProvider(
                    name: providerName,
                    email: providerEmail,
                    fax: providerFax,
                    organization: providerOrganization,
                    address: providerAddress,
                    phone: providerPhone,
                    onSuccess: {
                        resetProviderFields()
                        sheetProviderError = nil
                        isPresentingAddProvider = false
                    }
                )
            }
        )
        .onChange(of: viewModel.errorMessage) { msg in
            if isPresentingAddProvider { sheetProviderError = msg }
        }
    }

    private func fieldIcon(_ label: String) -> String {
        switch label.lowercased() {
        case let s where s.contains("email"):        return "envelope.fill"
        case let s where s.contains("phone"):        return "phone.fill"
        case let s where s.contains("fax"):          return "printer.fill"
        case let s where s.contains("address"):      return "mappin.circle.fill"
        case let s where s.contains("organization"): return "building.2.fill"
        case let s where s.contains("first"):        return "person.fill"
        case let s where s.contains("last"):         return "person.text.rectangle.fill"
        case let s where s.contains("name"):         return "person.fill"
        default:                                      return "pencil"
        }
    }

    private func fieldColor(_ label: String) -> Color {
        switch label.lowercased() {
        case let s where s.contains("email"):        return Color(red: 0.30, green: 0.55, blue: 0.95)
        case let s where s.contains("phone"):        return Color(red: 0.25, green: 0.72, blue: 0.45)
        case let s where s.contains("fax"):          return Color(red: 0.65, green: 0.45, blue: 0.90)
        case let s where s.contains("address"):      return Color(red: 0.95, green: 0.45, blue: 0.35)
        case let s where s.contains("organization"): return Color(red: 0.92, green: 0.60, blue: 0.20)
        default:                                      return AppColor.green
        }
    }

    private func formSheet(
        title: String,
        icon: String = "plus.circle.fill",
        headerColor: Color = AppColor.green,
        fields: [(String, Binding<String>)],
        submitTitle: String,
        isSubmitting: Bool,
        inlineError: String?,
        onDismiss: (() -> Void)? = nil,
        submitAction: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            // ── Gradient header ──────────────────────────────────────────
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [headerColor, headerColor.opacity(0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 110)

                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.20))
                            .frame(width: 46, height: 46)
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(AppFont.display(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text("Fill in the details below")
                            .font(AppFont.body(size: 12))
                            .foregroundColor(.white.opacity(0.80))
                    }
                    Spacer()
                    if let onDismiss {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.90))
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(Color.white.opacity(0.20)))
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
            }

            // ── Scrollable fields ────────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 14) {
                        ForEach(Array(fields.enumerated()), id: \.offset) { _, pair in
                            let label   = pair.0
                            let binding = pair.1
                            iconField(
                                label: label,
                                binding: binding,
                                icon: fieldIcon(label),
                                iconColor: fieldColor(label)
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 12, y: 4)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 12)

                    // Inline error
                    if let errorMsg = inlineError {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                            Text(errorMsg)
                                .font(AppFont.body(size: 13))
                                .foregroundColor(.red)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }

                    Spacer(minLength: 24)
                }
            }
            .background(AppColor.secondary)

            // ── Sticky save button ───────────────────────────────────────
            Divider()
            Button(action: submitAction) {
                HStack(spacing: 10) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Text(isSubmitting ? "Saving…" : submitTitle)
                        .font(AppFont.body(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSubmitting ? headerColor.opacity(0.60) : headerColor)
                        .shadow(color: headerColor.opacity(0.35), radius: 10, y: 4)
                )
            }
            .disabled(isSubmitting)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
        }
        .background(AppColor.secondary.ignoresSafeArea())
        .ignoresSafeArea(edges: .bottom)
    }

    private func keyboardType(for label: String) -> UIKeyboardType {
        let lower = label.lowercased()
        if lower.contains("phone") || lower.contains("fax") { return .phonePad }
        if lower.contains("email") { return .emailAddress }
        return .default
    }

    private func iconField(label: String, binding: Binding<String>,
                           icon: String, iconColor: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(AppFont.body(size: 11, weight: .semibold))
                    .foregroundColor(AppColor.grey)
                    .textCase(.uppercase)
                    .tracking(0.4)
                TextField(label, text: binding)
                    .font(AppFont.body(size: 15, weight: .medium))
                    .foregroundColor(AppColor.black)
                    .keyboardType(keyboardType(for: label))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
        .padding(.vertical, 10)
        .overlay(Divider(), alignment: .bottom)
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
                .foregroundColor(AppColor.black)
            Text(message)
                .font(AppFont.body(size: 14))
                .foregroundColor(AppColor.red)
            Button("Retry") {
                viewModel.loadContacts(force: true)
            }
            .font(AppFont.body(size: 15, weight: .semibold))
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(AppColor.green)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }
}

#if DEBUG
struct CaregiversView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CaregiversView(session: SessionManager())
        }
    }
}
#endif
