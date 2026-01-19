import Foundation

/// Generates hero images and embedded images for NerdOut articles
/// using OpenAI's GPT Image API following 2026 guidelines
actor ArticleImageGenerator {

    private let apiClient: OpenAIAPIClient

    /// Maximum prompt length for GPT Image models
    private let maxPromptLength = 32000

    init(apiClient: OpenAIAPIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Hero Image Generation

    /// Generates a hero image for an article
    /// - Parameters:
    ///   - articleTitle: The title of the article
    ///   - articleSummary: Brief summary of the article content
    ///   - category: The topic category for style hints
    /// - Returns: An ArticleImage configured as a hero image
    func generateHeroImage(
        articleTitle: String,
        articleSummary: String,
        category: TopicCategory
    ) async throws -> ArticleImage {
        let prompt = buildHeroImagePrompt(
            title: articleTitle,
            summary: articleSummary,
            category: category
        )

        let imageData = try await apiClient.generateImageData(
            prompt: prompt,
            size: .landscape,  // 1536x1024 - ideal for hero images
            quality: .high
        )

        let altText = "Hero image for article: \(articleTitle)"

        return ArticleImage(
            imageType: .hero,
            imageData: imageData,
            generationPrompt: prompt,
            format: .png,
            size: .landscape,
            position: nil,
            altText: altText
        )
    }

    // MARK: - Embedded Image Generation

    /// Generates an embedded image for a specific section of an article
    /// - Parameters:
    ///   - sectionTitle: Title or topic of the section
    ///   - sectionContent: The text content of the section
    ///   - position: Position index in the article
    ///   - category: The topic category for style hints
    /// - Returns: An ArticleImage configured as an embedded image
    func generateEmbeddedImage(
        sectionTitle: String,
        sectionContent: String,
        position: Int,
        category: TopicCategory
    ) async throws -> ArticleImage {
        let prompt = buildEmbeddedImagePrompt(
            sectionTitle: sectionTitle,
            sectionContent: sectionContent,
            category: category
        )

        let imageData = try await apiClient.generateImageData(
            prompt: prompt,
            size: .square1024,  // 1024x1024 - ideal for embedded images
            quality: .medium
        )

        let altText = "Illustration for: \(sectionTitle)"

        return ArticleImage(
            imageType: .embedded,
            imageData: imageData,
            generationPrompt: prompt,
            format: .png,
            size: .square1024,
            position: position,
            altText: altText
        )
    }

    // MARK: - Full Article Image Set

    /// Generates a complete set of images for an article
    /// - Parameters:
    ///   - articleTitle: The title of the article
    ///   - articleSummary: Brief summary of the article
    ///   - sections: Array of section titles and content for embedded images
    ///   - category: The topic category
    ///   - includeHero: Whether to generate a hero image
    ///   - embeddedImageCount: Number of embedded images to generate (0 to skip)
    /// - Returns: An ArticleImageSet with hero and embedded images
    func generateArticleImages(
        articleTitle: String,
        articleSummary: String,
        sections: [(title: String, content: String)],
        category: TopicCategory,
        includeHero: Bool = true,
        embeddedImageCount: Int = 2
    ) async throws -> ArticleImageSet {

        // Generate hero image if requested
        var heroImage: ArticleImage?
        if includeHero {
            heroImage = try await generateHeroImage(
                articleTitle: articleTitle,
                articleSummary: articleSummary,
                category: category
            )
        }

        // Generate embedded images for selected sections
        var embeddedImages: [ArticleImage] = []
        let sectionsToIllustrate = Array(sections.prefix(embeddedImageCount))

        for (index, section) in sectionsToIllustrate.enumerated() {
            let image = try await generateEmbeddedImage(
                sectionTitle: section.title,
                sectionContent: section.content,
                position: index,
                category: category
            )
            embeddedImages.append(image)
        }

        return ArticleImageSet(
            heroImage: heroImage,
            embeddedImages: embeddedImages
        )
    }

    // MARK: - Prompt Building

    private func buildHeroImagePrompt(
        title: String,
        summary: String,
        category: TopicCategory
    ) -> String {
        let styleGuide = categoryStyleGuide(for: category)

        return """
        Create a visually striking hero image for an educational article.

        Article Title: \(title)
        Summary: \(summary)

        Style Guidelines:
        \(styleGuide)

        Requirements:
        - Professional, editorial quality suitable for a learning app
        - Landscape orientation (16:10 aspect ratio)
        - Clean composition with clear focal point
        - Evocative imagery that captures the article's essence
        - No text or watermarks in the image
        - Modern, sophisticated aesthetic
        - High visual impact for app header display
        """
    }

    private func buildEmbeddedImagePrompt(
        sectionTitle: String,
        sectionContent: String,
        category: TopicCategory
    ) -> String {
        let styleGuide = categoryStyleGuide(for: category)
        let contentSnippet = String(sectionContent.prefix(500))

        return """
        Create an informative illustration for an article section.

        Section Topic: \(sectionTitle)
        Content Context: \(contentSnippet)

        Style Guidelines:
        \(styleGuide)

        Requirements:
        - Educational and informative visual
        - Square format suitable for inline display
        - Clear, focused composition
        - Supports understanding of the content
        - No text or labels in the image
        - Clean, professional aesthetic
        - Complements article reading experience
        """
    }

    private func categoryStyleGuide(for category: TopicCategory) -> String {
        switch category {
        case .sports:
            return """
            - Dynamic, energetic imagery
            - Action-oriented compositions
            - Bold, vibrant colors
            - Athletic and competitive themes
            """
        case .music:
            return """
            - Rhythmic, flowing compositions
            - Warm, expressive tones
            - Musical instruments or performance imagery
            - Emotional and artistic atmosphere
            """
        case .science:
            return """
            - Clean, precise imagery
            - Scientific visualization aesthetic
            - Cool, analytical color palette
            - Data-inspired or natural phenomena themes
            """
        case .history:
            return """
            - Rich, textured imagery
            - Period-appropriate aesthetic cues
            - Warm, aged tones
            - Documentary or archival feel
            """
        case .literature:
            return """
            - Evocative, narrative imagery
            - Soft, literary lighting
            - Bookish or storytelling themes
            - Contemplative atmosphere
            """
        case .technology:
            return """
            - Modern, sleek imagery
            - Digital and innovative themes
            - Cool blues and tech-inspired colors
            - Futuristic but approachable aesthetic
            """
        case .arts:
            return """
            - Creative, expressive imagery
            - Artistic techniques and mediums
            - Rich, varied color palette
            - Gallery or studio aesthetic
            """
        case .philosophy:
            return """
            - Abstract, contemplative imagery
            - Symbolic visual metaphors
            - Muted, thoughtful tones
            - Ethereal or conceptual atmosphere
            """
        case .other:
            return """
            - Versatile, engaging imagery
            - Clear visual communication
            - Balanced color palette
            - Professional educational aesthetic
            """
        }
    }
}

// MARK: - Batch Image Generation

extension ArticleImageGenerator {

    /// Generates images for multiple articles concurrently
    /// - Parameters:
    ///   - articles: Array of article metadata for image generation
    ///   - includeHero: Whether to include hero images
    ///   - embeddedCount: Number of embedded images per article
    /// - Returns: Dictionary mapping article IDs to their image sets
    func generateImagesForArticles(
        _ articles: [(id: UUID, title: String, summary: String, sections: [(String, String)], category: TopicCategory)],
        includeHero: Bool = true,
        embeddedCount: Int = 1
    ) async throws -> [UUID: ArticleImageSet] {
        var results: [UUID: ArticleImageSet] = [:]

        for article in articles {
            let imageSet = try await generateArticleImages(
                articleTitle: article.title,
                articleSummary: article.summary,
                sections: article.sections.map { ($0.0, $0.1) },
                category: article.category,
                includeHero: includeHero,
                embeddedImageCount: embeddedCount
            )
            results[article.id] = imageSet
        }

        return results
    }
}
