import SwiftUI
import CoreData // Import CoreData

struct CardDetailView: View {
    let card: Card // Property to hold the Card object

    var body: some View {
        let notAvailable = NSLocalizedString("cardDetailView.value.notAvailable", comment: "Fallback for N/A values")
        let defaultNavTitle = NSLocalizedString("cardDetailView.defaultNavigationTitle", comment: "Default navigation title for card details")

        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("cardDetailView.label.cardName")
                    .fontWeight(.semibold)
                Text(card.name ?? notAvailable)
            }
            .font(.title2)
            
            HStack {
                Text("cardDetailView.label.cardType")
                    .fontWeight(.semibold)
                Text(card.cardType ?? notAvailable)
            }
            .font(.headline)

            HStack {
                Text("cardDetailView.label.issuer")
                    .fontWeight(.semibold)
                Text(card.issuer ?? notAvailable)
            }
            
            HStack {
                Text("cardDetailView.label.lastFour")
                    .fontWeight(.semibold)
                Text(card.lastFourDigits ?? NSLocalizedString("cardView.defaultLastFour", comment: "Default last four digits from CardView"))
            }
            
            if let expiryDate = card.expiryDate {
                HStack {
                    Text("cardDetailView.label.expires")
                        .fontWeight(.semibold)
                    Text(expiryDate, style: .date)
                }
            }

            if let creditCard = card as? CreditCard {
                // Credit Limit Section
                HStack {
                    Text("card.detail.totalLimit.label")
                        .fontWeight(.semibold)
                    Text(String(format: NSLocalizedString("currency.format.usd", comment: "USD currency format for amounts"), creditCard.totalCreditLimit))
                }
                HStack {
                    Text("card.detail.usedLimit.label")
                        .fontWeight(.semibold)
                    Text(String(format: NSLocalizedString("currency.format.usd", comment: "USD currency format for amounts"), creditCard.usedCreditLimit))
                }
                HStack {
                    Text("card.detail.availableLimit.label")
                        .fontWeight(.semibold)
                    Text(String(format: NSLocalizedString("currency.format.usd", comment: "USD currency format for amounts"), creditCard.totalCreditLimit - creditCard.usedCreditLimit))
                }

                // Billing Cycle Section
                HStack {
                    Text("card.detail.statementDay.label")
                        .fontWeight(.semibold)
                    Text("\(creditCard.statementDayOfMonth)")
                    Text("card.detail.dayOfMonth.suffix")
                }
                HStack {
                    Text("card.detail.paymentDueDay.label")
                        .fontWeight(.semibold)
                    Text("\(creditCard.paymentDueDayOfMonth)")
                    Text("card.detail.dayOfMonth.suffix")
                }
                HStack {
                    Text("card.detail.gracePeriod.label")
                        .fontWeight(.semibold)
                    if creditCard.gracePeriodDays > 0 {
                        Text("\(creditCard.gracePeriodDays)")
                        Text("card.detail.days.suffix")
                    } else {
                        Text("card.detail.gracePeriod.none")
                    }
                }
                
                // Annual Fee Section
                if creditCard.annualFeeAmount > 0 {
                    HStack {
                        Text("card.detail.annualFee.label")
                            .fontWeight(.semibold)
                        // For now, direct display. Consider localized currency format later.
                        Text("\(creditCard.annualFeeAmount, specifier: "%.2f")")
                    }
                    if let feeDate = creditCard.annualFeeDate {
                        HStack {
                            Text("card.detail.annualFeeDate.label")
                                .fontWeight(.semibold)
                            Text(feeDate, style: .date)
                        }
                    }
                } else {
                    Text("card.detail.annualFee.none")
                        .fontWeight(.semibold)
                }
                
            } else if let debitCard = card as? DebitCard {
                HStack {
                    Text("card.detail.balance.label")
                        .fontWeight(.semibold)
                    Text(String(format: NSLocalizedString("currency.format.usd", comment: "USD currency format for amounts"), debitCard.balance))
                }
                HStack {
                    Text("card.detail.currency.label")
                        .fontWeight(.semibold)
                    Text(debitCard.currencyCode ?? NSLocalizedString("cardDetailView.value.notAvailable", comment: "Fallback for N/A values"))
                }
            }
            
            Spacer() // Pushes content to the top
            
            // Transactions Section
            Section {
                Text("card.detail.transactions.title")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                let transactionsArray = (card.transactions?.allObjects as? [Transaction] ?? []).sorted { $0.date ?? Date() > $1.date ?? Date() }

                if transactionsArray.isEmpty {
                    Text("card.detail.transactions.none")
                        .foregroundColor(.gray)
                } else {
                    List { // Using List for better scrollability and row separation if many transactions
                        ForEach(transactionsArray) { transaction in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(transaction.category ?? NSLocalizedString("transaction.category.unknown", comment: "Unknown category"))
                                        .font(.headline)
                                    Text(transaction.date ?? Date(), style: .date)
                                        .font(.caption)
                                }
                                Spacer()
                                Text(String(format: NSLocalizedString("currency.format.usd.signed", comment: "USD currency format with sign"), transaction.isExpense ? -transaction.amount : transaction.amount))
                                    .foregroundColor(transaction.isExpense ? .red : .green)
                            }
                        }
                    }
                    .frame(minHeight: CGFloat(transactionsArray.count) * 50) // Adjust height dynamically or set a max height
                }
            }
        }
        .padding()
        .navigationTitle(Text(card.name ?? defaultNavTitle))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddTransactionSheet = true
                } label: {
                    Label(LocalizedStringKey("card.detail.addTransaction.button"), systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAddTransactionSheet) {
            AddTransactionView(card: card)
                .environment(\.managedObjectContext, viewContext) // Pass the context
        }
    }
    
    // Need to access viewContext if it's not already available from environment for the sheet
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddTransactionSheet = false
}

struct CardDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // Create a sample CreditCard for preview
        let sampleCreditCard = CreditCard(context: context)
        sampleCreditCard.id = UUID()
        sampleCreditCard.name = "Visa Gold Preview Detail"
        sampleCreditCard.lastFourDigits = "1234"
        sampleCreditCard.cardType = "Credit"
        sampleCreditCard.issuer = "Preview Bank"
        sampleCreditCard.expiryDate = Calendar.current.date(byAdding: .year, value: 2, to: Date())
        sampleCreditCard.createdAt = Date()
        sampleCreditCard.customColorHex = "#1A237E"
        sampleCreditCard.totalCreditLimit = 5000.00
        sampleCreditCard.statementDayOfMonth = 15
        sampleCreditCard.paymentDueDayOfMonth = 10

        return NavigationView {
            CardDetailView(card: sampleCreditCard)
                .environment(\.managedObjectContext, context)
        }
    }
}
