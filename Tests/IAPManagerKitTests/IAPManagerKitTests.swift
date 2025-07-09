import Testing
@testable import IAPManagerKit

import XCTest
@testable import IAPManagerKit
import StoreKit

final class IAPManagerKitTests: XCTestCase {
    
    var iapManager: IAPManagerKit!
    var mockPaymentQueue: MockPaymentQueue!
    var mockProductsRequest: MockProductsRequest!
    
    override func setUp() {
        super.setUp()
        mockPaymentQueue = MockPaymentQueue()
        iapManager = IAPManagerKit(
            productsRequestFactory: { _ in
                self.mockProductsRequest = MockProductsRequest()
                return self.mockProductsRequest!
            },
            paymentQueue: mockPaymentQueue,
            receiptValidator: IAPReceiptValidator()
        )
    }
    
    func testFetchProductsStartsRequest() {
        iapManager.fetchProducts(identifiers: ["com.example.product1"])
        XCTAssertTrue(mockProductsRequest.started, "Products request should start")
    }
    
    func testPurchaseAddsPayment() {
        let product = SKProduct()
        
        
        class MockProduct: SKProduct {
            override var productIdentifier: String { return "com.example.product1" }
        }
        let mockProduct = MockProduct()
        
        iapManager.purchase(product: mockProduct)
        
        XCTAssertEqual(mockPaymentQueue.addedPayments.first?.productIdentifier, "com.example.product1")
    }
    
    func testRestorePurchasesCallsRestore() {
        iapManager.restorePurchases()
        XCTAssertTrue(mockPaymentQueue.restoredTransactionsCalled)
    }
}
