import StoreKit

@MainActor
final class StoreKitManager: ObservableObject {
    static let annualProductID = "com.kochan17.nagi.annual"
    static let monthlyProductID = "com.kochan17.nagi.monthly"

    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var transactionListener: Task<Void, Never>?
    private weak var appState: AppState?

    init(appState: AppState) {
        self.appState = appState
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await Product.products(for: [
                Self.annualProductID,
                Self.monthlyProductID
            ])
            products = fetched.sorted { first, second in
                first.id == Self.annualProductID
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                appState?.isSubscribed = true
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func checkSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.annualProductID ||
               transaction.productID == Self.monthlyProductID {
                if transaction.revocationDate == nil {
                    appState?.isSubscribed = true
                    return
                }
            }
        }
        appState?.isSubscribed = false
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                if transaction.productID == Self.annualProductID ||
                   transaction.productID == Self.monthlyProductID {
                    await MainActor.run {
                        self.appState?.isSubscribed = transaction.revocationDate == nil
                    }
                }
                await transaction.finish()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }
}

enum StoreError: Error, LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Purchase verification failed. Please try again."
        }
    }
}
