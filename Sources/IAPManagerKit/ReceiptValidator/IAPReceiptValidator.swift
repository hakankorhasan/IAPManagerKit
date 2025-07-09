//
//  ReceiptValidator.swift
//  IAPManagerKit
//
//  Created by Hakan on 9.07.2025.
//

import Foundation

public enum IAPReceiptValidationResult {
    case success(receipt: Receipt)
    case failure(error: Error)
}

public final class IAPReceiptValidator {
    
    public init() {}
    
    public func loadReceiptData() -> Data? {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: receiptURL.path) else {
            return nil
        }
        return try? Data(contentsOf: receiptURL)
    }
    
    public func validateReceipt(_ receiptData: Data, completion: @escaping (IAPReceiptValidationResult) -> Void) {
        
        let receiptString = receiptData.base64EncodedString()
        let requestContents = ["receipt-data": receiptString]
        
        guard let requestData = try? JSONSerialization.data(withJSONObject: requestContents) else {
            completion(.failure(error: NSError(domain: "ReceiptValidator", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to encode receipt data"])))
            return
        }
        
        let productionURL = URL(string: "https://buy.itunes.apple.com/verifyReceipt")!
        let sandboxURL = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")!
        
        func sendRequest(to url: URL) {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = requestData
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error: error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(error: NSError(domain: "ReceiptValidator", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    return
                }
                
                self.parseResponse(data, completion: completion, sandboxURL: sandboxURL, sendRequest: sendRequest)
            }
            task.resume()
        }
        
        sendRequest(to: productionURL)
    }
    
    private func parseResponse(_ data: Data, completion: @escaping (IAPReceiptValidationResult) -> Void, sandboxURL: URL, sendRequest: @escaping (URL) -> Void) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = json["status"] as? Int else {
                completion(.failure(error: NSError(domain: "ReceiptValidator", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                return
            }
            
            if status == 21007 {
                sendRequest(sandboxURL)
                return
            }
            
            if status != 0 {
                let error = NSError(domain: "ReceiptValidator", code: status, userInfo: [NSLocalizedDescriptionKey: "Receipt validation failed with status: \(status)"])
                completion(.failure(error: error))
                return
            }
            
            guard let receipt = json["receipt"] as? [String: Any],
                  let inApp = receipt["in_app"] as? [[String: Any]],
                  !inApp.isEmpty else {
                completion(.failure(error: NSError(domain: "ReceiptValidator", code: 0, userInfo: [NSLocalizedDescriptionKey: "No in-app purchase info found in receipt"])))
                return
            }
            
            // En son satın alınan ürünü bul
            let latestPurchase = inApp.max { item1, item2 in
                let date1 = self.parseDate(from: item1) ?? Date.distantPast
                let date2 = self.parseDate(from: item2) ?? Date.distantPast
                return date1 < date2
            }
            
            guard let latest = latestPurchase,
                  let productID = latest["product_id"] as? String else {
                completion(.failure(error: NSError(domain: "ReceiptValidator", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid in-app purchase info"])))
                return
            }
            
            let expirationDate = parseDate(from: latest)
            let purchaseDate = parsePurchaseDate(from: latest)
            let transactionID = latest["transaction_id"] as? String
            let isTrialPeriod = (latest["is_trial_period"] as? String) == "true"
            let isSubscription = (latest["subscription_group_identifier"] as? String) != nil
            
            let receiptObj = Receipt(
                productID: productID,
                expirationDate: expirationDate,
                purchaseDate: purchaseDate,
                transactionID: transactionID,
                isTrialPeriod: isTrialPeriod,
                isSubscription: isSubscription
            )
            completion(.success(receipt: receiptObj))
            
        } catch {
            completion(.failure(error: error))
        }
    }
    
    private func parseDate(from purchaseInfo: [String: Any]) -> Date? {
        // expiration date parsing
        if let expiresDateMsString = purchaseInfo["expires_date_ms"] as? String,
           let ms = Double(expiresDateMsString) {
            return Date(timeIntervalSince1970: ms / 1000.0)
        }
        
        if let expiresDateString = purchaseInfo["expires_date"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: expiresDateString) {
                return date
            }
        }
        
        if let isoDateString = purchaseInfo["expires_date"] as? String {
            let isoFormatter = ISO8601DateFormatter()
            return isoFormatter.date(from: isoDateString)
        }
        
        return nil
    }
    
    private func parsePurchaseDate(from purchaseInfo: [String: Any]) -> Date? {
        // purchase date parsing
        if let purchaseDateMsString = purchaseInfo["purchase_date_ms"] as? String,
           let ms = Double(purchaseDateMsString) {
            return Date(timeIntervalSince1970: ms / 1000.0)
        }
        
        if let purchaseDateString = purchaseInfo["purchase_date"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: purchaseDateString) {
                return date
            }
        }
        
        if let isoDateString = purchaseInfo["purchase_date"] as? String {
            let isoFormatter = ISO8601DateFormatter()
            return isoFormatter.date(from: isoDateString)
        }
        
        return nil
    }
}
