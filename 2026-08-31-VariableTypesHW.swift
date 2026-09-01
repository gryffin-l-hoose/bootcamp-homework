// MODULE 4: Swift Programming Fundamtals

import Foundation


// EXERCISE 1: Constants and Variables


let appName = "PNC Mobile"
var loginAttempts = 0
loginAttempts += 1
let accountBalance: Double = 4_250.75
var interestRate: Double = 0.035

print(appName)
print(loginAttempts)
print(accountBalance)
print(interestRate)


// EXERCISE 2: Working with Strings


let firstName = "Jane"
let lastName = "Smith"
let fullName = "\(firstName) \(lastName)"
let greeting = "Welcome to \(appName), \(fullName). Your account is active."
let accountNumber = "1234567890"
let maskedAccount = "****\(accountNumber.suffix(4))"

print("Full-name character count: \(fullName.count)")
print(greeting)
print(maskedAccount)


// EXERCISE 3: Type Safety and Conversion


let transactionCount = 47
let transactionTotal = 12_309.88
let averageTransaction = transactionTotal / Double(transactionCount)
let summary = "\(transactionCount) transactions averaging $\(String(format: \"%.2f\", averageTransaction)) each"

print(summary)

let rawInput = "2500"
let parsedAmount = Int(rawInput)

if let parsedAmount {
    print("Parsed amount: \(parsedAmount)")
} else {
    print("Invalid input")
}


// EXERCISE 4: Control Flow


let balance: Double = 8_500.00

if balance > 25_000 {
    print("Private Banking eligible")
} else if balance > 10_000 {
    print("Preferred client")
} else if balance > 1_000 {
    print("Standard account")
} else {
    print("Low balance alert")
}

let creditScore = 714
let creditRating: String

switch creditScore {
case 800...850:
    creditRating = "Exceptional"
case 740...799:
    creditRating = "Very Good"
case 670...739:
    creditRating = "Good"
case 580...669:
    creditRating = "Fair"
default:
    creditRating = "Poor"
}

print("Credit rating: \(creditRating)")

let transactionType = "transfer"
let transactionMessage: String

switch transactionType {
case "deposit":
    transactionMessage = "Processing deposit"
case "withdrawal":
    transactionMessage = "Processing withdrawal"
case "transfer":
    transactionMessage = "Processing transfer"
default:
    transactionMessage = "Unknown transaction type: \(transactionType)"
}

print(transactionMessage)

func processWithdrawal(amount: Double, availableBalance: Double) -> String {
    guard amount > 0 else {
        return "Invalid amount"
    }

    guard amount <= availableBalance else {
        return "Insufficient funds. Available: $\(String(format: \"%.2f\", availableBalance))"
    }

    return "Withdrawal of $\(String(format: \"%.2f\", amount)) approved"
}

print(processWithdrawal(amount: -50, availableBalance: 1_000))
print(processWithdrawal(amount: 2_000, availableBalance: 1_000))
print(processWithdrawal(amount: 500, availableBalance: 1_000))

// EXERCISE 5: Loops and Collections


for number in 1...10 {
    print("7 x \(number) = \(7 * number)")
}

for number in 1...20 where number % 2 == 0 {
    print(number)
}

let accounts = ["Checking", "Savings", "Investment", "Credit Card"]

for account in accounts {
    print("• \(account)")
}

for (index, account) in accounts.enumerated() {
    print("\(index + 1). \(account)")
}

var attempts = 0
var connected = false

while !connected && attempts < 3 {
    attempts += 1
    print("Connection attempt \(attempts)...")

    if attempts == 3 {
        connected = true
        print("Connected.")
    }
}
