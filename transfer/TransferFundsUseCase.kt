package com.pnc.jetpackcomposedemos.features.transfer

import javax.inject.Inject

class TransferEligibilityService @Inject constructor() {
    fun canTransfer(amount: Double, from: Account): Boolean {
        return amount > 0 && from.balance >= amount
    }
}

class TransferFundsUseCase @Inject constructor(
    private val repository: AccountsRepository,
    private val eligibility: TransferEligibilityService
) {
    suspend operator fun invoke(
        amount: Double,
        from: Account,
        to: Account
    ): Result<Unit> {
        if (!eligibility.canTransfer(amount, from)) {
            return Result.failure(IllegalArgumentException("Transfer not allowed"))
        }
        return repository.transfer(from.id, to.id, amount)
    }
}