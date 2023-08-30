import Foundation

public struct PreviewCard: Codable {
    public let type: CardType
    public let url: URL
}


public enum CardType: String, Codable {
    case link
    case video
    case photo
}
