import SwiftUI


struct Product: Identifiable, Hashable {
    let id: Int
    let name: String
    let productNumber: String
    let color: String
    let listPrice: Double
}

class ProductLoader {
    static func fetchProducts() async -> [Product] {

        return [
            Product(id: 1, name: "Mountain Bike", productNumber: "MK-M100", color: "Red", listPrice: 1099.99),
            Product(id: 2, name: "Road Frame", productNumber: "F-R200", color: "Silver", listPrice: 550.00),
            Product(id: 3, name: "Cycling Gloves", productNumber: "GL-C300", color: "Black", listPrice: 29.99),
            Product(id: 4, name: "Water Bottle", productNumber: "W-d40", color: "Blue", listPrice: 9.50)
        ]
    }
}

struct ProductListView: View {
    @State private var products: [Product] = []

    var body: some View {
        NavigationStack {
            List(products) { product in
                NavigationLink(value: product) {
                    VStack(alignment: .leading) {
                        Text(product.name)
                            .font(.headline)
                        Text("Color: \(product.color)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Products")
            .navigationDestination(for: Product.self) { product in
                ProductDetailsView(product: product)
            }
            .task {
                products = await ProductLoader.fetchProducts()
            }
        }
    }
}

struct ProductDetailsView: View {
    let product: Product

    var body: some View {
        List {
            Section(header: Text("Product Information")) {
                LabeledContent("ID", value: "\(product.id)")
                LabeledContent("Name", value: product.name)
                LabeledContent("Product Number", value: product.productNumber)
                LabeledContent("Color", value: product.color)
                LabeledContent("Price", value: product.listPrice, format: .currency(code: "USD"))
            }
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProductListView()
}
