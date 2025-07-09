//
//  Untitled.swift
//  IAPManagerKit
//
//  Created by Hakan on 9.07.2025.
//
import StoreKit

public protocol PaymentQueueProtocol {
    func add(_ payment: SKPayment)
    func restoreCompletedTransactions()
    func add(_ observer: SKPaymentTransactionObserver)
    func remove(_ observer: SKPaymentTransactionObserver)
    func finishTransaction(_ transaction: SKPaymentTransaction)
}

extension SKPaymentQueue: PaymentQueueProtocol {}
