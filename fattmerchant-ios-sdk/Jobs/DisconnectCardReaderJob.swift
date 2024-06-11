import Foundation

class DisconnectCardReaderJob : Job {
  typealias Output = Bool
  
  func start() async throws -> Bool {
    guard let card = Services.resolve(CardReaderService.self) else {
      throw StaxInitializeException.missingInitializationDetails
    }

    return try await card.disconnectFromReader()
  }
}
