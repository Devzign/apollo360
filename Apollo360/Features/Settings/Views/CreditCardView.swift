import SwiftUI

struct CreditCardView: View {
    private let session: SessionManager
    @StateObject private var viewModel: CreditCardViewModel

    @State private var isPresentingAddSheet = false
    @State private var cardNumber = ""
    @State private var expMonth = ""
    @State private var expYear = ""
    @State private var cvv = ""

    init(session: SessionManager) {
        self.session = session
        _viewModel = StateObject(wrappedValue: CreditCardViewModel(session: session))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    header

                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .padding(.top, 40)
                    } else if let error = viewModel.errorMessage {
                        errorView(message: error)
                    } else if viewModel.cards.isEmpty {
                        emptyState
                    } else {
                        cardList
                    }

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 80)
            }

            floatingAddButton
        }
        .background(AppColor.secondary.ignoresSafeArea())
        .navigationTitle("Credit Card Authorization")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingAddSheet) {
            addCardSheet
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Credit Card Information")
                .font(AppFont.display(size: 28, weight: .semibold))
                .foregroundStyle(AppColor.color414141)

            Text("Add and manage the cards we can use to process your care transactions.")
                .font(AppFont.body(size: 14))
                .foregroundStyle(AppColor.grey)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cardList: some View {
        VStack(spacing: 14) {
            ForEach(viewModel.cards) { card in
                cardRow(for: card)
            }
        }
    }

    private func cardRow(for card: CreditCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.maskedNumber)
                .font(AppFont.body(size: 18, weight: .semibold))
                .foregroundStyle(AppColor.black)

            Text(card.expiryDisplay)
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
        .swipeActions {
            Button(role: .destructive) {
                viewModel.deleteCard(card.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("No cards registered yet.")
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundStyle(AppColor.color414141)

            Text("Use the + button to add a new card.")
                .font(AppFont.body(size: 14))
                .foregroundStyle(AppColor.grey)
        }
        .padding(.top, 40)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 10) {
            Text("Something went wrong")
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundStyle(AppColor.color414141)

            Text(message)
                .font(AppFont.body(size: 14))
                .foregroundStyle(AppColor.red)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 20)
    }

    private var floatingAddButton: some View {
        Button(action: { isPresentingAddSheet = true }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(AppColor.green)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 6)
        }
        .padding()
    }

    private var addCardSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Add Card")
                .font(AppFont.display(size: 24, weight: .semibold))
                .foregroundStyle(AppColor.color414141)

            FormInputField(label: "Card Number", value: $cardNumber, placeholder: "1234 5678 9012 3456", keyboardType: .numberPad)
            FormInputField(label: "Expiration Month (MM)", value: $expMonth, placeholder: "MM", keyboardType: .numberPad)
            FormInputField(label: "Expiration Year (YY)", value: $expYear, placeholder: "YY", keyboardType: .numberPad)
            FormInputField(label: "CVC", value: $cvv, placeholder: "123", keyboardType: .numberPad)

            Button(action: submitCard) {
                if viewModel.isSubmitting {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Submit")
                        .font(AppFont.body(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(AppColor.green)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .disabled(viewModel.isSubmitting)

            Spacer()
        }
        .padding()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.isSubmitting)
    }

    private func submitCard() {
        isPresentingAddSheet = false
        viewModel.addCard(cardNumber: cardNumber,
                          month: expMonth,
                          year: expYear,
                          cvv: cvv)
        cardNumber = ""
        expMonth = ""
        expYear = ""
        cvv = ""
    }
}

#Preview("Credit Cards") {
    NavigationStack {
        CreditCardView(session: SessionManager())
    }
}
