//
//  ChipDnaUtils.swift
//  fattmerchant-ios-sdk
//
//  Created by Tulio Troncoso on 1/17/20.
//  Copyright © 2020 Fattmerchant. All rights reserved.
//

import Foundation

extension MobileReader {
  static func from(pinPad: ChipDnaDriver.SelectablePinPad) -> MobileReader {
    return MobileReader(name: pinPad.name)
  }
}

extension CCParameters {

  subscript(key: String) -> String? {
    get {
      guard
        let allKeys = allKeys() as? [String],
        allKeys.contains(key)
        else { return nil }

      return value(forKey: key)
    }

    set {
      setValue(newValue, forKey: key)
    }

  }

  convenience init(transactionRequest: TransactionRequest) {
    self.init()
    self[CCParamAmount] = transactionRequest.amount.centsString()
    self[CCParamAmountType] = CCValueAmountTypeActual
    self[CCParamCurrency] = "USD"
    self[CCParamUserReference] = generateChipDnaTransactionUserReference()
    self[CCParamPaymentMethod] = CCValueCard
    self[CCParamAutoConfirm] = CCValueTrue
    self[CCParamTransactionType] = CCValueSale
  }

}