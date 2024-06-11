//
//  GetConnectedMobileReader.swift
//  fattmerchant-ios-sdk
//
//  Created by Tulio Troncoso on 4/20/20.
//  Copyright © 2020 Fattmerchant. All rights reserved.
//

import Foundation

class GetConnectedMobileReader {
  var mobileReaderDriverRepository: MobileReaderDriverRepository

  init(mobileReaderDriverRepository: MobileReaderDriverRepository) {
    self.mobileReaderDriverRepository = mobileReaderDriverRepository
  }

  func start(completion: @escaping (MobileReader?) -> Void, failure: @escaping (StaxException) -> Void) {
    mobileReaderDriverRepository.getInitializedDrivers { drivers in
      guard let driver = drivers.first else {
        failure(GetConnectedMobileReaderException.noReaderAvailable)
        return
      }

      driver.getConnectedReader(completion: completion, error: failure)
    }
  }
}
