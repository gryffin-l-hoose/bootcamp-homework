

import Foundation





protocol Displayable {
    var displayDescription: String { get }
    func printDetails()
}


extension Displayable {
    func printDetails() {
        print(displayDescription)
    }
}


struct Transaction: Displayable {
    let date: String
    let description: String
    let amount: Double

    var formattedAmount: String {
        let sign = amount >= 0 ? "+" : "-"
        return String(format: "%@$%.2f", sign, abs(amount))
    }

    var displayDescription: String {
        "\(date) \(description): \(formattedAmount)"
    }
}

let sampleTransaction = Transaction(date: "Jan 15, 2024", description: "Direct Deposit", amount: 2500.00)
sampleTransaction.printDetails()


func printAll(items: [Displayable]) {
    for item in items {
        item.printDetails()
    }
}

let transactionList: [Displayable] = [
    Transaction(date: "Jan 15, 2024", description: "Direct Deposit", amount: 2500.00),
    Transaction(date: "Jan 16, 2024", description: "Grocery Store", amount: -84.32)

]
printAll(items: transactionList)






protocol AccountDataSource {
    func fetchBalance(for accountId: String) -> Double
    func fetchTransactionCount(for accountId: String) -> Int
    
}

struct MockAccountDataSource: AccountDataSource {
    func fetchBalance(for accountId: String) -> Double {
        4_250.75
    }

    func fetchTransactionCount(for accountId: String) -> Int {
        47
    }
}

struct LiveAccountDataSource: AccountDataSource {
    func fetchBalance(for accountId: String) -> Double {
        Double.random(in: 100...50_000)
    }

    func fetchTransactionCount(for accountId: String) -> Int {
        Int.random(in: 1...500)
    }
}

class AccountDashboard {
    let dataSource: AccountDataSource

    init(dataSource: AccountDataSource) {
        self.dataSource = dataSource
    }

    func showSummary(for accountId: String) {
        let balance = dataSource.fetchBalance(for: accountId)
        let count = dataSource.fetchTransactionCount(for: accountId)
        print(String(format: "Account %@: Balance $%.2f | Transactions: %d", accountId, balance, count))
    }
}

let mockDashboard = AccountDashboard(dataSource: MockAccountDataSource())
let liveDashboard = AccountDashboard(dataSource: LiveAccountDataSource())
mockDashboard.showSummary(for: "ACC-100")
liveDashboard.showSummary(for: "ACC-200")




class Customer {
    let name: String
    var account: Account?

    init(name: String) {
        self.name = name
    }

    deinit {
        print("Customer \(name) deallocated")
    }
}

class Account {
    let number: String
    weak var

    init(number: String) {
        self.number = number
    }

    deinit {
        print("Account \(number) deallocated")
    }
}

func demonstrateRetainCycleFix() {
    do {
        let customer = Customer(name: "Jane")
        let account = Account(number: "ACC-001")
        customer.account = account
        account.owner = customer
    }
}

demonstrateRetainCycleFix()


class TransactionProcessor {
    let accountId: String
    var onComplete: (() -> Void)?

    init(accountId: String) {
        self.accountId = accountId
    }

    deinit {
        print("TransactionProcessor \(accountId) deallocated")
    }

    func startProcessing() {
        onComplete = { [weak self] in
            guard let self = self else { return }
            print("Processing complete for \(self.accountId)")
        }
    }

    func complete() {
        onComplete?()
    }
}

func demonstrateWeakClosureCapture() {
    do {
        let processor = TransactionProcessor(accountId: "ACC-001")
        processor.startProcessing()
        processor.complete()
    }
}

demonstrateWeakClosureCapture()




struct Address {
    let street: String
    let city: String
    let zip: String?
}

struct UserProfile {
    let name: String
    var address: Address?
}

let user = UserProfile(name: "Jane Smith", address: Address(
    street: "123 Main St", city: "Columbus", zip: "43001"))
let userNoAddress = UserProfile(name: "Bob", address: nil)

func printZip(for profile: UserProfile) {
    let zipMessage = profile.address?.zip.map { "ZIP: \($0)" } ?? "No ZIP available"
    print(zipMessage)
}

printZip(for: user)
printZip(for: userNoAddress)


func transfer(from sourceId: String?, to destId: String?, amount: Double?) {
    if let sourceId = sourceId, let destId = destId, let amount = amount, amount > 0 {
        print(String(format: "Transfer $%.2f from %@ to %@ approved", amount, sourceId, destId))
    } else {
        print("Transfer failed: missing required fields")
    }
}

transfer(from: "ACC-001", to: "ACC-002", amount: 500.0)
transfer(from: nil, to: "ACC-002", amount: 500.0)
transfer(from: "ACC-001", to: "ACC-002", amount: nil)


let rawBalanceString: String? = "4250.75"
let rawInvalidString: String? = "abc"
let nilString: String? = nil

func formattedCurrency(from raw: String?) -> String? {
    raw.flatMap { Double($0) }.map { String(format: "$%.2f", $0) }
}

print(formattedCurrency(from: rawBalanceString) as Any)
print(formattedCurrency(from: rawInvalidString) as Any)
print(formattedCurrency(from: nilString) as Any)


let apiURL = URL(string: "https://api.pnc.com/v1")!





enum TransferError: LocalizedError {
    case invalidAmount
    case insufficientFunds(available: Double)
    case accountNotFound(id: String)
    case dailyLimitExceeded(limit: Double, attempted: Double)
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Transfer amount must be greater than zero."
        case .insufficientFunds(let available):
            return String(format: "Insufficient funds. Available balance: $%.2f", available)
        case .accountNotFound(let id):
            return "Account not found: \(id)"
        case .dailyLimitExceeded(let limit, let attempted):
            return String(format: "Daily limit exceeded. Limit: $%.2f, attempted: $%.2f", limit, attempted)
        case .networkUnavailable:
            return "Network unavailable. Please try again later."
        }
    }
}

func executeTransfer(amount: Double, fromBalance: Double, toAccountId: String,
                      dailyUsed: Double, dailyLimit: Double) throws -> String {
    guard amount > 0 else {
        throw TransferError.invalidAmount
    }
    guard !toAccountId.isEmpty else {
        throw TransferError.accountNotFound(id: toAccountId)
    }
    guard amount <= fromBalance else {
        throw TransferError.insufficientFunds(available: fromBalance)
    }
    guard dailyUsed + amount <= dailyLimit else {
        throw TransferError.dailyLimitExceeded(limit: dailyLimit, attempted: dailyUsed + amount)
    }
    if toAccountId == "ERR_NET" {
        throw TransferError.networkUnavailable
    }
    return String(format: "Transfer of $%.2f to account %@ complete", amount, toAccountId)
}

func runTransferDemo() {
    let scenarios: [(amount: Double, fromBalance: Double, toAccountId: String, dailyUsed: Double, dailyLimit: Double)] = [
        (-100, 5000, "ACC-002", 0, 10_000),
        (100, 5000, "", 0, 10_000),
        (6000, 5000, "ACC-002", 0, 10_000),
        (500, 5000, "ACC-002", 9_800, 10_000),
        (100, 5000, "ERR_NET", 0, 10_000),
        (500, 5000, "ACC-002", 0, 10_000)
    ]

    for scenario in scenarios {
        do {
            let result = try executeTransfer(
                amount: scenario.amount,
                fromBalance: scenario.fromBalance,
                toAccountId: scenario.toAccountId,
                dailyUsed: scenario.dailyUsed,
                dailyLimit: scenario.dailyLimit
            )
            print(result)
        } catch let error as TransferError {
            print(error.errorDescription ?? "Unknown transfer error")
        } catch {
            print("Unexpected error: \(error)")
        }
    }
}

runTransferDemo()

func demonstrateTryOptional() {
    let failureResult = try? executeTransfer(amount: -100, fromBalance: 5000, toAccountId: "ACC-002", dailyUsed: 0, dailyLimit: 10_000)
    print(failureResult ?? "Transfer failed")

    let successResult = try? executeTransfer(amount: 500, fromBalance: 5000, toAccountId: "ACC-002", dailyUsed: 0, dailyLimit: 10_000)
    print(successResult ?? "Transfer failed")
}

demonstrateTryOptional()


 

func printFirst<T>(_ items: [T]) {
    if let first = items.first {
        print(first)
    } else {
        print("Array is empty")
    }
}

printFirst([1, 2, 3])
printFirst(["a", "b", "c"])
printFirst([1.5, 2.5, 3.5])
printFirst([Int]())


struct Stack<Element> {
    private var items: [Element] = []

    mutating func push(_ item: Element) {
        items.append(item)
    }

    mutating func pop() -> Element? {
        items.popLast()
    }

    var top: Element? {
        items.last
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    var count: Int {
        items.count
    }
}

func demonstrateStack() {
    var amountHistory = Stack<Double>()
    amountHistory.push(250.00)
    amountHistory.push(45.67)
    amountHistory.push(1200.00)

    let popped = amountHistory.pop()
    print(popped ?? "empty")
    print(amountHistory.top ?? "empty")
    print(amountHistory.count)
}

demonstrateStack()


func findLargest<T: Comparable>(_ items: [T]) -> T? {
    items.max()
}

print(findLargest([3, 7, 2, 9, 4]) as Any)
print(findLargest([3.1, 7.6, 2.2]) as Any)
print(findLargest(["banana", "apple", "cherry"]) as Any)
print(findLargest([Int]()) as Any)