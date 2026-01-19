import Foundation

// MARK: - Article Model

/// Represents a complete article in the NerdOut learning system
struct Article: Codable, Identifiable {
    let id: UUID

    /// The topic pivot this article belongs to
    let pivotId: UUID

    /// Article title
    let title: String

    /// Brief summary of the article
    let summary: String

    /// Full article content (500-1000 words)
    let content: String

    /// Structured sections of the article
    let sections: [ArticleSection]

    /// Category for styling and organization
    let category: TopicCategory

    /// Images associated with this article
    let images: ArticleImageSet

    /// Estimated reading time in minutes
    let estimatedReadingTime: Int

    /// When the article was generated
    let createdAt: Date

    init(
        id: UUID = UUID(),
        pivotId: UUID,
        title: String,
        summary: String,
        content: String,
        sections: [ArticleSection],
        category: TopicCategory,
        images: ArticleImageSet = ArticleImageSet(),
        estimatedReadingTime: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.pivotId = pivotId
        self.title = title
        self.summary = summary
        self.content = content
        self.sections = sections
        self.category = category
        self.images = images
        self.estimatedReadingTime = estimatedReadingTime
        self.createdAt = createdAt
    }
}

// MARK: - Article Sections

/// A section within an article
struct ArticleSection: Codable, Identifiable {
    let id: UUID

    /// Section heading
    let heading: String

    /// Section content
    let content: String

    /// Order in the article
    let order: Int

    /// Optional embedded image for this section
    var embeddedImage: ArticleImage?

    init(
        id: UUID = UUID(),
        heading: String,
        content: String,
        order: Int,
        embeddedImage: ArticleImage? = nil
    ) {
        self.id = id
        self.heading = heading
        self.content = content
        self.order = order
        self.embeddedImage = embeddedImage
    }
}

// MARK: - Article with Pending Images

/// Represents an article that needs images generated
struct ArticleImageRequest {
    let article: Article
    let generateHero: Bool
    let embeddedImagePositions: [Int]

    init(
        article: Article,
        generateHero: Bool = true,
        embeddedImagePositions: [Int] = []
    ) {
        self.article = article
        self.generateHero = generateHero
        self.embeddedImagePositions = embeddedImagePositions
    }

    /// Sections that should have embedded images
    var sectionsForImages: [(title: String, content: String)] {
        embeddedImagePositions.compactMap { position in
            guard position < article.sections.count else { return nil }
            let section = article.sections[position]
            return (section.heading, section.content)
        }
    }
}

// MARK: - Article Builder

/// Builds an article with generated images
struct ArticleBuilder {

    /// Creates an article with an image set
    static func build(
        pivotId: UUID,
        title: String,
        summary: String,
        content: String,
        sections: [ArticleSection],
        category: TopicCategory,
        images: ArticleImageSet,
        estimatedReadingTime: Int
    ) -> Article {
        // Associate embedded images with their sections
        var updatedSections = sections
        for image in images.embeddedImages {
            if let position = image.position, position < updatedSections.count {
                updatedSections[position].embeddedImage = image
            }
        }

        return Article(
            pivotId: pivotId,
            title: title,
            summary: summary,
            content: content,
            sections: updatedSections,
            category: category,
            images: images,
            estimatedReadingTime: estimatedReadingTime
        )
    }
}

// MARK: - Reading Progress

/// Tracks user's reading progress for an article
struct ArticleProgress: Codable {
    let articleId: UUID
    let userId: UUID

    /// Whether the article has been completed
    var isCompleted: Bool

    /// Percentage of article read (0.0 - 1.0)
    var progressPercent: Double

    /// Scroll position to resume reading
    var lastScrollPosition: Double

    /// When the user last accessed this article
    var lastAccessedAt: Date

    /// Time spent reading in seconds
    var timeSpentSeconds: Int

    init(
        articleId: UUID,
        userId: UUID,
        isCompleted: Bool = false,
        progressPercent: Double = 0.0,
        lastScrollPosition: Double = 0.0,
        lastAccessedAt: Date = Date(),
        timeSpentSeconds: Int = 0
    ) {
        self.articleId = articleId
        self.userId = userId
        self.isCompleted = isCompleted
        self.progressPercent = progressPercent
        self.lastScrollPosition = lastScrollPosition
        self.lastAccessedAt = lastAccessedAt
        self.timeSpentSeconds = timeSpentSeconds
    }
}
