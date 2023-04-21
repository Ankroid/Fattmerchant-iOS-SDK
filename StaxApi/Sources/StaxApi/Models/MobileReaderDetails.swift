import Foundation

public class MobileReaderDetails: Codable {
  /// Holds details for NMI settings set in the mobile reader tab
  public var nmi: NMIDetails?
}

/// Details for NMI (ChipDNA) settings set in the mobile reader tab
public struct NMIDetails: Codable {
  /// NMI (ChipDNA) security key
  public var securityKey: String
}
