import Foundation
import SwiftUI

class AddEditSubscriptionViewModel: ObservableObject {
    @Published var name = ""
    @Published var price = ""
    @Published var selectedCategory: SubscriptionCategory = .other
    @Published var selectedBillingCycle: BillingCycle = .monthly
    @Published var selectedRepetitionType: RepetitionType = .monthly
    @Published var nextBillingDate = Date()
    @Published var notes = ""
    @Published var isActive = true
    @Published var selectedColor = "blue"
    @Published var showingDatePicker = false
    @Published var showingError = false
    @Published var errorMessage = ""
    
    private var subscriptionManager: SubscriptionManager
    private var editingSubscription: Subscription?
    
    var isEditing: Bool {
        editingSubscription != nil
    }
    
    var navigationTitle: String {
        isEditing ? "Edit Subscription" : "Add Subscription"
    }
    
    var saveButtonTitle: String {
        isEditing ? "Update" : "Add"
    }
    
    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !price.isEmpty &&
        Double(price) != nil &&
        Double(price) ?? 0 > 0
    }
    
    init(subscriptionManager: SubscriptionManager, subscription: Subscription? = nil) {
        self.subscriptionManager = subscriptionManager
        self.editingSubscription = subscription
        
        if let subscription = subscription {
            loadSubscriptionData(subscription)
        }
    }
    
    private func loadSubscriptionData(_ subscription: Subscription) {
        name = subscription.name
        price = String(format: "%.2f", subscription.price)
        selectedCategory = subscription.category
        selectedBillingCycle = subscription.billingCycle
        selectedRepetitionType = subscription.repetitionType
        nextBillingDate = subscription.nextBillingDate
        notes = subscription.notes
        isActive = subscription.isActive
        selectedColor = subscription.color
    }
    
    func saveSubscription() {
        guard canSave else {
            showError("Please fill in all required fields with valid data")
            return
        }
        
        guard let priceValue = Double(price), priceValue > 0 else {
            showError("Please enter a valid price greater than 0")
            return
        }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if var existingSubscription = editingSubscription {
            existingSubscription.name = trimmedName
            existingSubscription.price = priceValue
            existingSubscription.category = selectedCategory
            existingSubscription.billingCycle = selectedBillingCycle
            existingSubscription.repetitionType = selectedRepetitionType
            existingSubscription.nextBillingDate = nextBillingDate
            existingSubscription.notes = notes
            existingSubscription.isActive = isActive
            existingSubscription.color = selectedColor
            
            subscriptionManager.updateSubscription(existingSubscription)
        } else {
            let newSubscription = Subscription(
                name: trimmedName,
                price: priceValue,
                billingCycle: selectedBillingCycle,
                category: selectedCategory,
                nextBillingDate: nextBillingDate,
                isActive: isActive,
                notes: notes,
                color: selectedColor,
                repetitionType: selectedRepetitionType
            )
            
            subscriptionManager.addSubscription(newSubscription)
        }
    }
    
    func resetForm() {
        name = ""
        price = ""
        selectedCategory = .other
        selectedBillingCycle = .monthly
        selectedRepetitionType = .monthly
        nextBillingDate = Date()
        notes = ""
        isActive = true
        selectedColor = "blue"
        showingError = false
        errorMessage = ""
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    func toggleDatePicker() {
        showingDatePicker.toggle()
    }
    
    func dismissError() {
        showingError = false
        errorMessage = ""
    }
}