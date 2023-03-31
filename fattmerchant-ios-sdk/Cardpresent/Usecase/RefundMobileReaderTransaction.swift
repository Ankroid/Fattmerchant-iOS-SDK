//
//  RefundMobileReaderTransaction.swift
//  fattmerchant-ios-sdk
//
//  Created by Tulio Troncoso on 1/16/20.
//  Copyright © 2020 Fattmerchant. All rights reserved.
//

import Foundation

enum RefundException: StaxException {
    case transactionNotRefundable(details: String?)
    case missingTransactionId
    case couldNotFindMobileReaderForRefund
    case errorRefunding(details: String?)

    static var mess: String = "Could not refund transaction"

    var detail: String? {
        switch self {
        case .transactionNotRefundable(let d):
            return d ?? "Transaction is not refundable"

        case .couldNotFindMobileReaderForRefund:
            return "Mobile reader driver responsible for performing refund could not be found"

        case .errorRefunding(let d):
            return d ?? "Error while performing refund"

        case .missingTransactionId:
            return "Transaction id not provided"
        }
    }
}

class RefundMobileReaderTransaction {

    typealias Exception = RefundException

    var mobileReaderDriverRepository: MobileReaderDriverRepository
    var transactionRepository: TransactionRepository
    var staxApi: StaxApi
    var transaction: Transaction
    var refundAmount: Amount?

    init(mobileReaderDriverRepository: MobileReaderDriverRepository,
         transactionRepository: TransactionRepository,
         transaction: Transaction,
         refundAmount: Amount? = nil,
         staxApi: StaxApi) {

        // Get the amount to refund
        var amount: Amount?
        if let amt = refundAmount {
            amount = amt
        } else if let total = transaction.total {
            amount = Amount(dollars: total)
        }

        self.mobileReaderDriverRepository = mobileReaderDriverRepository
        self.transactionRepository = transactionRepository
        self.transaction = transaction
        self.refundAmount = amount
        self.staxApi = staxApi
    }

    func start(completion: @escaping (Transaction) -> Void, failure: @escaping (StaxException) -> Void ) {
        // Make sure the transaction has an id
        guard let transactionId = transaction.id else {
            return failure(RefundException.missingTransactionId)
        }

        // Get the driver
        mobileReaderDriverRepository.getDriverFor(transaction: transaction) { driver in
            guard let driver = driver else {
                return failure(Exception.couldNotFindMobileReaderForRefund)
            }

            // If stax can do the refund, then we should call out to Stax to do it
            if type(of: driver).staxRefundsSupported {
                self.staxApi.request(method: "post",
                                     urlString: "/transaction/\(transactionId)/void-or-refund", body: nil,
                                     completion: completion, failure: failure)
            } else {
                // Stax can *not* do the refund, so we have to do it
                if let error = RefundMobileReaderTransaction.validateRefund(transaction: transaction, refundAmount: refundAmount) {
                    failure(error)
                    return
                }

                // Do the 3rd-party refund
                driver.refund(transaction: transaction, refundAmount: refundAmount, completion: { result in
                    self.postRefundedTransaction(with: result, failure: failure, completion: completion)
                }, error: failure)
            }
        }
    }

    fileprivate func postRefundedTransaction(with result: TransactionResult, failure: @escaping (StaxException) -> Void, completion: @escaping (Transaction) -> Void) {
        let refundedTransaction = Transaction()
        refundedTransaction.total = result.amount?.dollars()
        refundedTransaction.paymentMethodId = transaction.paymentMethodId
        refundedTransaction.success = result.success
        refundedTransaction.lastFour = transaction.lastFour
        refundedTransaction.type = "refund"
        refundedTransaction.source = transaction.source
        refundedTransaction.referenceId = transaction.id
        refundedTransaction.method = transaction.method
        refundedTransaction.customerId = transaction.customerId
        refundedTransaction.invoiceId = transaction.invoiceId
        transactionRepository.create(model: refundedTransaction, completion: completion, error: failure)
    }

    /// Verifies that the refund about to happen is acceptable
    /// - Returns: StaxException explaining why the refund should not happen. `nil` if the refund is acceptable
    internal static func validateRefund(transaction: Transaction, refundAmount: Amount? = nil) -> StaxException? {
        // Ensure transaction isn't voided
        if transaction.isVoided == true {
            return Exception.transactionNotRefundable(details: "Can not refund voided transaction")
        }

        // Account for previous refunds
        if let totalRefunded = transaction.totalRefunded, let transactionTotal = transaction.total {

            // Can't refund transaction that has already been refunded
            if transactionTotal - totalRefunded < 0.01 {
                return Exception.transactionNotRefundable(details: "Can not refund transaction that has been fully refunded")
            }

            // Can't refund more than there is left to refund
            if let refundAmount = refundAmount, refundAmount.dollars() > (transactionTotal - totalRefunded) {
                return Exception.transactionNotRefundable(details: "Can not refund more than the original transaction total")
            }

            // Can't refund zero amount
            if let refundAmount = refundAmount?.dollars(), refundAmount <= 0.0 {
                return Exception.transactionNotRefundable(details: "Can not refund zero or negative amounts")
            }
        }

        return nil
    }

}
