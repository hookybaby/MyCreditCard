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
                    Text("My Cards")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    if cards.isEmpty {
                        Text("No cards added yet. Tap the + button to add your first card!")
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
                    Text("Monthly Snapshot")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top)

                    VStack(alignment: .leading, spacing: 15) {
                        Text("Credit Card Usage")
                            .font(.headline)
                        ProgressView(value: creditCardUsage)
                            .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                            .frame(height: 20)
                        Text(String(format: "%.0f%% of $%.2f limit used", creditCardUsage * 100, creditCardLimit))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Debit Card Spending")
                            .font(.headline)
                            .padding(.top)
                        Text(String(format: "Total this month: $%.2f", debitCardTotalSpending))
                            .font(.subheadline)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Groceries: $123.45")
                                .font(.caption)
                            Text("Utilities: $88.00")
                                .font(.caption)
                            Text("Entertainment: $55.20")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Account Overview")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isAddingCard = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
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
