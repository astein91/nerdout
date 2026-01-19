import Foundation

struct Topic: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String
    let category: Category
    let sophisticationLevel: SophisticationLevel
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case category
        case sophisticationLevel = "sophistication_level"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum SophisticationLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}
