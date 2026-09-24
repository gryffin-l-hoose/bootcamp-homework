
@file:DependsOn("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.11.0")
import kotlinx.coroutines.*

// 1 — Account data class
data class Account(
    val id: String,
    val name: String,
    val balance: Double
)

// 2: TransferResult sealed class
sealed class TransferResult {
    data class Success(val confirmationId: String) : TransferResult()
    data class Failure(val reason: String) : TransferResult()
}

fun describe(result: TransferResult): String = when (result) {
    is TransferResult.Success -> "Transfer succeeded. Confirmation ID: ${result.confirmationId}"
    is TransferResult.Failure -> "Transfer failed. Reason: ${result.reason}"
}

// 3: Double.asCurrency() extension function
fun Double.asCurrency(): String = "$${"%.2f".format(this)}"

// 4 — suspend function simulating a network fetch
suspend fun fetchAccounts(): List<Account> {
    delay(500)
    return listOf(
        Account(id = "acc-1001", name = "Checking", balance = 4281.16),
        Account(id = "acc-1002", name = "Savings", balance = 12500.00),
        Account(id = "acc-1003", name = "Overdraft Protection", balance = -237.45),
        Account(id = "acc-1004", name = "Travel Fund", balance = 890.50)
    )
}

fun main() = runBlocking {
    println("Fetching accounts...")
    val accounts = fetchAccounts()

    println("\nAccounts:")
    accounts.forEach { account ->
        println("  ${account.name} (${account.id}): ${account.balance.asCurrency()}")
    }

    // 5 — collection operations
    val overdraftAccounts = accounts.filter { it.balance < 0 }
    val totalBalance = accounts.sumOf { it.balance }

    println("\nOverdraft accounts:")
    if (overdraftAccounts.isEmpty()) {
        println("  None")
    } else {
        overdraftAccounts.forEach { account ->
            println("  ${account.name} (${account.id}): ${account.balance.asCurrency()}")
        }
    }

    println("\nTotal balance: ${totalBalance.asCurrency()}")

    // Demonstrate TransferResult + exhaustive when
    val success = TransferResult.Success(confirmationId = "TXN-88421")
    val failure = TransferResult.Failure(reason = "Insufficient funds")
    println("\nTransfer results:")
    println("  ${describe(success)}")
    println("  ${describe(failure)}")
}

main()






