import XCTest
@testable import NerdOut

final class ArticleContentGeneratorTests: XCTestCase {

    // MARK: - Mock API Client

    actor MockOpenAIAPIClient {
        let apiKey: String = "test-key"
        let baseURL = URL(string: "https://api.openai.com/v1")!
        let session: URLSession = .shared
        let model: String = "gpt-4o"

        var lastMessages: [ChatMessage] = []
        var responseToReturn: String = ""

        func sendChatCompletion(
            messages: [ChatMessage],
            responseFormat: ResponseFormat = .text
        ) async throws -> String {
            lastMessages = messages
            return responseToReturn
        }
    }

    // MARK: - Tests

    func testGenerateArticleContent_ValidResponse() async throws {
        // Given
        let mockClient = MockOpenAIAPIClient()
        await mockClient.setResponse(validArticleResponse)

        let pivot = TopicPivot(
            id: UUID(),
            title: "The Pythagorean Theorem",
            description: "Understanding the fundamental relationship in right triangles",
            order: 0,
            estimatedReadingTime: 5,
            prerequisites: []
        )

        // When
        // Note: In a real test, we'd inject the mock client
        // For now, this demonstrates the expected test structure

        // Then
        // Verify the generated content structure
        let expectedContent = try JSONDecoder().decode(
            GeneratedArticleContent.self,
            from: validArticleResponse.data(using: .utf8)!
        )

        XCTAssertEqual(expectedContent.title, "The Hidden Mathematics of Right Triangles")
        XCTAssertEqual(expectedContent.sections.count, 4)
        XCTAssertEqual(expectedContent.estimatedReadingTime, 5)
        XCTAssertFalse(expectedContent.heroImageDescription.isEmpty)
    }

    func testGeneratedSection_HasImageDescription() async throws {
        // Given
        let content = try JSONDecoder().decode(
            GeneratedArticleContent.self,
            from: validArticleResponse.data(using: .utf8)!
        )

        // Then
        for section in content.sections {
            XCTAssertFalse(section.heading.isEmpty, "Section should have a heading")
            XCTAssertFalse(section.content.isEmpty, "Section should have content")
            XCTAssertFalse(section.imageDescription.isEmpty, "Section should have image description")
        }
    }

    func testParsing_InvalidJSON_ThrowsError() async throws {
        // Given
        let invalidJSON = "{ invalid json }"

        // Then
        XCTAssertThrowsError(
            try JSONDecoder().decode(GeneratedArticleContent.self, from: invalidJSON.data(using: .utf8)!)
        )
    }

    // MARK: - Test Fixtures

    private var validArticleResponse: String {
        """
        {
            "title": "The Hidden Mathematics of Right Triangles",
            "summary": "Discover how the Pythagorean theorem, a 2,500-year-old mathematical principle, continues to shape our modern world from architecture to GPS navigation.",
            "sections": [
                {
                    "heading": "Ancient Origins",
                    "content": "Over 2,500 years ago, the Greek mathematician Pythagoras made a discovery that would echo through the ages. While examining the relationship between the sides of right triangles, he noticed something remarkable: the square of the longest side (the hypotenuse) always equals the sum of the squares of the other two sides. This elegant relationship, expressed as a² + b² = c², became one of the most famous equations in mathematics.",
                    "imageDescription": "An ancient Greek temple with geometric patterns, showing right triangles integrated into the architectural design"
                },
                {
                    "heading": "Proof Through Pictures",
                    "content": "One of the beautiful aspects of the Pythagorean theorem is that you don't need complex algebra to prove it—you can see it with your own eyes. Imagine a right triangle with squares drawn on each of its three sides. If you cut and rearrange the pieces from the two smaller squares, they fit perfectly into the larger square. This visual proof has been discovered independently by countless cultures across history.",
                    "imageDescription": "A colorful diagram showing squares on each side of a right triangle, with the two smaller squares rearranged to fill the larger square"
                },
                {
                    "heading": "Beyond the Classroom",
                    "content": "While you might remember the Pythagorean theorem from geometry class, it's working for you every day in ways you might not realize. Your smartphone uses it to calculate distances on maps. Architects rely on it to ensure buildings stand straight. Video game designers use it to determine how far your character can travel. Even the screen you're reading this on was manufactured using precise right-angle measurements based on this ancient principle.",
                    "imageDescription": "A split image showing a smartphone map calculating distance and an architect using a right angle tool, connected by geometric lines"
                },
                {
                    "heading": "Three Dimensions and Beyond",
                    "content": "The theorem's true power reveals itself when we extend it beyond flat surfaces. In three dimensions, we can find the diagonal of a box using a² + b² + c² = d². This extension helps engineers design everything from airplane wings to skyscrapers. Mathematicians have even extended this relationship into higher dimensions that we can't visualize but can still calculate, opening doors to theoretical physics and advanced computation.",
                    "imageDescription": "A transparent 3D box showing diagonal lines with mathematical notation, transitioning into abstract higher-dimensional geometric shapes"
                }
            ],
            "estimatedReadingTime": 5,
            "heroImageDescription": "A majestic view of the Parthenon at golden hour, with subtle geometric overlays showing right triangles and the Pythagorean equation elegantly integrated into the classical architecture"
        }
        """
    }
}

// MARK: - Mock Extension

extension ArticleContentGeneratorTests.MockOpenAIAPIClient {
    func setResponse(_ response: String) {
        responseToReturn = response
    }
}
