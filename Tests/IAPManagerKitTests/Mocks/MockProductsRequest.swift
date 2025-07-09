//
//  MockProductsRequest.swift
//  IAPManagerKit
//
//  Created by Hakan on 9.07.2025.
//

import StoreKit
@testable import IAPManagerKit

final class MockProductsRequest: ProductsRequesting {
    var delegate: SKProductsRequestDelegate?
    var started = false
    var isCancelled = false

    func start() {
        started = true
        isCancelled = false
    }
    
    func cancel() {
        isCancelled = true
    }
}
