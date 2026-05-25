import SwiftUI

struct CaregiverProvidersPage: View {
    @ObservedObject var viewModel: CaregiversViewModel
    @Environment(\.openURL) private var openURL

    @State private var isPresentingAddProvider = false
    @State private var providerName = ""
    @State private var providerEmail = ""
    @State private var providerFax = ""
    @State private var providerOrganization = ""
    @State private var providerAddress = ""
    @State private var providerPhone = ""
    @State private var sheetProviderError: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                caregiverPageHeader(
                    title: "Healthcare Providers",
                    subtitle: "Provider management and consent actions are separated from caregiver contacts."
                )

                caregiverActionHeader(
                    title: "Providers",
                    countText: "\(viewModel.providers.count)",
                    actionTitle: "Add Provider"
                ) {
                    isPresentingAddProvider = true
                }

                if viewModel.providers.isEmpty {
                    caregiverEmptyState(text: "No providers yet.")
                } else {
                    caregiverListCard {
                        ForEach(viewModel.providers) { provider in
                            caregiverContactRow(
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
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 80)
        }
        .background(AppColor.secondary.ignoresSafeArea())
        .navigationTitle("Healthcare Providers")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingAddProvider) {
            providerFormSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var providerFormSheet: some View {
        caregiverContactFormSheet(
            title: "Add Healthcare Provider",
            icon: "cross.case.fill",
            headerColor: Color(red: 0.22, green: 0.54, blue: 0.78),
            fields: [
                ("Name", $providerName),
                ("Email", $providerEmail),
                ("Organization", $providerOrganization),
                ("Fax", $providerFax),
                ("Address", $providerAddress),
                ("Phone", $providerPhone)
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
                        providerName = ""
                        providerEmail = ""
                        providerFax = ""
                        providerOrganization = ""
                        providerAddress = ""
                        providerPhone = ""
                        sheetProviderError = nil
                        isPresentingAddProvider = false
                    }
                )
            }
        )
        .onChange(of: viewModel.errorMessage) { message in
            if isPresentingAddProvider {
                sheetProviderError = message
            }
        }
    }
}
