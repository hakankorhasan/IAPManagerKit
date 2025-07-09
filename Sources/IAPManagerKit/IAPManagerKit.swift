//
//  IAPManager.swift
//  IAPManagerKit
//

import Foundation
import StoreKit
import Combine

@available(iOS 13.0, macOS 10.15, *)
public final class IAPManagerKit: NSObject, ObservableObject {
    
    // MARK: - Dependencies
    private let productsRequestFactory: (_ identifiers: Set<String>) -> ProductsRequesting
    private let paymentQueue: PaymentQueueProtocol
    private let receiptValidator: IAPReceiptValidator
    
    // MARK: - Shared Instance
    public static let shared = IAPManagerKit()
    
    // MARK: - Published Properties
    @Published public private(set) var purchasedProductIDs: Set<String> = []
    @Published public var lastError: Error? = nil
    
    // MARK: - Logging
    public var isLoggingEnabled: Bool = false
    private func log(_ message: String) {
        if isLoggingEnabled {
            print("[IAPManagerKit] \(message)")
        }
    }
    
    // MARK: - Private Properties
    private var products: [SKProduct] = []
    private var productRequest: ProductsRequesting?
    
    // MARK: - Computed Properties
    public var hasUnlockedPro: Bool {
        return !purchasedProductIDs.isEmpty
    }
    
    public var availableProducts: [SKProduct] {
        return products
    }
    
    // MARK: - Init
    public init(
        productsRequestFactory: @escaping (_ identifiers: Set<String>) -> ProductsRequesting = { identifiers in
            return SKProductsRequest(productIdentifiers: identifiers)
        },
        paymentQueue: PaymentQueueProtocol = SKPaymentQueue.default(),
        receiptValidator: IAPReceiptValidator = IAPReceiptValidator()
    ) {
        self.productsRequestFactory = productsRequestFactory
        self.paymentQueue = paymentQueue
        self.receiptValidator = receiptValidator
        super.init()
        self.paymentQueue.add(self)
    }
    
    deinit {
        paymentQueue.remove(self)
    }
    
    // MARK: - Public Methods
    
    public func fetchProducts(identifiers: [String]) {
        productRequest?.cancel()
        var request = productsRequestFactory(Set(identifiers))
        request.delegate = self
        request.start()
        productRequest = request
        log("Started fetching products: \(identifiers)")
    }
    
    public func purchase(product: SKProduct) {
        guard SKPaymentQueue.canMakePayments() else {
            let error = NSError(domain: "IAPManagerKit", code: 0,
                                userInfo: [NSLocalizedDescriptionKey: "In-App Purchases are disabled on this device."])
            lastError = error
            log("In-App Purchases are disabled on this device.")
            return
        }
        let payment = SKPayment(product: product)
        paymentQueue.add(payment)
        log("Initiated purchase for product: \(product.productIdentifier)")
    }
    
    public func restorePurchases() {
        paymentQueue.restoreCompletedTransactions()
        log("Restore purchases started.")
    }
    
    public func isProductPurchased(_ id: String) -> Bool {
        return purchasedProductIDs.contains(id)
    }
    
    public func product(for id: String) -> SKProduct? {
        return products.first { $0.productIdentifier == id }
    }
    
    public func subscriptionType(for product: SKProduct) -> SubscriptionPeriodType? {
        guard let period = product.subscriptionPeriod else { return nil }
        switch period.unit {
        case .day: return .daily
        case .week: return .weekly
        case .month: return .monthly
        case .year: return .yearly
        @unknown default: return nil
        }
    }
    
    public func validateReceipt(completion: @escaping (IAPReceiptValidationResult) -> Void) {
        guard let receiptData = receiptValidator.loadReceiptData() else {
            let error = NSError(domain: "IAPManagerKit", code: 0,
                                userInfo: [NSLocalizedDescriptionKey: "Receipt not found on device"])
            lastError = error
            completion(.failure(error: error))
            return
        }
        
        receiptValidator.validateReceipt(receiptData) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let receipt):
                    self?.purchasedProductIDs.insert(receipt.productID)
                    completion(.success(receipt: receipt))
                    self?.log("Receipt validated successfully for product: \(receipt.productID)")
                case .failure(let error):
                    self?.lastError = error
                    completion(.failure(error: error))
                    self?.log("Receipt validation failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Optional callback for purchase failure events
    public var onPurchaseFailed: ((SKPaymentTransaction, Error?) -> Void)?
}

// MARK: - SKProductsRequestDelegate
@available(iOS 13.0, macOS 10.15, *)
extension IAPManagerKit: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.products = response.products
        log("Fetched products: \(products.map { $0.localizedTitle })")
    }
}

// MARK: - SKPaymentTransactionObserver
@available(iOS 13.0, macOS 10.15, *)
extension IAPManagerKit: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                complete(transaction)
            case .failed:
                paymentQueue.finishTransaction(transaction)
                DispatchQueue.main.async {
                    self.lastError = transaction.error
                }
                onPurchaseFailed?(transaction, transaction.error)
                log("Purchase failed: \(transaction.error?.localizedDescription ?? "Unknown error")")
            default:
                break
            }
        }
    }
    
    private func complete(_ transaction: SKPaymentTransaction) {
        let productID = transaction.payment.productIdentifier
        DispatchQueue.main.async {
            self.purchasedProductIDs.insert(productID)
        }
        paymentQueue.finishTransaction(transaction)
        log("Purchase successful: \(productID)")
    }
}
