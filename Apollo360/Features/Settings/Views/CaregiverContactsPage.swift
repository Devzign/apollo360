import SwiftUI

struct CaregiverContactsPage: View {
    @ObservedObject var viewModel: CaregiversViewModel

    @State private var isPresentingAddCaregiver = false
    @State private var caregiverFirstName = ""
    @State private var caregiverLastName = ""
    @State private var caregiverEmail = ""
    @State private var caregiverPhone = ""
    @State private var sheetCaregiverError: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                caregiverPageHeader(
                    title: "My Contacts",
                    subtitle: "Keep personal caregivers organized on their own page."
                )

                caregiverActionHeader(
                    title: "Caregivers",
                    countText: "\(viewModel.caregivers.count)",
                    actionTitle: "Add Contact"
                ) {
                    isPresentingAddCaregiver = true
                }

                if viewModel.caregivers.isEmpty {
                    caregiverEmptyState(text: "No caregivers yet.")
                } else {
                    caregiverListCard {
                        ForEach(viewModel.caregivers) { caregiver in
                            caregiverContactRow(
                                title: caregiver.name,
                                subtitle: caregiver.email ?? caregiver.phone,
                                badge: caregiver.isSigned == true ? "Signed" : "Pending"
                            ) {
                                viewModel.deleteCaregiver(caregiver.key)
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
        .navigationTitle("My Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingAddCaregiver) {
            caregiverFormSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var caregiverFormSheet: some View {
        caregiverContactFormSheet(
            title: "Add Caregiver",
            icon: "person.badge.plus",
            headerColor: AppColor.green,
            fields: [
                ("First Name", $caregiverFirstName),
                ("Last Name", $caregiverLastName),
                ("Email", $caregiverEmail),
                ("Phone", $caregiverPhone)
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
                        caregiverFirstName = ""
                        caregiverLastName = ""
                        caregiverEmail = ""
                        caregiverPhone = ""
                        sheetCaregiverError = nil
                        isPresentingAddCaregiver = false
                    }
                )
            }
        )
        .onChange(of: viewModel.errorMessage) { message in
            if isPresentingAddCaregiver {
                sheetCaregiverError = message
            }
        }
    }
}
