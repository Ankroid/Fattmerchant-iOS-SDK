//
//  Omni.swift
//  fattmerchant-ios-sdk
//
//  Created by Tulio Troncoso on 1/16/20.
//  Copyright © 2020 Fattmerchant. All rights reserved.
//

import Foundation

enum OmniNetworkingException: OmniException {
  case couldNotGetMerchantDetails
  case couldNotGetPaginatedTransactions

  static var mess: String = "Omni Networking Exception"

  var detail: String? {
    switch self {
    case .couldNotGetMerchantDetails:
      return "Could not get merchant details from Omni"

    case .couldNotGetPaginatedTransactions:
      return "Could not get paginated transactions"
    }
  }
}

enum OmniGeneralException: OmniException {
  case uninitialized

  static var mess: String = "Omni General Error"

  var detail: String? {
    switch self {
    case .uninitialized:
      return "Omni has not been initialized yet"
    }
  }
}

/**
 Handles cardpresent payments

 This is the object you used for communicating with the Omni platform

 ## Usage
 Create an instance of Omni
 ```
 let omni = Omni()
 ```
 Then initialize, passing in an instance of InitParams
 ```
 let omniInitParms = Omni.InitParams(appId: "Myappid", apiKey: "omniephemeralkey")
 omni.initialize(omniInitParams, completion: ..., error: ...)
 ```

 Once initialized, you can call its methods like `getAvailableReaders` and `takeMobileReaderTransaction`
 */
public class Omni: NSObject {

  private var initialized: Bool = false
  private var omniApi = OmniApi()
  private var transactionRepository: TransactionRepository!
  private var invoiceRepository: InvoiceRepository!
  private var customerRepository: CustomerRepository!
  private var paymentMethodRepository: PaymentMethodRepository!
  private var mobileReaderDriverRepository = MobileReaderDriverRepository()

  /// The queue that Omni should use to communicate back with its listeners
  public var preferredQueue: DispatchQueue = DispatchQueue.main

  /// Contains all the data necessary to initialize `Omni`
  public struct InitParams {
    /// An id for your application
    public var appId: String

    /// An ephemeral Omni api key
    public var apiKey: String

    /// The Omni enviroment to use
    public var environment: Environment

    public init(appId: String, apiKey: String, environment: Environment = Environment.LIVE) {
      self.appId = appId
      self.apiKey = apiKey
      self.environment = environment
    }
  }

  fileprivate func initRepos(omniApi: OmniApi) {
    transactionRepository = TransactionRepository(omniApi: omniApi)
    invoiceRepository = InvoiceRepository(omniApi: omniApi)
    customerRepository = CustomerRepository(omniApi: omniApi)
    paymentMethodRepository = PaymentMethodRepository(omniApi: omniApi)
  }

  /// True when Omni is initialized. False otherwise
  public var isInitialized: Bool {
    return initialized
  }

  /// Used to initialize the Omni object
  /// - Parameters:
  ///   - params: an instance of InitParams which contains all necessary information to initialize omni
  ///   - completion: a completion block to run once finished
  ///   - error: an error block to run in case something goes wrong
  public func initialize(params: InitParams, completion: @escaping () -> Void, error: @escaping (OmniException) -> Void) {
    omniApi = OmniApi()
    omniApi.apiKey = params.apiKey
    omniApi.environment = params.environment
    initRepos(omniApi: omniApi)

    // Verify the apikey corresponds to a real merchant
    omniApi.getSelf(completion: { myself in

      guard let merchant = myself.merchant else {
        error(OmniNetworkingException.couldNotGetMerchantDetails)
        return
      }

      let args: [String: Any] = [
        "appId": params.appId,
        "merchant": merchant
      ]

      InitializeDrivers(mobileReaderDriverRepository: self.mobileReaderDriverRepository, args: args).start(completion: { _ in
        self.initialized = true
        self.preferredQueue.async(execute: completion)
      }, failure: error)
    }, failure: error)

  }

  /// Captures a mobile reader transaction
  /// - Parameters:
  ///   - request: A request for a Transaction
  ///   - completion: Called when the operation is complete successfully. Receives a Transaction
  ///   - error: Receives any errors that happened while attempting the operation
  public func takeMobileReaderTransaction(request: TransactionRequest, completion: @escaping (Transaction) -> Void, error: @escaping (OmniException) -> Void) {
    guard initialized else {
      return error(OmniGeneralException.uninitialized)
    }

    let job = TakeMobileReaderPayment(
      mobileReaderDriverRepository: mobileReaderDriverRepository,
      invoiceRepository: invoiceRepository,
      customerRepository: customerRepository,
      paymentMethodRepository: paymentMethodRepository,
      transactionRepository: transactionRepository,
      request: request
    )

    job.start(completion: completion, failure: error)
  }

  /// Refunds the given transaction and returns a new Transaction that represents the refund in Omni
  /// - Parameters:
  ///   - transaction: the transaction to refund
  ///   - refundAmount: the amount of money to refund. When present, this **must** be greater than zero and lesser than or equal to the transaction total
  ///   - completion: Receives the Transaction that represents the refund in Omni
  ///   - error: Receives any errors that happened while attempting the operation
  public func refundMobileReaderTransaction(transaction: Transaction, refundAmount: Amount? = nil, completion: @escaping (Transaction) -> Void, error: @escaping (OmniException) -> Void) {
    guard initialized else {
      return error(OmniGeneralException.uninitialized)
    }

    let job = RefundMobileReaderTransaction(mobileReaderDriverRepository: mobileReaderDriverRepository,
                                            transactionRepository: transactionRepository,
                                            transaction: transaction,
                                            refundAmount: refundAmount)
    job.start(completion: completion, failure: error)
  }

  /// Refunds the given transaction and returns a new Transaction that represents the refund in Omni
  /// - Parameters:
  ///   - transaction: the transaction to refund
  ///   - completion: Receives the Transaction that represents the refund in Omni
  ///   - error: Receives any errors that happened while attempting the operation
  public func refundMobileReaderTransaction(transaction: Transaction, completion: @escaping (Transaction) -> Void, error: @escaping (OmniException) -> Void) {
    refundMobileReaderTransaction(transaction: transaction, refundAmount: nil, completion: completion, error: error)
  }

  /// Finds the available readers that Omni can connect to
  /// - Parameters:
  ///   - completion: Receives an array of MobileReaders that are available
  ///   - error: Receives any errors that happened while attempting the operation
  public func getAvailableReaders(completion: @escaping ([MobileReader]) -> Void, error: @escaping (OmniException) -> Void) {
    guard initialized else {
      return error(OmniGeneralException.uninitialized)
    }

    SearchForReaders(mobileReaderDriverRepository: mobileReaderDriverRepository, args: [:]).start(completion: { (readers) in
      self.preferredQueue.async { completion(readers) }
    }, failure: ({ exception in
      self.preferredQueue.async { error(exception) }
    }))
  }

  /// Attempts to connect to the given MobileReader
  ///
  /// - Parameters:
  ///   - reader: The MobileReader to connect
  ///   - completion: A completion block to call once finished. It will receive the connected MobileReader
  ///   - error: A block to call if this operation fails
  public func connect(reader: MobileReader, completion: @escaping (MobileReader) -> Void, error: @escaping () -> Void) {
    guard initialized else {
      return error()
    }

    let task = ConnectMobileReader(mobileReaderDriverRepository: mobileReaderDriverRepository, mobileReader: reader)
    task.start { success in
      self.preferredQueue.async {
        if success {
          completion(reader)
        } else {
          error()
        }
      }
    }
  }

  /// Retrieves a list of the most recent mobile reader transactions from Omni
  /// - Parameters:
  ///   - completion: Receives a list of Transactions
  ///   - error: A block to call if this operation fails
  public func getMobileReaderTransactions(completion: @escaping ([Transaction]) -> Void, error: @escaping (OmniException) -> Void) {
    guard initialized else {
      return error(OmniGeneralException.uninitialized)
    }

    transactionRepository.getList(completion: ({ paginatedTransactions in
      guard let transactions = paginatedTransactions.data else {
        error(OmniNetworkingException.couldNotGetPaginatedTransactions)
        return
      }
      completion(transactions)
    }), error: error)
  }

}
