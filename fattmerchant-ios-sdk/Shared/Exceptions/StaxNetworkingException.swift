import Foundation

enum StaxNetworkingException: StaxException {
    case couldNotGetMerchantDetails
    case couldNotGetPaginatedTransactions

    static var mess: String = "Stax Networking Exception"

    var detail: String? {
        switch self {
        case .couldNotGetMerchantDetails:
            return "Could not get merchant details from Stax"
        case .couldNotGetPaginatedTransactions:
            return "Could not get paginated transactions"
        }
    }
}
