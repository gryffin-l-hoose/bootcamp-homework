import Foundation

// MARK: - Structs: value types

struct Transaction {
    let id: String
    let date: Date
    let amount: Double
    var description: String
    let isDebit: Bool
    var isPending: Bool = false

    var formattedAmount: String {
        let sign = isDebit ? "-" : "+"
        return "\(sign)$\(String(format: "%.2f", abs(amount)))"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    mutating func markAsPending() {
        isPending = true
    }
}

let t1 = Transaction(
    id: "txn_001",
    date: Date(),
    amount: 2_500.00,
    description: "Direct Deposit",
    isDebit: false
)

var t2 = Transaction(
    id: "txn_002",
    date: Date(),
    amount: 45.67,
    description: "Starbucks",
    isDebit: true
)

print("\(t1.formattedAmount) — \(t1.description)")
print("\(t2.formattedAmount) — \(t2.description)")
print("Transaction date: \(t1.formattedDate)")

var t3 = t1
t3.description = "Modified"
print("t1 description: \(t1.description)")
print("t3 description: \(t3.description)")

t2.markAsPending()
print("Is \(t2.description) pending? \(t2.isPending)")

// MARK: - Classes: reference types

class BankAccount {
    let id: String
    let accountNumber: String
    var balance: Double
    let owner: String

    init(id: String, accountNumber: String, owner: String, initialBalance: Double = 0.0) {
        self.id = id
        self.accountNumber = accountNumber
        self.owner = owner
        self.balance = initialBalance
    }

    func deposit(amount: Double) {
        guard amount > 0 else { return }
        balance += amount
    }

    func withdraw(amount: Double) -> Bool {
        guard amount > 0, amount <= balance else { return false }
        balance -= amount
        return true
    }

    func printSummary() {
        print("Account \(accountNumber) | Owner: \(owner) | Balance: $\(String(format: "%.2f", balance))")
    }
}

let checking = BankAccount(
    id: "acc_001",
    accountNumber: "1234567890",
    owner: "Jane Smith",
    initialBalance: 1_000.00
)

let savings = BankAccount(
    id: "acc_002",
    accountNumber: "0987654321",
    owner: "Jane Smith",
    initialBalance: 5_000.00
)

checking.deposit(amount: 200.00)
_ = checking.withdraw(amount: 125.50)
checking.printSummary()
savings.printSummary()

let checkingRef = checking
checkingRef.deposit(amount: 500.00)
print("checking balance: $\(String(format: "%.2f", checking.balance))")
print("checkingRef balance: $\(String(format: "%.2f", checkingRef.balance))")

class PremiumBankAccount: BankAccount {
    var overdraftLimit: Double = 0.0

    convenience init(
        id: String,
        accountNumber: String,
        owner: String,
        initialBalance: Double = 0.0,
        overdraftLimit: Double
    ) {
        self.init(
            id: id,
            accountNumber: accountNumber,
            owner: owner,
            initialBalance: initialBalance
        )
        self.overdraftLimit = overdraftLimit
    }

    override func withdraw(amount: Double) -> Bool {
        guard amount > 0, amount <= balance + overdraftLimit else { return false }
        balance -= amount
        return true
    }
}

let premium = PremiumBankAccount(
    id: "acc_003",
    accountNumber: "1111222233",
    owner: "Jane Smith",
    initialBalance: 100.00,
    overdraftLimit: 500.00
)

print("Premium withdrawal of $400 succeeds: \(premium.withdraw(amount: 400.00))")
print("Premium withdrawal of $800 succeeds: \(premium.withdraw(amount: 800.00))")
premium.printSummary()

// MARK: - Enumerations

enum TransactionType: String, CaseIterable {
    case credit, debit, transfer, fee

    var displayName: String {
        switch self {
        case .credit: return "Credit"
        case .debit: return "Debit"
        case .transfer: return "Transfer"
        case .fee: return "Fee"
        }
    }
}

enum AccountError {
    case insufficientFunds(available: Double, requested: Double)
    case accountInactive
    case dailyLimitExceeded(limit: Double)
    case invalidAmount
}

func describeError(_ error: AccountError) -> String {
    switch error {
    case let .insufficientFunds(available, requested):
        return "Insufficient funds: $\(String(format: "%.2f", available)) available, $\(String(format: "%.2f", requested)) requested."
    case .accountInactive:
        return "This account is inactive."
    case let .dailyLimitExceeded(limit):
        return "This transaction exceeds the daily limit of $\(String(format: "%.2f", limit))."
    case .invalidAmount:
        return "Enter an amount greater than zero."
    }
}

let errors: [AccountError] = [
    .insufficientFunds(available: 25.00, requested: 100.00),
    .accountInactive,
    .dailyLimitExceeded(limit: 1_000.00),
    .invalidAmount
]

for error in errors {
    print(describeError(error))
}

for type in TransactionType.allCases {
    print("\(type.displayName) → \(type.rawValue)")
}