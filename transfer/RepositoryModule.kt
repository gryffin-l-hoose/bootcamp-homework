package com.pnc.jetpackcomposedemos.features.transfer

import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Inject
import javax.inject.Singleton

class AccountsRepositoryImpl @Inject constructor() : AccountsRepository {
    override suspend fun transfer(fromId: String, toId: String, amount: Double): Result<Unit> {
        return Result.success(Unit)
    }
}

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    @Binds
    @Singleton
    abstract fun bindAccountsRepository(impl: AccountsRepositoryImpl): AccountsRepository
}
