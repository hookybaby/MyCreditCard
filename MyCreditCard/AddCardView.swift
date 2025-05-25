import SwiftUI
import CoreData // Import CoreData

struct AddCardView: View {
    @Environment(\.managedObjectContext) private var viewContext // Access Core Data context
    @Environment(\.presentationMode) var presentationMode

    // Card Type Picker
    enum CardType: String, CaseIterable, Identifiable {
        case credit // Raw value will be used for logic, localization key for display
        case debit
        var id: String { self.rawValue }

        func localizedString() -> LocalizedStringKey {
            switch self {
            case .credit:
                return "addCardView.picker.cardType.option.credit"
            case .debit:
                return "addCardView.picker.cardType.option.debit"
            }
        }
    }
    @State private var selectedCardType: CardType = .credit

    // Common Fields
    @State private var cardName: String = ""
    @State private var issuer: String = ""
    @State private var lastFourDigits: String = ""
    @State private var expiryDate: Date = Date()
    @State private var customColorHex: String = "" // Added for completeness with model

    // Credit Card Specific Fields
    @State private var totalCreditLimit: String = ""
    @State private var statementDayOfMonth: String = ""
    @State private var paymentDueDayOfMonth: String = ""
    @State private var gracePeriodDays: String = ""
    @State private var annualFeeAmount: String = ""
    @State private var nextAnnualFeeDate: Date = Date()
    @State private var hasAnnualFeeDate: Bool = false

    // Debit Card Specific Fields
    @State private var currentBalance: String = ""
    @State private var currencyCode: String = "USD"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("addCardView.section.cardDetails")) {
                    Picker(Text("addCardView.picker.cardType.label"), selection: $selectedCardType) {
                        ForEach(CardType.allCases) { type in
                            Text(type.localizedString()).tag(type)
                        }
                    }

                    TextField(LocalizedStringKey("addCardView.textField.cardName.placeholder"), text: $cardName)
                    TextField(LocalizedStringKey("addCardView.textField.issuer.placeholder"), text: $issuer)
                    TextField(LocalizedStringKey("addCardView.textField.lastFour.placeholder"), text: $lastFourDigits)
                        .keyboardType(.numberPad)
                    DatePicker(LocalizedStringKey("addCardView.datePicker.expiryDate.label"), selection: $expiryDate, displayedComponents: .date)
                    TextField(LocalizedStringKey("addCardView.textField.customColorHex.placeholder"), text: $customColorHex)
                }

                if selectedCardType == .credit {
                    Section(header: Text("addCardView.section.creditCardSpecifics")) {
                        TextField(LocalizedStringKey("addCardView.textField.totalCreditLimit.placeholder"), text: $totalCreditLimit)
                            .keyboardType(.decimalPad)
                        TextField(LocalizedStringKey("addCardView.textField.statementDay.placeholder"), text: $statementDayOfMonth)
                            .keyboardType(.numberPad)
                        TextField(LocalizedStringKey("addCardView.textField.paymentDueDay.placeholder"), text: $paymentDueDayOfMonth)
                            .keyboardType(.numberPad)
                        TextField(LocalizedStringKey("addCardView.textField.gracePeriod.placeholder"), text: $gracePeriodDays)
                            .keyboardType(.numberPad)
                        TextField(LocalizedStringKey("addCardView.textField.annualFeeAmount.placeholder"), text: $annualFeeAmount)
                            .keyboardType(.decimalPad)
                        
                        Toggle(isOn: $hasAnnualFeeDate) {
                            Text("addCardView.toggle.setAnnualFeeDate.label")
                        }
                        if hasAnnualFeeDate {
                            DatePicker(LocalizedStringKey("addCardView.datePicker.annualFeeDate.label"), selection: $nextAnnualFeeDate, displayedComponents: .date)
                        }
                    }
                } else if selectedCardType == .debit {
                    Section(header: Text("addCardView.section.debitCardSpecifics")) {
                        TextField(LocalizedStringKey("addCardView.textField.currentBalance.placeholder"), text: $currentBalance)
                            .keyboardType(.decimalPad)
                        TextField(LocalizedStringKey("addCardView.textField.currencyCode.placeholder"), text: $currencyCode)
                    }
                }
            }
            .navigationTitle(Text("addCardView.navigationTitle"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("addCardView.button.cancel")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveCard()
                        // Dismissal is handled after saveCard completes or in case of error
                    }) {
                        Text("addCardView.button.save")
                    }
                }
            }
        }
    }

    private func saveCard() {
        let newCardId = UUID()
        let newCardCreatedAt = Date()

        switch selectedCardType {
        case .credit:
            let newCreditCard = CreditCard(context: viewContext)
            newCreditCard.id = newCardId
            newCreditCard.createdAt = newCardCreatedAt
            newCreditCard.cardType = "Credit" // Set card type string
            
            newCreditCard.name = cardName
            newCreditCard.issuer = issuer.isEmpty ? nil : issuer
            newCreditCard.lastFourDigits = lastFourDigits // Basic assignment, consider validation
            newCreditCard.expiryDate = expiryDate
            newCreditCard.customColorHex = customColorHex.isEmpty ? nil : customColorHex

            newCreditCard.totalCreditLimit = Double(totalCreditLimit) ?? 0.0
            newCreditCard.statementDayOfMonth = Int16(statementDayOfMonth) ?? 0 // Default to 0 if invalid
            newCreditCard.paymentDueDayOfMonth = Int16(paymentDueDayOfMonth) ?? 0 // Default to 0 if invalid
            newCreditCard.gracePeriodDays = Int16(gracePeriodDays) ?? 0
            newCreditCard.annualFeeAmount = Double(annualFeeAmount) ?? 0.0
            if hasAnnualFeeDate {
                newCreditCard.annualFeeDate = nextAnnualFeeDate
            } else {
                newCreditCard.annualFeeDate = nil
            }
            // usedCreditLimit and rewardsPointsBalance will use their default values from the model

        case .debit:
            let newDebitCard = DebitCard(context: viewContext)
            newDebitCard.id = newCardId
            newDebitCard.createdAt = newCardCreatedAt
            newDebitCard.cardType = "Debit" // Set card type string

            newDebitCard.name = cardName
            newDebitCard.issuer = issuer.isEmpty ? nil : issuer
            newDebitCard.lastFourDigits = lastFourDigits // Basic assignment, consider validation
            newDebitCard.expiryDate = expiryDate
            newDebitCard.customColorHex = customColorHex.isEmpty ? nil : customColorHex
            
            newDebitCard.balance = Double(currentBalance) ?? 0.0
            newDebitCard.currencyCode = currencyCode.isEmpty ? "USD" : currencyCode // Default to USD
        }

        do {
            try viewContext.save()
            print("Card saved successfully!")
            presentationMode.wrappedValue.dismiss() // Dismiss on successful save
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
            // Optionally, present an alert to the user here
            // For now, sheet will remain for correction if save fails.
        }
    }
}

struct AddCardView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a mock context for preview if needed, or ensure PersistenceController.preview is set up
        AddCardView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
