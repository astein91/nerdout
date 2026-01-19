import Foundation

/// Orchestrates the complete article generation process including
/// content generation and image integration following OpenAI ChatGPT 2026 guidelines
actor ArticleGenerationOrchestrator {

    private let contentGenerator: ArticleContentGenerator
    private let imageGenerator: ArticleImageGenerator

    /// Configuration for image generation
    struct ImageConfiguration {
        /// Whether to generate a hero image
        let includeHeroImage: Bool

        /// Maximum number of embedded images to generate
        let maxEmbeddedImages: Int

        /// Image quality level
        let quality: ImageQuality

        init(
            includeHeroImage: Bool = true,
            maxEmbeddedImages: Int = 2,
            quality: ImageQuality = .medium
        ) {
            self.includeHeroImage = includeHeroImage
            self.maxEmbeddedImages = maxEmbeddedImages
            self.quality = quality
        }

        /// Default configuration with hero and 2 embedded images
        static let standard = ImageConfiguration()

        /// Minimal configuration with hero only
        static let heroOnly = ImageConfiguration(maxEmbeddedImages: 0)

        /// Rich configuration with hero and up to 4 embedded images
        static let rich = ImageConfiguration(maxEmbeddedImages: 4, quality: .high)
    }

    init(apiClient: OpenAIAPIClient) {
        self.contentGenerator = ArticleContentGenerator(apiClient: apiClient)
        self.imageGenerator = ArticleImageGenerator(apiClient: apiClient)
    }

    /// Generates a complete article with content and images
    /// - Parameters:
    ///   - pivot: The topic pivot to generate an article for
    ///   - category: The topic category
    ///   - sophisticationLevel: User's knowledge level (1-5)
    ///   - imageConfig: Configuration for image generation
    /// - Returns: A complete Article with hero image and embedded images
    func generateArticle(
        pivot: TopicPivot,
        category: TopicCategory,
        sophisticationLevel: Int,
        imageConfig: ImageConfiguration = .standard
    ) async throws -> Article {
        // Step 1: Generate article content
        let content = try await contentGenerator.generateArticleContent(
            pivot: pivot,
            category: category,
            sophisticationLevel: sophisticationLevel
        )

        // Step 2: Generate images using the content descriptions
        let imageSet = try await generateImages(
            for: content,
            category: category,
            config: imageConfig
        )

        // Step 3: Build sections from generated content
        let sections = buildSections(from: content.sections)

        // Step 4: Assemble the complete article
        let fullContent = sections.map { $0.content }.joined(separator: "\n\n")

        return ArticleBuilder.build(
            pivotId: pivot.id,
            title: content.title,
            summary: content.summary,
            content: fullContent,
            sections: sections,
            category: category,
            images: imageSet,
            estimatedReadingTime: content.estimatedReadingTime
        )
    }

    /// Generates multiple articles in batch
    /// - Parameters:
    ///   - pivots: Array of topic pivots to generate articles for
    ///   - category: The topic category
    ///   - sophisticationLevel: User's knowledge level
    ///   - imageConfig: Configuration for image generation
    /// - Returns: Array of generated articles
    func generateArticles(
        pivots: [TopicPivot],
        category: TopicCategory,
        sophisticationLevel: Int,
        imageConfig: ImageConfiguration = .standard
    ) async throws -> [Article] {
        var articles: [Article] = []

        for pivot in pivots {
            let article = try await generateArticle(
                pivot: pivot,
                category: category,
                sophisticationLevel: sophisticationLevel,
                imageConfig: imageConfig
            )
            articles.append(article)
        }

        return articles
    }

    // MARK: - Private

    private func generateImages(
        for content: GeneratedArticleContent,
        category: TopicCategory,
        config: ImageConfiguration
    ) async throws -> ArticleImageSet {
        // Build sections data for image generator
        let sectionsForImages = content.sections.prefix(config.maxEmbeddedImages).enumerated().map {
            (title: $0.element.heading, content: $0.element.imageDescription)
        }

        return try await imageGenerator.generateArticleImages(
            articleTitle: content.title,
            articleSummary: content.heroImageDescription,
            sections: Array(sectionsForImages),
            category: category,
            includeHero: config.includeHeroImage,
            embeddedImageCount: config.maxEmbeddedImages
        )
    }

    private func buildSections(from generatedSections: [GeneratedSection]) -> [ArticleSection] {
        generatedSections.enumerated().map { index, section in
            ArticleSection(
                heading: section.heading,
                content: section.content,
                order: index
            )
        }
    }
}

// MARK: - Progress Reporting

extension ArticleGenerationOrchestrator {

    /// Generation progress stages
    enum GenerationStage: String {
        case starting = "Starting generation"
        case generatingContent = "Generating article content"
        case generatingHeroImage = "Creating hero image"
        case generatingEmbeddedImages = "Creating embedded images"
        case assembling = "Assembling article"
        case complete = "Complete"
    }

    /// Progress update during article generation
    struct GenerationProgress {
        let stage: GenerationStage
        let progress: Double // 0.0 to 1.0
        let message: String
    }

    /// Generates an article with progress updates via async stream
    /// - Parameters:
    ///   - pivot: The topic pivot
    ///   - category: The topic category
    ///   - sophisticationLevel: User's knowledge level
    ///   - imageConfig: Image configuration
    /// - Returns: AsyncStream of progress updates, final element contains the completed article
    func generateArticleWithProgress(
        pivot: TopicPivot,
        category: TopicCategory,
        sophisticationLevel: Int,
        imageConfig: ImageConfiguration = .standard
    ) -> AsyncThrowingStream<GenerationProgressOrResult, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Report starting
                    continuation.yield(.progress(GenerationProgress(
                        stage: .starting,
                        progress: 0.0,
                        message: "Preparing to generate article..."
                    )))

                    // Generate content
                    continuation.yield(.progress(GenerationProgress(
                        stage: .generatingContent,
                        progress: 0.1,
                        message: "Writing article content..."
                    )))

                    let content = try await contentGenerator.generateArticleContent(
                        pivot: pivot,
                        category: category,
                        sophisticationLevel: sophisticationLevel
                    )

                    // Generate hero image
                    var heroImage: ArticleImage?
                    if imageConfig.includeHeroImage {
                        continuation.yield(.progress(GenerationProgress(
                            stage: .generatingHeroImage,
                            progress: 0.4,
                            message: "Creating hero image..."
                        )))

                        heroImage = try await imageGenerator.generateHeroImage(
                            articleTitle: content.title,
                            articleSummary: content.heroImageDescription,
                            category: category
                        )
                    }

                    // Generate embedded images
                    var embeddedImages: [ArticleImage] = []
                    if imageConfig.maxEmbeddedImages > 0 {
                        continuation.yield(.progress(GenerationProgress(
                            stage: .generatingEmbeddedImages,
                            progress: 0.6,
                            message: "Creating embedded images..."
                        )))

                        for (index, section) in content.sections.prefix(imageConfig.maxEmbeddedImages).enumerated() {
                            let image = try await imageGenerator.generateEmbeddedImage(
                                sectionTitle: section.heading,
                                sectionContent: section.imageDescription,
                                position: index,
                                category: category
                            )
                            embeddedImages.append(image)

                            // Update progress for each image
                            let imageProgress = 0.6 + (0.3 * Double(index + 1) / Double(imageConfig.maxEmbeddedImages))
                            continuation.yield(.progress(GenerationProgress(
                                stage: .generatingEmbeddedImages,
                                progress: imageProgress,
                                message: "Created \(index + 1) of \(imageConfig.maxEmbeddedImages) embedded images"
                            )))
                        }
                    }

                    // Assemble article
                    continuation.yield(.progress(GenerationProgress(
                        stage: .assembling,
                        progress: 0.95,
                        message: "Assembling final article..."
                    )))

                    let imageSet = ArticleImageSet(
                        heroImage: heroImage,
                        embeddedImages: embeddedImages
                    )

                    let sections = buildSections(from: content.sections)
                    let fullContent = sections.map { $0.content }.joined(separator: "\n\n")

                    let article = ArticleBuilder.build(
                        pivotId: pivot.id,
                        title: content.title,
                        summary: content.summary,
                        content: fullContent,
                        sections: sections,
                        category: category,
                        images: imageSet,
                        estimatedReadingTime: content.estimatedReadingTime
                    )

                    // Complete
                    continuation.yield(.progress(GenerationProgress(
                        stage: .complete,
                        progress: 1.0,
                        message: "Article generation complete!"
                    )))

                    continuation.yield(.result(article))
                    continuation.finish()

                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

/// Either a progress update or the final result
enum GenerationProgressOrResult {
    case progress(ArticleGenerationOrchestrator.GenerationProgress)
    case result(Article)
}
