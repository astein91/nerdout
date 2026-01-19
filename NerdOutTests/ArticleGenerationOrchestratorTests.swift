import XCTest
@testable import NerdOut

final class ArticleGenerationOrchestratorTests: XCTestCase {

    // MARK: - Image Configuration Tests

    func testImageConfiguration_Standard() {
        let config = ArticleGenerationOrchestrator.ImageConfiguration.standard

        XCTAssertTrue(config.includeHeroImage)
        XCTAssertEqual(config.maxEmbeddedImages, 2)
        XCTAssertEqual(config.quality, .medium)
    }

    func testImageConfiguration_HeroOnly() {
        let config = ArticleGenerationOrchestrator.ImageConfiguration.heroOnly

        XCTAssertTrue(config.includeHeroImage)
        XCTAssertEqual(config.maxEmbeddedImages, 0)
    }

    func testImageConfiguration_Rich() {
        let config = ArticleGenerationOrchestrator.ImageConfiguration.rich

        XCTAssertTrue(config.includeHeroImage)
        XCTAssertEqual(config.maxEmbeddedImages, 4)
        XCTAssertEqual(config.quality, .high)
    }

    func testImageConfiguration_Custom() {
        let config = ArticleGenerationOrchestrator.ImageConfiguration(
            includeHeroImage: false,
            maxEmbeddedImages: 3,
            quality: .low
        )

        XCTAssertFalse(config.includeHeroImage)
        XCTAssertEqual(config.maxEmbeddedImages, 3)
        XCTAssertEqual(config.quality, .low)
    }

    // MARK: - Generation Progress Tests

    func testGenerationStage_RawValues() {
        XCTAssertEqual(ArticleGenerationOrchestrator.GenerationStage.starting.rawValue, "Starting generation")
        XCTAssertEqual(ArticleGenerationOrchestrator.GenerationStage.generatingContent.rawValue, "Generating article content")
        XCTAssertEqual(ArticleGenerationOrchestrator.GenerationStage.generatingHeroImage.rawValue, "Creating hero image")
        XCTAssertEqual(ArticleGenerationOrchestrator.GenerationStage.generatingEmbeddedImages.rawValue, "Creating embedded images")
        XCTAssertEqual(ArticleGenerationOrchestrator.GenerationStage.assembling.rawValue, "Assembling article")
        XCTAssertEqual(ArticleGenerationOrchestrator.GenerationStage.complete.rawValue, "Complete")
    }

    func testGenerationProgress_Initialization() {
        let progress = ArticleGenerationOrchestrator.GenerationProgress(
            stage: .generatingContent,
            progress: 0.5,
            message: "Halfway done"
        )

        XCTAssertEqual(progress.stage, .generatingContent)
        XCTAssertEqual(progress.progress, 0.5, accuracy: 0.01)
        XCTAssertEqual(progress.message, "Halfway done")
    }

    // MARK: - GenerationProgressOrResult Tests

    func testGenerationProgressOrResult_Progress() {
        let progressUpdate = ArticleGenerationOrchestrator.GenerationProgress(
            stage: .starting,
            progress: 0.0,
            message: "Starting"
        )
        let result = GenerationProgressOrResult.progress(progressUpdate)

        if case .progress(let progress) = result {
            XCTAssertEqual(progress.stage, .starting)
        } else {
            XCTFail("Expected progress case")
        }
    }

    func testGenerationProgressOrResult_Result() {
        let article = createTestArticle()
        let result = GenerationProgressOrResult.result(article)

        if case .result(let returnedArticle) = result {
            XCTAssertEqual(returnedArticle.title, "Test Article")
        } else {
            XCTFail("Expected result case")
        }
    }

    // MARK: - Article Assembly Tests

    func testArticleBuilder_AssociatesImagesWithSections() {
        // Given
        let heroImage = createTestImage(type: .hero, position: nil)
        let embeddedImage1 = createTestImage(type: .embedded, position: 0)
        let embeddedImage2 = createTestImage(type: .embedded, position: 1)

        let imageSet = ArticleImageSet(
            heroImage: heroImage,
            embeddedImages: [embeddedImage1, embeddedImage2]
        )

        let sections = [
            ArticleSection(heading: "Section 1", content: "Content 1", order: 0),
            ArticleSection(heading: "Section 2", content: "Content 2", order: 1),
            ArticleSection(heading: "Section 3", content: "Content 3", order: 2)
        ]

        // When
        let article = ArticleBuilder.build(
            pivotId: UUID(),
            title: "Test",
            summary: "Summary",
            content: "Full content",
            sections: sections,
            category: .science,
            images: imageSet,
            estimatedReadingTime: 5
        )

        // Then
        XCTAssertNotNil(article.sections[0].embeddedImage)
        XCTAssertNotNil(article.sections[1].embeddedImage)
        XCTAssertNil(article.sections[2].embeddedImage)
    }

    func testArticleImageSet_ImageCount() {
        // Given - no images
        let emptySet = ArticleImageSet()
        XCTAssertEqual(emptySet.imageCount, 0)

        // Given - hero only
        let heroOnlySet = ArticleImageSet(
            heroImage: createTestImage(type: .hero, position: nil),
            embeddedImages: []
        )
        XCTAssertEqual(heroOnlySet.imageCount, 1)

        // Given - hero + embedded
        let fullSet = ArticleImageSet(
            heroImage: createTestImage(type: .hero, position: nil),
            embeddedImages: [
                createTestImage(type: .embedded, position: 0),
                createTestImage(type: .embedded, position: 1)
            ]
        )
        XCTAssertEqual(fullSet.imageCount, 3)
    }

    // MARK: - Helpers

    private func createTestArticle() -> Article {
        Article(
            pivotId: UUID(),
            title: "Test Article",
            summary: "A test summary",
            content: "Test content",
            sections: [],
            category: .science,
            estimatedReadingTime: 5
        )
    }

    private func createTestImage(type: ArticleImageType, position: Int?) -> ArticleImage {
        ArticleImage(
            imageType: type,
            imageData: "base64encodeddata",
            generationPrompt: "Test prompt",
            size: type == .hero ? .landscape : .square1024,
            position: position,
            altText: "Test image"
        )
    }
}
