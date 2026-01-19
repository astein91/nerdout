import Foundation

/// Represents an educational article with content, hero image, and embedded images
struct Article: Codable, Identifiable {
    let id: UUID

    /// ID of the topic this article belongs to
    let topicId: UUID

    /// Article title
    let title: String

    /// Markdown-formatted article content (500-1000 words)
    let content: String

    /// Hero image displayed at the top of the article
    let heroImage: ArticleImage?

    /// Images embedded within the article content
    let embeddedImages: [ArticleImage]

    /// Estimated word count of the content
    let wordCount: Int

    /// Estimated reading time in minutes
    let estimatedReadingTime: Int

    /// When the article was generated
    let createdAt: Date

    init(
        id: UUID = UUID(),
        topicId: UUID,
        title: String,
        content: String,
        heroImage: ArticleImage? = nil,
        embeddedImages: [ArticleImage] = [],
        wordCount: Int? = nil,
        estimatedReadingTime: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.topicId = topicId
        self.title = title
        self.content = content
        self.heroImage = heroImage
        self.embeddedImages = embeddedImages

        // Calculate word count if not provided
        let calculatedWordCount = wordCount ?? content.split(separator: " ").count
        self.wordCount = calculatedWordCount

        // Estimate reading time at ~200 words per minute
        self.estimatedReadingTime = estimatedReadingTime ?? max(1, calculatedWordCount / 200)
        self.createdAt = createdAt
    }
}

/// Represents an image associated with an article
struct ArticleImage: Codable, Identifiable {
    let id: UUID

    /// The image type (hero or embedded)
    let imageType: ArticleImageType

    /// URL to the image (for remote images)
    let imageURL: URL?

    /// Base64-encoded image data (for locally generated images)
    let imageData: String?

    /// The prompt used to generate this image
    let generationPrompt: String?

    /// Position in article content (for embedded images, 0-indexed paragraph)
    let position: Int?

    /// Alt text for accessibility
    let altText: String

    /// Caption displayed below the image
    let caption: String?

    init(
        id: UUID = UUID(),
        imageType: ArticleImageType,
        imageURL: URL? = nil,
        imageData: String? = nil,
        generationPrompt: String? = nil,
        position: Int? = nil,
        altText: String,
        caption: String? = nil
    ) {
        self.id = id
        self.imageType = imageType
        self.imageURL = imageURL
        self.imageData = imageData
        self.generationPrompt = generationPrompt
        self.position = position
        self.altText = altText
        self.caption = caption
    }
}

/// Type of image in an article
enum ArticleImageType: String, Codable {
    /// Hero image displayed at the top of the article
    case hero

    /// Embedded image within the article content
    case embedded
}
