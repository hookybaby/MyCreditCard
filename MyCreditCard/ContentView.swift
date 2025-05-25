import SwiftUI
import CoreData // Import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext // Add managed object context

    // FetchRequest for Card entities
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.createdAt, ascending: true)],
        animation: .default)
    private var cards: FetchedResults<Card>

    // Sample data for previews (can be removed if snapshot section becomes dynamic too)
    @State private var creditCardUsage: Double = 0.45
    @State private var creditCardLimit: Double = 2000.00
    @State private var debitCardTotalSpending: Double = 567.89

    // State variable to control the presentation of AddCardView
    @State private var isAddingCard: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // My Cards Section
                    Text("contentView.myCards.header")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    if cards.isEmpty {
                        Text("contentView.myCards.emptyState")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    } else {
                        VStack(spacing: 15) {
                            ForEach(cards) { card in
                                NavigationLink(destination: CardDetailView(card: card)) { // Pass card to CardDetailView
                                    CardView(card: card) // Pass card to CardView
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Monthly Snapshot Section (remains static for now)
                    Text("contentView.monthlySnapshot.header")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top)

                    VStack(alignment: .leading, spacing: 15) {
                        Text("contentView.monthlySnapshot.creditUsage.title")
                            .font(.headline)
                        ProgressView(value: creditCardUsage)
                            .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                            .frame(height: 20)
                        // For "%.0f%% of $%.2f limit used", use LocalizedStringKey for dynamic content
                        // This is a simplified approach. For complex cases, consider multiple keys or NumberFormatters.
                        Text(LocalizedStringKey(String.localizedStringWithFormat(NSLocalizedString("contentView.monthlySnapshot.creditUsage.format", comment: "Format for credit usage: percentage and limit"), creditCardUsage * 100, creditCardLimit)))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("contentView.monthlySnapshot.debitSpending.title")
                            .font(.headline)
                            .padding(.top)
                        Text(LocalizedStringKey(String.localizedStringWithFormat(NSLocalizedString("contentView.monthlySnapshot.debitSpending.totalFormat", comment: "Format for total debit spending"), debitCardTotalSpending)))
                            .font(.subheadline)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("contentView.monthlySnapshot.debitSpending.groceriesPlaceholder")
                                .font(.caption)
                            Text("contentView.monthlySnapshot.debitSpending.utilitiesPlaceholder")
                                .font(.caption)
                            Text("contentView.monthlySnapshot.debitSpending.entertainmentPlaceholder")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle(Text("contentView.navigationTitle"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isAddingCard = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .accessibilityLabel(Text("contentView.buttons.addNewCard.accessibilityLabel"))
                    }
                }
            }
            .sheet(isPresented: $isAddingCard) {
                // Pass the context to AddCardView if it's not already getting it from environment
                AddCardView().environment(\.managedObjectContext, self.viewContext)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
