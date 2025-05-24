import SwiftUI
import CoreData // Import CoreData for Card entity

struct CardView: View {
    let card: Card // Property to hold the Card object

    // Helper to convert hex string to Color
    private func colorFromHex(_ hexString: String?) -> Color {
        guard let hex = hexString?.trimmingCharacters(in: CharacterSet.alphanumerics.inverted) else {
            return Color.gray // Default color if hex is nil or invalid
        }
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return Color.gray // Default color
        }
        return Color(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
    
    // Determine foreground color based on background brightness (simple heuristic)
    private func foregroundColor(for backgroundColor: Color) -> Color {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        guard UIColor(backgroundColor).getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return .white // Default to white if color conversion fails
        }
        
        // Calculate luminance
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.5 ? .black : .white // Use black for light backgrounds, white for dark
    }

    var body: some View {
        let cardBackgroundColor = colorFromHex(card.customColorHex)
        let cardForegroundColor = foregroundColor(for: cardBackgroundColor)

        RoundedRectangle(cornerRadius: 10)
            .fill(cardBackgroundColor)
            .frame(height: 150)
            .overlay(
                VStack(alignment: .leading) {
                    Text(card.name ?? "Unnamed Card")
                        .font(.headline)
                        .foregroundColor(cardForegroundColor)
                    
                    Spacer()
                    
                    Text("•••• \(card.lastFourDigits ?? "----")")
                        .font(.title2)
                        .foregroundColor(cardForegroundColor)
                    
                    Spacer()
                    
                    Text(card.cardType ?? "Unknown Type")
                        .font(.caption)
                        .foregroundColor(cardForegroundColor)
                }
                .padding()
            )
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample Card for preview
        let context = PersistenceController.preview.container.viewContext
        
        let sampleCreditCard = CreditCard(context: context)
        sampleCreditCard.id = UUID()
        sampleCreditCard.name = "Visa Gold Preview"
        sampleCreditCard.lastFourDigits = "1234"
        sampleCreditCard.cardType = "Credit"
        sampleCreditCard.createdAt = Date()
        sampleCreditCard.customColorHex = "#1A237E" // Dark Blue
        sampleCreditCard.totalCreditLimit = 5000.00
        
        let sampleDebitCard = DebitCard(context: context)
        sampleDebitCard.id = UUID()
        sampleDebitCard.name = "Mastercard Debit Preview"
        sampleDebitCard.lastFourDigits = "5678"
        sampleDebitCard.cardType = "Debit"
        sampleDebitCard.createdAt = Date()
        // sampleDebitCard.customColorHex = nil // Will use default gray
        sampleDebitCard.balance = 1250.75
        sampleDebitCard.currencyCode = "USD"

        return VStack {
            CardView(card: sampleCreditCard)
            CardView(card: sampleDebitCard)
        }
        .padding()
        .environment(\.managedObjectContext, context)
    }
}
