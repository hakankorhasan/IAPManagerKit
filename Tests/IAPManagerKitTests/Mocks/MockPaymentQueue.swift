//
//  MockPaymentQueue.swift
//  IAPManagerKit
//
//  Created by Hakan on 9.07.2025.
//

import StoreKit
@testable import IAPManagerKit

final class MockPaymentQueue: PaymentQueueProtocol {
    var addedPayments: [SKPayment] = []
    var restoredTransactionsCalled = false
    var addedObservers: [SKPaymentTransactionObserver] = []
    var removedObservers: [SKPaymentTransactionObserver] = []
    var finishedTransactions: [SKPaymentTransaction] = []

    func add(_ payment: SKPayment) {
        addedPayments.append(payment)
    }

    func restoreCompletedTransactions() {
        restoredTransactionsCalled = true
    }

    func add(_ observer: SKPaymentTransactionObserver) {
        addedObservers.append(observer)
    }

    func remove(_ observer: SKPaymentTransactionObserver) {
        removedObservers.append(observer)
    }

    func finishTransaction(_ transaction: SKPaymentTransaction) {
        finishedTransactions.append(transaction)
    }
}
