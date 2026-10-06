package com.pnc.jetpackcomposedemos.features.transfer


interface AccountsRepository {
    suspend fun transfer(fromId: String, toId: String, amount: Double): Result<Unit>
}