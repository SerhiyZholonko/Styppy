import SwiftUI

struct AddEditSubscriptionView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddEditSubscriptionViewModel
    
    private let colors = ["blue", "red", "green", "orange", "purple", "pink", "yellow", "indigo", "teal", "mint"]
    
    init(subscriptionManager: SubscriptionManager, subscription: Subscription? = nil) {
        self.subscriptionManager = subscriptionManager
        self._viewModel = StateObject(wrappedValue: AddEditSubscriptionViewModel(subscriptionManager: subscriptionManager, subscription: subscription))
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Subscription Details") {
                    HStack {
                        Image(systemName: viewModel.selectedCategory.icon)
                            .foregroundColor(viewModel.selectedCategory.color)
                            .font(.title2)

                        TextField("Subscription name", text: $viewModel.name)
                            .textFieldStyle(.plain)
                    }

                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $viewModel.price)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                    }

                    Picker("Billing Cycle", selection: $viewModel.selectedBillingCycle) {
                        ForEach(BillingCycle.allCases, id: \.self) { cycle in
                            Text(cycle.rawValue).tag(cycle)
                        }
                    }

                    Picker("Category", selection: $viewModel.selectedCategory) {
                        ForEach(SubscriptionCategory.allCases, id: \.self) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                Text(cat.rawValue)
                            }
                            .tag(cat)
                        }
                    }
                }

                Section("Billing Information") {
                    DatePicker("Next billing date", selection: $viewModel.nextBillingDate, displayedComponents: .date)

                    Toggle("Active subscription", isOn: $viewModel.isActive)
                }

                Section("Payment Repetition") {
                    Picker("Auto-renewal", selection: $viewModel.selectedRepetitionType) {
                        ForEach(RepetitionType.allCases, id: \.self) { type in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.rawValue)
                                    .font(.body)
                                Text(type.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.automatic)

                    if viewModel.selectedRepetitionType != .disabled {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("Payments will automatically renew based on your selection")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("This subscription will not auto-renew")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Appearance") {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Color")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            
                            // Enhanced selected color indicator
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(Color(stringColor: viewModel.selectedColor))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                    )
                                    .shadow(color: Color(stringColor: viewModel.selectedColor).opacity(0.4), radius: 4, x: 0, y: 2)
                                
                                Text(viewModel.selectedColor.capitalized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        // Enhanced color picker with better visual design
                        VStack(spacing: 16) {
                            // Top row
                            HStack(spacing: 16) {
                                ForEach(Array(colors.prefix(5)), id: \.self) { color in
                                    ColorPickerButton(
                                        color: color,
                                        isSelected: viewModel.selectedColor == color
                                    ) {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            viewModel.selectedColor = color
                                        }
                                    }
                                }
                            }
                            
                            // Bottom row
                            HStack(spacing: 16) {
                                ForEach(Array(colors.suffix(5)), id: \.self) { color in
                                    ColorPickerButton(
                                        color: color,
                                        isSelected: viewModel.selectedColor == color
                                    ) {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            viewModel.selectedColor = color
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.vertical, 8)
                }

                Section("Notes") {
                    TextField("Add notes (optional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if viewModel.isEditing {
                    Section {
                        Button("Delete Subscription", role: .destructive) {
                            // TODO: Add delete confirmation alert
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(viewModel.saveButtonTitle) {
                        viewModel.saveSubscription()
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }

}

#Preview {
    AddEditSubscriptionView(subscriptionManager: SubscriptionManager())
}