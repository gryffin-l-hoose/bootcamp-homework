//
//  2026-09-11TransferLab.swift
//  TransferLab
//
//  Created by user302021 on 9/14/26.
//

import Foundation

struct Account: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let maskedNumber: String
    let balance: Decimal
}

protocol AccountsRepository {
    func transfer(amount: Decimal, from: Account, to: Account) async throws
}

enum TransferError: Error, Equatable {
    case invalidAmount
    case insufficientFunds
}

struct TransferEligibilityService {
    func canTransfer(amount: Decimal, from account: Account) -> Result<Void, TransferError> {
        guard amount > 0 else { return .failure(.invalidAmount) }
        guard account.balance >= amount else { return .failure(.insufficientFunds) }
        return .success(())
    }
}

final class TransferViewModel {
    private let repository: AccountsRepository
    private let eligibilityService: TransferEligibilityService

    var onError: ((TransferError) -> Void)?
    var onSuccess: (() -> Void)?

    init(
        repository: AccountsRepository,
        eligibilityService: TransferEligibilityService = TransferEligibilityService()
    ) {
        self.repository = repository
        self.eligibilityService = eligibilityService
    }

    func attemptTransfer(amount: Decimal, from: Account, to: Account) async {
        switch eligibilityService.canTransfer(amount: amount, from: from) {
        case .failure(let error):
            onError?(error)
        case .success:
            do {
                try await repository.transfer(amount: amount, from: from, to: to)
                onSuccess?()
            } catch let error as TransferError {
                onError?(error)
            } catch {}
        }
    }
}

final class FakeAccountsRepository: AccountsRepository {
    private(set) var transferCallCount = 0
    var shouldThrow = false

    func transfer(amount: Decimal, from: Account, to: Account) async throws {
        transferCallCount += 1
        if shouldThrow { throw TransferError.insufficientFunds }
    }
}

func makeAccounts(balance: Decimal) -> (from: Account, to: Account) {
    (
        Account(name: "Checking", maskedNumber: "•••• 4471", balance: balance),
        Account(name: "Savings", maskedNumber: "•••• 9902", balance: 0)
    )
}

func runTransferLabChecks() async {
    func check(_ name: String, _ passed: Bool) {
        print(passed ? "PASS  \(name)" : "FAIL  \(name)")
    }

    do {
        let fake = FakeAccountsRepository()
        let vm = TransferViewModel(repository: fake)
        let (from, to) = makeAccounts(balance: 500)
        var succeeded = false
        vm.onSuccess = { succeeded = true }
        await vm.attemptTransfer(amount: 100, from: from, to: to)
        check("transfer below balance succeeds", succeeded && fake.transferCallCount == 1)
    }

    do {
        let fake = FakeAccountsRepository()
        let vm = TransferViewModel(repository: fake)
        let (from, to) = makeAccounts(balance: 50)
        var received: TransferError?
        vm.onError = { received = $0 }
        await vm.attemptTransfer(amount: 100, from: from, to: to)
        check("over balance fails without network", received == .insufficientFunds && fake.transferCallCount == 0)
    }

    do {
        let fake = FakeAccountsRepository()
        let vm = TransferViewModel(repository: fake)
        let (from, to) = makeAccounts(balance: 500)
        var received: TransferError?
        vm.onError = { received = $0 }
        await vm.attemptTransfer(amount: 0, from: from, to: to)
        check("zero amount rejected", received == .invalidAmount && fake.transferCallCount == 0)
    }
}
