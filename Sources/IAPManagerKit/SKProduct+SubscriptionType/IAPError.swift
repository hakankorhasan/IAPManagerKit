//
//  IAPError.swift
//  IAPManagerKit
//
//  Created by Hakan on 9.07.2025.
//

import Foundation

/// In-App Purchase işlemlerinde oluşabilecek hata tipleri
public enum IAPError: LocalizedError {
    case paymentsNotAllowed
    case productNotFound(productID: String)
    case purchaseFailed(error: Error?)
    case restoreFailed(error: Error?)
    case receiptInvalid
    case unknown

    public var errorDescription: String? {
        switch self {
        case .paymentsNotAllowed:
            return NSLocalizedString("In-App Purchases are disabled on this device.", comment: "")
        case .productNotFound(let productID):
            return NSLocalizedString("Product with ID '\(productID)' was not found.", comment: "")
        case .purchaseFailed(let error):
            return error?.localizedDescription ?? NSLocalizedString("Purchase failed due to an unknown error.", comment: "")
        case .restoreFailed(let error):
            return error?.localizedDescription ?? NSLocalizedString("Restore purchases failed due to an unknown error.", comment: "")
        case .receiptInvalid:
            return NSLocalizedString("Receipt validation failed.", comment: "")
        case .unknown:
            return NSLocalizedString("An unknown error occurred.", comment: "")
        }
    }
}
