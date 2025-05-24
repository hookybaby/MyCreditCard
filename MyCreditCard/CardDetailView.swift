import SwiftUI
import CoreData // Import CoreData

struct CardDetailView: View {
    let card: Card // Property to hold the Card object

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Card Name: \(card.name ?? "N/A")")
                .font(.title2)
            Text("Type: \(card.cardType ?? "N/A")")
                .font(.headline)
            Text("Issuer: \(card.issuer ?? "N/A")")
            Text("Last Four Digits: \(card.lastFourDigits ?? "----")")
            
            if let expiryDate = card.expiryDate {
                Text("Expires: \(expiryDate, style: .date)")
            }

            if let creditCard = card as? CreditCard {
                Text("Credit Limit: \(creditCard.totalCreditLimit, specifier: "%.2f")")
                Text("Statement Day: \(creditCard.statementDayOfMonth)")
                Text("Payment Due Day: \(creditCard.paymentDueDayOfMonth)")
            } else if let debitCard = card as? DebitCard {
                Text("Balance: \(debitCard.balance, specifier: "%.2f")")
                Text("Currency: \(debitCard.currencyCode ?? "N/A")")
            }
            
            Spacer() // Pushes content to the top
        }
        .padding()
        .navigationTitle(card.name ?? "Card Details")
    }
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
