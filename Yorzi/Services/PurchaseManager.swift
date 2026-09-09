import Foundation
import StoreKit

final class PurchaseManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    struct ProductConfiguration {
        let id: String
        let coins: Int
    }

    static let shared = PurchaseManager()
    private(set) var products: [SKProduct] = []
    var isLoading = false
    let configurations: [ProductConfiguration] = [
        .init(id: "lvbsvhxcgcrvesor", coins: 500),
        .init(id: "dxismgcwewhrtezo", coins: 1_000),
        .init(id: "khtxlcejaxmqcsra", coins: 1_500),
        .init(id: "yadwwvxspgxwlndb", coins: 2_500),
        .init(id: "qnrcuelbtiuflyky", coins: 5_000),
        .init(id: "ymohxnvpkqxutvab", coins: 10_000)
    ]
    var productIDs: [String] { configurations.map(\.id) }
    func coins(for productID: String) -> Int { configurations.first(where: { $0.id == productID })?.coins ?? 0 }
    private var request: SKProductsRequest?
    private var purchaseCompletion: ((Bool) -> Void)?
    private override init() { super.init(); SKPaymentQueue.default().add(self) }
    func loadProducts(completion: @escaping ([SKProduct]) -> Void) {
        isLoading = true; request?.cancel(); request = SKProductsRequest(productIdentifiers: Set(productIDs)); request?.delegate = self; request?.start(); pendingCompletion = completion
    }
    private var pendingCompletion: (([SKProduct]) -> Void)?
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) { products = response.products; isLoading = false; pendingCompletion?(products); pendingCompletion = nil }
    func request(_ request: SKRequest, didFailWithError error: Error) { isLoading = false; pendingCompletion?([]); pendingCompletion = nil }
    func buy(_ product: SKProduct, completion: ((Bool) -> Void)? = nil) {
        purchaseCompletion = completion
        guard SKPaymentQueue.canMakePayments() else { purchaseCompletion?(false); purchaseCompletion = nil; return }
        SKPaymentQueue.default().add(SKPayment(product: product))
    }
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { transaction in
            if transaction.transactionState == .purchased { DataRepository.shared.credit(coins(for: transaction.payment.productIdentifier)); queue.finishTransaction(transaction); purchaseCompletion?(true); purchaseCompletion = nil }
            if transaction.transactionState == .failed || transaction.transactionState == .restored { queue.finishTransaction(transaction); purchaseCompletion?(false); purchaseCompletion = nil }
        }
    }
}
