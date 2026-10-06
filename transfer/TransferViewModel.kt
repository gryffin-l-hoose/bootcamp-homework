package com.pnc.jetpackcomposedemos.features.transfer



import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

sealed class TransferUiState {
    data object Idle : TransferUiState()
    data object Success : TransferUiState()
    data class Error(val message: String) : TransferUiState()
}

@HiltViewModel
class TransferViewModel @Inject constructor(
    private val transferFunds: TransferFundsUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow<TransferUiState>(TransferUiState.Idle)
    val uiState: StateFlow<TransferUiState> = _uiState.asStateFlow()

    fun attemptTransfer(amount: Double, from: Account, to: Account) {
        viewModelScope.launch {
            val result = transferFunds(amount, from, to)
            _uiState.update {
                result.fold(
                    onSuccess = { TransferUiState.Success },
                    onFailure = { TransferUiState.Error(it.message ?: "Transfer failed") }
                )
            }
        }
    }
}