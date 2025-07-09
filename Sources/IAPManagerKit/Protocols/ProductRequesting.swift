//
//  ProductRequesting.swift
//  IAPManagerKit
//
//  Created by Hakan on 9.07.2025.
//

import StoreKit

public protocol ProductsRequesting {
    func start()
    func cancel()
    var delegate: SKProductsRequestDelegate? { get set }
}

extension SKProductsRequest: ProductsRequesting {}

