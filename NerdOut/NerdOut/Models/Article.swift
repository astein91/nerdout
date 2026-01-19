import Foundation

struct Article: Codable, Identifiable {
    let id: UUID
    let topicId: UUID
    let title: String
    let content: String
    let heroImageURL: URL?
    let embeddedImages: [EmbeddedImage]
    let wordCount: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case topicId = "topic_id"
        case title
        case content
        case heroImageURL = "hero_image_url"
        case embeddedImages = "embedded_images"
        case wordCount = "word_count"
        case createdAt = "created_at"
    }
}

struct EmbeddedImage: Codable, Identifiable {
    let id: UUID
    let url: URL
    let caption: String?
    let position: Int

    var altText: String {
        caption ?? "Image"
    }
}
