//
//  Extensions.swift
//  IAPManagerKit
//
//  Created by Hakan on 9.07.2025.
//

import StoreKit

@available(iOS 13.0, macOS 10.15, *)
public extension SKProduct {
    var subscriptionPeriodString: String? {
        guard let period = subscriptionPeriod else { return nil }
        switch period.unit {
        case .day: return "Daily"
        case .week: return "Weekly"
        case .month: return "Monthly"
        case .year: return "Yearly"
        @unknown default: return nil
        }
    }
}
