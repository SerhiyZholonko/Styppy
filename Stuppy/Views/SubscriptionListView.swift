import SwiftUI

struct SubscriptionListView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel: SubscriptionListViewModel
    
    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        self._viewModel = StateObject(wrappedValue: SubscriptionListViewModel(subscriptionManager: subscriptionManager))
    }

    var body: some View {
        GeometryReader { geometry in
            let isIPad = UIDevice.current.userInterfaceIdiom == .pad
            let screenWidth = geometry.size.width
            let isLandscape = screenWidth > geometry.size.height
            let _ = isIPad && isLandscape ? 2 : 1  // Used for layout logic in view
            
            NavigationStack {
                VStack(spacing: 0) {
                    // Header with Title and Search
                    VStack(spacing: isIPad ? 20 : 16) {
                        // Custom Header
                        HStack {
                            Text("Subscriptions")
                                .font(.system(size: isIPad ? 42 : 34, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, isIPad ? 32 : 20)
                        
                        // Search Bar
                        HStack {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: isIPad ? 18 : 16))
                                
                                TextField("Search subscriptions", text: $viewModel.searchText)
                                    .font(.system(size: isIPad ? 18 : 16))
                                
                                if !viewModel.searchText.isEmpty {
                                    Button {
                                        viewModel.searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: isIPad ? 16 : 14))
                                    }
                                }
                            }
                            .padding(.horizontal, isIPad ? 20 : 16)
                            .padding(.vertical, isIPad ? 16 : 12)
                            .background(
                                RoundedRectangle(cornerRadius: isIPad ? 16 : 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                        .padding(.horizontal, isIPad ? 32 : 20)
                        
                        // Category Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: isIPad ? 16 : 12) {
                                CategoryFilterButton(
                                    title: "All",
                                    isSelected: viewModel.selectedCategory == nil,
                                    isIPad: isIPad
                                ) {
                                    viewModel.clearCategoryFilter()
                                }

                                ForEach(viewModel.allCategories, id: \.self) { category in
                                    CategoryFilterButton(
                                        title: category.rawValue,
                                        isSelected: viewModel.selectedCategory == category,
                                        icon: category.icon,
                                        isIPad: isIPad
                                    ) {
                                        viewModel.selectCategory(category)
                                    }
                                }
                            }
                            .padding(.horizontal, isIPad ? 32 : 20)
                        }
                    }
                    .padding(.top, isIPad ? 20 : 10)

                    // Main Content
                    if !viewModel.hasFilteredSubscriptions {
                        // Empty State
                        Spacer()
                        VStack(spacing: isIPad ? 24 : 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: isIPad ? 120 : 80, height: isIPad ? 120 : 80)
                                
                                Image(systemName: "creditcard")
                                    .font(.system(size: isIPad ? 50 : 35))
                                    .foregroundColor(.gray)
                            }

                            VStack(spacing: isIPad ? 12 : 8) {
                                Text("No subscriptions found")
                                    .font(isIPad ? .largeTitle : .title2)
                                    .fontWeight(.medium)

                                Text("Tap the + button to add your first subscription")
                                    .font(isIPad ? .title3 : .body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, isIPad ? 40 : 20)
                            }

                            Button {
                                viewModel.toggleAddSubscription()
                            } label: {
                                HStack(spacing: isIPad ? 12 : 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: isIPad ? 18 : 16, weight: .semibold))
                                    
                                    Text("Add Subscription")
                                        .font(.system(size: isIPad ? 18 : 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, isIPad ? 32 : 24)
                                .padding(.vertical, isIPad ? 16 : 12)
                                .background(
                                    RoundedRectangle(cornerRadius: isIPad ? 16 : 12)
                                        .fill(Color.accentColor)
                                        .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                            }
                        }
                        Spacer()
                    } else {
                        // Subscription Grid/List
                        if isIPad {
                            ScrollView {
                                LazyVStack(spacing: isLandscape ? 24 : 20) {
                                    if isLandscape {
                                        // Landscape - 2 columns
                                        let chunked = viewModel.filteredSubscriptions.chunked(into: 2)
                                        ForEach(Array(chunked.enumerated()), id: \.offset) { index, chunk in
                                            HStack(spacing: 24) {
                                                ForEach(chunk) { subscription in
                                                    NavigationLink(value: subscription) {
                                                        SubscriptionCard(subscription: subscription, isIPad: true)
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                }
                                                
                                                if chunk.count == 1 {
                                                    Spacer()
                                                        .frame(maxWidth: .infinity)
                                                }
                                            }
                                        }
                                    } else {
                                        // Portrait - 1 column with enhanced cards
                                        ForEach(viewModel.filteredSubscriptions) { subscription in
                                            NavigationLink(value: subscription) {
                                                SubscriptionCard(subscription: subscription, isIPad: true)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                                .padding(.horizontal, 32)
                                .padding(.top, 24)
                                .padding(.bottom, 100) // Space for floating action button
                            }
                        } else {
                            // iPhone - Standard List
                            List {
                                ForEach(viewModel.filteredSubscriptions) { subscription in
                                    InteractiveSubscriptionRow(
                                        subscription: subscription,
                                        subscriptionManager: subscriptionManager
                                    )
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button {
                                            subscriptionManager.deleteSubscription(subscription)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        .tint(.red)
                                        
                                        Button {
                                            subscriptionManager.togglePaymentStatus(subscription)
                                        } label: {
                                            Label(subscription.isPaidForCurrentMonth ? "Mark Unpaid" : "Mark Paid", 
                                                  systemImage: subscription.isPaidForCurrentMonth ? "xmark.circle" : "checkmark.circle")
                                        }
                                        .tint(subscription.isPaidForCurrentMonth ? .orange : .green)
                                    }
                                }
                                .onDelete(perform: viewModel.deleteSubscriptions)
                            }
                            .listStyle(PlainListStyle())
                        }
                    }
                }
                .navigationBarHidden(true)
                .fullScreenCover(isPresented: $viewModel.showingAddSubscription) {
                    AddEditSubscriptionView(subscriptionManager: subscriptionManager)
                }
            }
            .navigationDestination(for: Subscription.self) { subscription in
                SubscriptionDetailView(
                    subscription: subscription,
                    subscriptionManager: subscriptionManager
                )
            }
        }
    }

}



// MARK: - Interactive Subscription Row
struct InteractiveSubscriptionRow: View {
    let subscription: Subscription
    let subscriptionManager: SubscriptionManager
    
    @State private var showingDetail = false
    
    var body: some View {
        HStack {
            // Main content that triggers navigation or long press menu
            HStack(spacing: 12) {
                // Category Icon
                Image(systemName: subscription.category.icon)
                    .font(.title2)
                    .foregroundColor(subscription.category.color)
                    .frame(width: 32, height: 32)
                    .background(subscription.category.color.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack {
                        Text(subscription.billingCycle.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 3, height: 3)

                        Text(subscription.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "$%.2f", subscription.price))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        // Payment status indicator
                        if subscription.isPaidForCurrentMonth {
                            Text("Paid")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                        } else if subscription.isOverdue {
                            Text("Overdue")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(4)
                        } else if subscription.daysUntilNextBilling <= 3 {
                            Text("\(subscription.daysUntilNextBilling) days")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(4)
                        } else {
                            Text("\(subscription.daysUntilNextBilling) days")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .contentShape(Rectangle()) // Make entire area tappable
            .onTapGesture {
                showingDetail = true
            }
        }
        .padding(.vertical, 4)
        .navigationDestination(isPresented: $showingDetail) {
            SubscriptionDetailView(
                subscription: subscription,
                subscriptionManager: subscriptionManager
            )
        }
    }
}

#Preview {
    SubscriptionListView(subscriptionManager: SubscriptionManager())
}
