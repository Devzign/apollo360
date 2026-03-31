import SwiftUI

struct CreditCardView: View {
    private let session: SessionManager
    @StateObject private var viewModel: CreditCardViewModel

    @State private var isPresentingAddSheet = false
    @State private var cardNumber = ""
    @State private var expMonth = ""
    @State private var expYear = ""
    @State private var cvv = ""
    @State private var cardNumberError: String?
    @State private var expiryError: String?
    @State private var cvvError: String?

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
                .foregroundColor(AppColor.color414141)

            Text("Add and manage the cards we can use to process your care transactions.")
                .font(AppFont.body(size: 14))
                .foregroundColor(AppColor.grey)
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
        VStack(alignment: .leading, spacing: 14) {
            Text("Credit Card Information")
                .font(AppFont.display(size: 34, weight: .semibold))
                .foregroundColor(AppColor.color414141)

            Text("Customer Payment Profile ID: \(card.customerPaymentProfileId)")
                .font(AppFont.body(size: 16, weight: .medium))
                .foregroundColor(AppColor.black)

            Text("Card Number: \(card.cardNumber ?? card.maskedNumber)")
                .font(AppFont.body(size: 16, weight: .medium))
                .foregroundColor(AppColor.black)

            Text("Expiration Date: \(card.expiryDisplay)")
                .font(AppFont.body(size: 16, weight: .medium))
                .foregroundColor(AppColor.black)

            Button {
                viewModel.deleteCard(card.id)
            } label: {
                Text("Remove Credit Card")
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 10)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("No cards registered yet.")
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundColor(AppColor.color414141)

            Text("Use the + button to add a new card.")
                .font(AppFont.body(size: 14))
                .foregroundColor(AppColor.grey)
        }
        .padding(.top, 40)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 10) {
            Text("Something went wrong")
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundColor(AppColor.color414141)

            Text(message)
                .font(AppFont.body(size: 14))
                .foregroundColor(AppColor.red)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 20)
    }

    private var floatingAddButton: some View {
        Button(action: { isPresentingAddSheet = true }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
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
                .foregroundColor(AppColor.color414141)

            FormInputField(label: "Card Number", value: $cardNumber, placeholder: "1234 5678 9012 3456", keyboardType: .numberPad)
                .onChange(of: cardNumber) { newValue in
                    cardNumber = formatCardNumber(newValue)
                    cardNumberError = validateCardNumber(cardNumber)
                }
            VStack(alignment: .leading, spacing: 8) {
                Text("Expiration (MM - YY)")
                    .font(AppFont.body(size: 14, weight: .semibold))
                    .foregroundColor(AppColor.grey)

                HStack(spacing: 10) {
                    FormInputField(label: "", value: $expMonth, placeholder: "MM", keyboardType: .numberPad)
                        .onChange(of: expMonth) { newValue in
                            expMonth = sanitizeDigits(newValue, maxLength: 2)
                            expiryError = validateExpiry(month: expMonth, year: expYear)
                        }
                    Text("-")
                        .font(AppFont.body(size: 20, weight: .bold))
                        .foregroundColor(AppColor.grey)
                    FormInputField(label: "", value: $expYear, placeholder: "YY", keyboardType: .numberPad)
                        .onChange(of: expYear) { newValue in
                            expYear = sanitizeDigits(newValue, maxLength: 4)
                            expiryError = validateExpiry(month: expMonth, year: expYear)
                        }
                }
            }
            FormInputField(label: "CVC", value: $cvv, placeholder: "123", keyboardType: .numberPad)
                .onChange(of: cvv) { newValue in
                    cvv = sanitizeDigits(newValue, maxLength: 4)
                    cvvError = validateCVV(cvv)
                }

            if let cardNumberError {
                Text(cardNumberError)
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundColor(AppColor.red)
            }
            if let expiryError {
                Text(expiryError)
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundColor(AppColor.red)
            }
            if let cvvError {
                Text(cvvError)
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundColor(AppColor.red)
            }

            if let error = viewModel.errorMessage, !error.isEmpty {
                Text(error)
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundColor(AppColor.red)
            }

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
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .disabled(viewModel.isSubmitting)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    private func submitCard() {
        cardNumberError = validateCardNumber(cardNumber)
        expiryError = validateExpiry(month: expMonth, year: expYear)
        cvvError = validateCVV(cvv)
        guard cardNumberError == nil, expiryError == nil, cvvError == nil else { return }

        let didSubmit = viewModel.addCard(cardNumber: cardNumber,
                                          month: expMonth,
                                          year: expYear,
                                          cvv: cvv)
        guard didSubmit else { return }
        isPresentingAddSheet = false
        cardNumber = ""
        expMonth = ""
        expYear = ""
        cvv = ""
        cardNumberError = nil
        expiryError = nil
        cvvError = nil
    }

    private func sanitizeDigits(_ value: String, maxLength: Int) -> String {
        let digits = value.filter(\.isNumber)
        return String(digits.prefix(maxLength))
    }

    private func formatCardNumber(_ value: String) -> String {
        let digits = sanitizeDigits(value, maxLength: 19)
        var result = ""
        for (index, character) in digits.enumerated() {
            if index > 0 && index % 4 == 0 {
                result.append(" ")
            }
            result.append(character)
        }
        return result
    }

    private func validateCardNumber(_ formatted: String) -> String? {
        let raw = formatted.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
        guard !raw.isEmpty else { return nil }
        let cardRegex = "^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|2(?:2[2-9][0-9]{12}|[3-6][0-9]{13}|7[01][0-9]{12}|720[0-9]{12})|3[47][0-9]{13}|6(?:011|5[0-9]{2})[0-9]{12}|3(?:0[0-5]|[68][0-9])[0-9]{11}|(?:2131|1800|35\\d{3})\\d{11}|62[0-9]{14,17}|(?:508|60|65|81|82)[0-9]{13})$"
        let valid = NSPredicate(format: "SELF MATCHES %@", cardRegex).evaluate(with: raw)
        if raw.count >= 12 && !valid {
            return "Invalid card number."
        }
        return nil
    }

    private func validateExpiry(month: String, year: String) -> String? {
        if month.isEmpty && year.isEmpty { return nil }
        if !month.isEmpty {
            guard let monthNumber = Int(month), (1...12).contains(monthNumber) else {
                return "Invalid month. Use 01-12."
            }
        }
        if !year.isEmpty && year.count != 2 && year.count != 4 {
            return "Year must be YY or YYYY."
        }
        if month.count == 2 && (year.count == 2 || year.count == 4) {
            let expiryRegex = "^(0[1-9]|1[0-2])\\/(\\d{2}|\\d{4})$"
            let valid = NSPredicate(format: "SELF MATCHES %@", expiryRegex).evaluate(with: "\(month)/\(year)")
            if !valid {
                return "Invalid expiry. Use MM/YY or MM/YYYY."
            }
        }
        return nil
    }

    private func validateCVV(_ value: String) -> String? {
        guard !value.isEmpty else { return nil }
        if value.count < 3 {
            return "CVV must be 3 or 4 digits."
        }
        let valid = NSPredicate(format: "SELF MATCHES %@", "^\\d{3,4}$").evaluate(with: value)
        return valid ? nil : "Invalid CVV."
    }
}

#if DEBUG
struct CreditCardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CreditCardView(session: SessionManager())
        }
        .previewDisplayName("Credit Cards")
    }
}
#endif
