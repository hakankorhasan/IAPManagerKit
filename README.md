# IAPManagerKit


A modular, Combine-based In-App Purchase manager built with `StoreKit`, `Combine`, and `SwiftUI` support.  
Designed to simplify integration of non-consumable and subscription-based purchases across iOS/macOS projects.

[➡ View on GitHub](https://github.com/hakankorhasan/IAPManagerKit)

---

## ✨ Features

- Modular and testable architecture
- `Combine` publishers for reactive UI updates
- Built-in receipt validation with Apple servers
- Subscription type parsing support
- SwiftUI-ready with `@Published` state
- Easy to integrate with reusable ViewModel patterns

---

## 🧱 Installation

You can integrate **IAPManagerKit** using Swift Package Manager:

### Xcode

1. Go to **File > Add Packages…**
2. Enter the URL: https://github.com/hakankorhasan/IAPManagerKit 
3. Choose the latest version and add it to your project.

---

## 🚀 Quick Start

Here's a quick example of how to use `IAPManagerKit` with SwiftUI and Combine in a clean MVVM setup.

### ✅ ViewModel

```swift
import Foundation
import Combine
import IAPManagerKit
import StoreKit

@MainActor
class IAPViewModel: ObservableObject {
 @Published var products: [SKProduct] = []
 @Published var purchasedProductIDs: Set<String> = []
 @Published var errorMessage: String? = nil

 private var cancellables = Set<AnyCancellable>()
 private let iapManager = IAPManagerKit.shared

 let productIDs = ["com.example.product1", "com.example.product2"]

 init() {
     iapManager.$purchasedProductIDs
         .receive(on: DispatchQueue.main)
         .assign(to: &$purchasedProductIDs)

     iapManager.$lastError
         .receive(on: DispatchQueue.main)
         .sink { [weak self] error in
             self?.errorMessage = error?.localizedDescription
         }
         .store(in: &cancellables)

     fetchProducts()
 }

 func fetchProducts() {
     iapManager.fetchProducts(identifiers: productIDs)
     products = iapManager.availableProducts
 }

 func purchase(product: SKProduct) {
     iapManager.purchase(product: product)
 }

 func isPurchased(productID: String) -> Bool {
     purchasedProductIDs.contains(productID)
 }
}
```

### ✅ View

```
import SwiftUI
import StoreKit

struct IAPView: View {
    @StateObject private var viewModel = IAPViewModel()

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.products.isEmpty {
                    ProgressView("Loading products...")
                } else {
                    List(viewModel.products, id: \.productIdentifier) { product in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(product.localizedTitle)
                                    .font(.headline)
                                Text(product.localizedDescription)
                                    .font(.subheadline)
                            }
                            Spacer()
                            Button(action: {
                                viewModel.purchase(product: product)
                            }) {
                                Text(viewModel.isPurchased(productID: product.productIdentifier) ? "Purchased" : "Buy")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.isPurchased(productID: product.productIdentifier))
                        }
                    }
                }

                if !viewModel.purchasedProductIDs.isEmpty {
                    Text("Purchased Products:")
                        .font(.headline)
                        .padding(.top)
                    ForEach(Array(viewModel.purchasedProductIDs), id: \.self) { id in
                        Text(id)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()
            }
            .navigationTitle("In-App Purchases")
            .padding()
        }
    }
}
```


🧪 Testing

You can test the system using sandbox accounts via Apple’s StoreKit testing tools or by mocking PaymentQueueProtocol and ProductsRequesting.


