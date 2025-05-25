import SwiftUI
import CoreData

enum TransactionType: String, CaseIterable, Identifiable {
    case expense
    case income
    var id: String { self.rawValue }

    func localizedString() -> LocalizedStringKey {
        switch self {
        case .expense:
            return "transaction.type.expense"
        case .income:
            return "transaction.type.income"
        }
    }
}

struct AddTransactionView: View {
    let card: Card // Card to associate the transaction with

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    @State private var date: Date = Date()
    @State private var amountString: String = ""
    @State private var type: TransactionType = .expense
    @State private var category: String = ""
    @State private var notes: String = ""
    
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker(LocalizedStringKey("addTransaction.date.label"), selection: $date, displayedComponents: .date)
                    
                    HStack {
                        Text("addTransaction.amount.label")
                        TextField(LocalizedStringKey("addTransaction.amount.placeholder"), text: $amountString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker(LocalizedStringKey("addTransaction.type.label"), selection: $type) {
                        ForEach(TransactionType.allCases) { transactionType in
                            Text(transactionType.localizedString()).tag(transactionType)
                        }
                    }
                    
                    HStack {
                        Text("addTransaction.category.label")
                        TextField(LocalizedStringKey("addTransaction.category.placeholder"), text: $category)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack(alignment: .top) {
                        Text("addTransaction.notes.label")
                        TextEditor(text: $notes)
                            .frame(height: 100) // Optional: Give TextEditor a defined height
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                            )
                            // Placeholder for TextEditor is a bit tricky, often done with ZStack if needed
                            // For simplicity, we'll rely on the label.
                    }
                }
            }
            .navigationTitle(Text("addTransaction.navigationTitle"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("common.cancel")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveTransaction) {
                        Text("common.save")
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("addTransaction.alert.validationError.title"), message: Text(alertMessage), dismissButton: .default(Text("common.ok")))
            }
        }
    }

    private func saveTransaction() {
        guard let amount = Double(amountString), amount > 0 else {
            alertMessage = NSLocalizedString("addTransaction.alert.invalidAmount.message", comment: "Invalid amount alert message")
            showingAlert = true
            return
        }
        
        if category.isEmpty {
            alertMessage = NSLocalizedString("addTransaction.alert.emptyCategory.message", comment: "Empty category alert message")
            showingAlert = true
            return
        }

        let newTransaction = Transaction(context: viewContext)
        newTransaction.id = UUID()
        newTransaction.date = date
        newTransaction.amount = amount
        newTransaction.category = category
        newTransaction.notes = notes.isEmpty ? nil : notes
        newTransaction.isExpense = (type == .expense)
        newTransaction.card = card 

        do {
            try viewContext.save()
            dismiss()
        } catch {
            // Handle the Core Data save error
            let nsError = error as NSError
            alertMessage = NSLocalizedString("addTransaction.alert.saveError.message", comment: "Save transaction error") + " \(nsError.localizedDescription)"
            showingAlert = true
            // fatalError("Unresolved error \(nsError), \(nsError.userInfo)") // Not for production
        }
    }
}

// Preview needs a Card object, so we need PersistenceController and sample data
struct AddTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let sampleCard = CreditCard(context: context) // Or DebitCard
        sampleCard.id = UUID()
        sampleCard.name = "Sample Credit Card"
        sampleCard.lastFourDigits = "1234"
        sampleCard.cardType = "Credit"
        sampleCard.createdAt = Date()
        
        return AddTransactionView(card: sampleCard)
            .environment(\.managedObjectContext, context)
    }
}
