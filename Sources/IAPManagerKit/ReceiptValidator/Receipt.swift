//
//  Receipt.swift
//  IAPManagerKit
//
//  Created by Hakan on 9.07.2025.
//

import Foundation

public struct Receipt {
    public let productID: String
    public let expirationDate: Date?
    public let purchaseDate: Date?
    public let transactionID: String?
    public let isTrialPeriod: Bool
    public let isSubscription: Bool
}
