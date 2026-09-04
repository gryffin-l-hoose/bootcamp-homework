import Foundation


enum TransactionType: String, CaseIterable, Codable {
    case credit
    case debit
    case transfer
    case fee

    var isExpense: Bool {
        switch self {
        case .debit, .fee:
            return true
        case .credit, .transfer:
            return false
        }
    }
}


enum TransactionStatus: String, Codable {
    case pending
    case completed
    case failed
    case cancelled

    var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        case .pending:
            return false
        }
    }
}



protocol Summarizable {
    var summary: String { get }
}

extension Summarizable {
    func printSummary() {
        print(summary)
    }
}


enum AccountOperationsError: LocalizedError {
    case invalidAmount
    case insufficientFunds(available: Double, required: Double)
    case accountInactive
    case transferToSameAccount
    case dailyLimitExceeded(limit: Double)

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Transaction amount must be greater than zero."
        case .insufficientFunds(let available, let required):
            let formattedAvailable = String(format: "$%.2f", available)
            let formattedRequired = String(format: "$%.2f", required)
            return "Insufficient funds: Available \(formattedAvailable), required \(formattedRequired)."
        case .accountInactive:
            return "Operation failed: The account is currently inactive."
        case .transferToSameAccount:
            return "Cannot transfer funds to the same account."
        case .dailyLimitExceeded(let limit):
            let formattedLimit = String(format: "$%.2f", limit)
            return "Transaction exceeds the daily limit of \(formattedLimit)."
        }
    }
}


protocol AccountOperations {
    func deposit(amount: Double) throws
    func withdraw(amount: Double) throws
    func transfer(amount: Double, to destination: BankAccount) throws
}




struct Transaction: Identifiable, Codable, Equatable, Hashable, Summarizable {
    let id: String
    let date: Date
    var amount: Double
    var description: String
    let type: TransactionType
    var status: TransactionStatus
    var category: String?
    var merchantName: String?

    var formattedAmount: String {
        let formatted = String(format: "$%.2f", amount)
        return type.isExpense ? "-\(formatted)" : "+\(formatted)"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var resolvedCategory: String {
        return category ?? "Uncategorized"
    }

    var summary: String {
        return "[\(formattedDate)] \(description) (\(resolvedCategory)): \(formattedAmount) [\(status.rawValue.capitalized)]"
    }

    init(
        id: String = UUID().uuidString,
        date: Date,
        amount: Double,
        description: String,
        type: TransactionType,
        status: TransactionStatus = .completed,
        category: String? = nil,
        merchantName: String? = nil
    ) {
        self.id = id
        self.date = date
        self.amount = abs(amount)
        self.description = description
        self.type = type
        self.status = status
        self.category = category
        self.merchantName = merchantName
    }
}


class BankAccount: Identifiable, AccountOperations, Summarizable {
    let id: String
    let accountNumber: String
    let accountType: String
    var nickname: String?
    var balance: Double
    var availableBalance: Double
    let currency: String
    let isActive: Bool
    var transactions: [Transaction]

    var displayName: String {
        return nickname ?? accountType.capitalized
    }

    var maskedAccountNumber: String {
        let lastFour = accountNumber.suffix(4)
        return "****\(lastFour)"
    }

    var formattedBalance: String {
        return String(format: "$%.2f", balance)
    }

    var recentTransactions: [Transaction] {
        return Array(transactions.sorted(by: { $0.date > $1.date }).prefix(5))
    }

    var pendingCount: Int {
        return transactions.filter { $0.status == .pending }.count
    }

    var summary: String {
        return "\(displayName) (\(maskedAccountNumber)): Balance \(formattedBalance) | \(transactions.count) Transactions"
    }

    init(
        id: String = UUID().uuidString,
        accountNumber: String,
        accountType: String,
        nickname: String? = nil,
        initialBalance: Double,
        currency: String = "USD",
        isActive: Bool = true,
        transactions: [Transaction] = []
    ) {
        self.id = id
        self.accountNumber = accountNumber
        self.accountType = accountType
        self.nickname = nickname
        self.balance = initialBalance
        self.availableBalance = initialBalance
        self.currency = currency
        self.isActive = isActive
        self.transactions = transactions
    }

    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        if transaction.type.isExpense {
            balance -= transaction.amount
        } else {
            balance += transaction.amount
        }
        availableBalance = balance
    }

   
    func deposit(amount: Double) throws {
        guard isActive else { throw AccountOperationsError.accountInactive }
        guard amount > 0 else { throw AccountOperationsError.invalidAmount }

        let tx = Transaction(
            date: Date(),
            amount: amount,
            description: "Deposit",
            type: .credit,
            category: "Income"
        )
        addTransaction(tx)
    }

    func withdraw(amount: Double) throws {
        guard isActive else { throw AccountOperationsError.accountInactive }
        guard amount > 0 else { throw AccountOperationsError.invalidAmount }
        guard availableBalance >= amount else {
            throw AccountOperationsError.insufficientFunds(available: availableBalance, required: amount)
        }

        let tx = Transaction(
            date: Date(),
            amount: amount,
            description: "Withdrawal",
            type: .debit,
            category: "Cash"
        )
        addTransaction(tx)
    }

    func transfer(amount: Double, to destination: BankAccount) throws {
        guard isActive && destination.isActive else { throw AccountOperationsError.accountInactive }
        guard id != destination.id else { throw AccountOperationsError.transferToSameAccount }
        guard amount > 0 else { throw AccountOperationsError.invalidAmount }
        guard availableBalance >= amount else {
            throw AccountOperationsError.insufficientFunds(available: availableBalance, required: amount)
        }

        let outgoingTx = Transaction(
            date: Date(),
            amount: amount,
            description: "Transfer to \(destination.displayName)",
            type: .transfer,
            category: "Transfer"
        )
        addTransaction(outgoingTx)

        let incomingTx = Transaction(
            date: Date(),
            amount: amount,
            description: "Transfer from \(self.displayName)",
            type: .credit,
            category: "Transfer"
        )
        destination.addTransaction(incomingTx)
    }
}



protocol AnalyticsProvider {
    var totalCredits: Double { get }
    var totalDebits: Double { get }
    var netFlow: Double { get }
    var largestTransaction: Transaction? { get }
    func monthlyTotal(month: Int, year: Int) -> Double
    func transactionsByCategory() -> [String: [Transaction]]
}


struct AccountAnalytics: AnalyticsProvider {
    let transactions: [Transaction]

    var totalCredits: Double {
        return transactions
            .filter { !$0.type.isExpense }
            .reduce(0) { $0 + $1.amount }
    }

    var totalDebits: Double {
        return transactions
            .filter { $0.type.isExpense }
            .reduce(0) { $0 + $1.amount }
    }

    var netFlow: Double {
        return totalCredits - totalDebits
    }

    var largestTransaction: Transaction? {
        return transactions.max(by: { $0.amount < $1.amount })
    }

    func monthlyTotal(month: Int, year: Int) -> Double {
        let calendar = Calendar.current
        return transactions
            .filter { tx in
                let components = calendar.dateComponents([.month, .year], from: tx.date)
                return components.month == month && components.year == year && tx.type.isExpense
            }
            .reduce(0) { $0 + $1.amount }
    }

    func transactionsByCategory() -> [String: [Transaction]] {
        return Dictionary(grouping: transactions, by: { $0.resolvedCategory })
    }
}



func reportResults<T: Summarizable>(_ items: [T], title: String) {
    print("=== \(title) ===")
    print("[\(items.count)] items")
    for item in items {
        item.printSummary()
    }
    print("=== End of \(title) ===\n")
}



func runlabDemo() {
    print("=======================================")
    print("PNC Mobile Banking Domain Model Demo")
    print("=======================================\n")

   
    let checkingAccount = BankAccount(
        accountNumber: "1234567890",
        accountType: "CHECKING",
        nickname: "Virtual Wallet Checking",
        initialBalance: 3500.00
    )

    let savingsAccount = BankAccount(
        accountNumber: "0987654321",
        accountType: "SAVINGS",
        nickname: "Growth Savings",
        initialBalance: 12000.00
    )

   
    let tx1 = Transaction(date: Date(), amount: 1500.00, description: "Payroll Direct Deposit", type: .credit, category: "Income")
    let tx2 = Transaction(date: Date(), amount: 84.50, description: "Grocery Store", type: .debit, category: "Food & Dining", merchantName: "Giant Eagle")
    let tx3 = Transaction(date: Date(), amount: 12.99, description: "Streaming Service", type: .debit, category: "Entertainment")
    let tx4 = Transaction(date: Date(), amount: 3.00, description: "Out-of-Network ATM Fee", type: .fee, category: "Fees")
    let tx5 = Transaction(date: Date(), amount: 200.00, description: "Savings Transfer", type: .transfer, category: "Transfer")

    checkingAccount.addTransaction(tx1)
    checkingAccount.addTransaction(tx2)
    checkingAccount.addTransaction(tx3)
    checkingAccount.addTransaction(tx4)
    checkingAccount.addTransaction(tx5)

    print("Updated Checking Account Balance: \(checkingAccount.formattedBalance)\n")

    
    print("--- Demonstrating Error Handling ---")
    
    
    do {
        try checkingAccount.withdraw(amount: 10000.00)
    } catch {
        print("Caught Expected Error: \(error.localizedDescription)")
    }

   
    do {
        try checkingAccount.deposit(amount: -50.00)
    } catch {
        print("Caught Expected Error: \(error.localizedDescription)")
    }

    
    do {
        try checkingAccount.transfer(amount: 100.00, to: checkingAccount)
    } catch {
        print("Caught Expected Error: \(error.localizedDescription)")
    }
    print()

    
    print("--- Account Analytics ---")
    let analytics = AccountAnalytics(transactions: checkingAccount.transactions)
    print("Total Credits: \(String(format: "$%.2f", analytics.totalCredits))")
    print("Total Debits: \(String(format: "$%.2f", analytics.totalDebits))")
    print("Net Flow: \(String(format: "$%.2f", analytics.netFlow))")

    if let largest = analytics.largestTransaction {
        print("Largest Transaction: \(largest.description) (\(largest.formattedAmount))")
    }

    print("Categories Breakdown:")
    for (category, txs) in analytics.transactionsByCategory() {
        print(" - \(category): \(txs.count) transaction(s)")
    }
    print()

   
    reportResults(checkingAccount.transactions, title: "Checking Transactions")
    reportResults([checkingAccount, savingsAccount], title: "All Accounts")

   
    print("--- Value vs. Reference Semantics ---")
    
    
    let originalTx = tx2
    var copiedTx = originalTx
    copiedTx.description = "Updated Merchant Description"
    print("Struct Copy Modification:")
    print(" Original Description: \(originalTx.description)")
    print(" Copied Description:   \(copiedTx.description)")

    
    let accountAlias = checkingAccount
    do {
        try accountAlias.deposit(amount: 100.00)
        print("\nClass Reference Modification via Alias:")
        print(" Original Account Balance: \(checkingAccount.formattedBalance)")
        print(" Alias Account Balance:    \(accountAlias.formattedBalance)")
    } catch {
        print("Deposit failed: \(error.localizedDescription)")
    }
}



runlabDemo()