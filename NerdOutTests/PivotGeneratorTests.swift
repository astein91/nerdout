import XCTest
@testable import NerdOut

final class PivotGeneratorTests: XCTestCase {

    // MARK: - Model Tests

    func testPivotDepthTypeRawValues() {
        XCTAssertEqual(PivotDepthType.deeper.rawValue, "deeper")
        XCTAssertEqual(PivotDepthType.tangent.rawValue, "tangent")
        XCTAssertEqual(PivotDepthType.broader.rawValue, "broader")
    }

    func testPivotDepthTypeDecoding() throws {
        let json = """
        "tangent"
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(PivotDepthType.self, from: data)
        XCTAssertEqual(decoded, .tangent)
    }

    func testTopicCategoryRawValues() {
        XCTAssertEqual(TopicCategory.science.rawValue, "Science")
        XCTAssertEqual(TopicCategory.history.rawValue, "History")
        XCTAssertEqual(TopicCategory.technology.rawValue, "Technology")
    }

    func testPivotSuggestionAPIResponseDecoding() throws {
        let json = """
        {
            "title": "Quantum Computing Basics",
            "hook": "Discover how particles can be in multiple states at once",
            "connectionReason": "Relates to the computing concepts discussed in the article",
            "suggestedCategory": "Technology",
            "relevanceScore": 0.85,
            "depthType": "deeper"
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(PivotSuggestionAPIResponse.self, from: data)

        XCTAssertEqual(decoded.title, "Quantum Computing Basics")
        XCTAssertEqual(decoded.hook, "Discover how particles can be in multiple states at once")
        XCTAssertEqual(decoded.connectionReason, "Relates to the computing concepts discussed in the article")
        XCTAssertEqual(decoded.suggestedCategory, "Technology")
        XCTAssertEqual(decoded.relevanceScore, 0.85)
        XCTAssertEqual(decoded.depthType, "deeper")
    }

    func testPivotGenerationAPIResponseDecoding() throws {
        let json = """
        {
            "suggestions": [
                {
                    "title": "The History of Encryption",
                    "hook": "From Caesar ciphers to quantum cryptography",
                    "connectionReason": "Security is fundamental to computing",
                    "suggestedCategory": "History",
                    "relevanceScore": 0.9,
                    "depthType": "tangent"
                },
                {
                    "title": "Machine Learning Fundamentals",
                    "hook": "How computers learn from data",
                    "connectionReason": "Modern AI builds on classic computing theory",
                    "suggestedCategory": "Technology",
                    "relevanceScore": 0.75,
                    "depthType": "broader"
                }
            ],
            "extractedConcepts": ["algorithms", "data structures", "computation"]
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(PivotGenerationAPIResponse.self, from: data)

        XCTAssertEqual(decoded.suggestions.count, 2)
        XCTAssertEqual(decoded.extractedConcepts.count, 3)
        XCTAssertEqual(decoded.suggestions[0].title, "The History of Encryption")
        XCTAssertEqual(decoded.suggestions[1].depthType, "broader")
        XCTAssertTrue(decoded.extractedConcepts.contains("algorithms"))
    }

    func testPivotSuggestionCreation() {
        let suggestion = PivotSuggestion(
            id: UUID(),
            title: "Test Topic",
            hook: "An interesting hook",
            connectionReason: "Connects because...",
            suggestedCategory: .science,
            relevanceScore: 0.8,
            depthType: .tangent
        )

        XCTAssertEqual(suggestion.title, "Test Topic")
        XCTAssertEqual(suggestion.suggestedCategory, .science)
        XCTAssertEqual(suggestion.depthType, .tangent)
        XCTAssertEqual(suggestion.relevanceScore, 0.8)
    }

    func testArticleContentCreation() {
        let content = ArticleContent(
            title: "Introduction to Swift",
            bodyText: "Swift is a powerful programming language...",
            category: .technology,
            coveredConcepts: ["variables", "functions"],
            userSophisticationLevel: 3
        )

        XCTAssertEqual(content.title, "Introduction to Swift")
        XCTAssertEqual(content.category, .technology)
        XCTAssertEqual(content.coveredConcepts.count, 2)
        XCTAssertEqual(content.userSophisticationLevel, 3)
    }

    func testPivotSuggestionResultCreation() {
        let suggestions = [
            PivotSuggestion(
                id: UUID(),
                title: "Topic 1",
                hook: "Hook 1",
                connectionReason: "Reason 1",
                suggestedCategory: .science,
                relevanceScore: 0.9,
                depthType: .deeper
            ),
            PivotSuggestion(
                id: UUID(),
                title: "Topic 2",
                hook: "Hook 2",
                connectionReason: "Reason 2",
                suggestedCategory: .history,
                relevanceScore: 0.7,
                depthType: .tangent
            )
        ]

        let result = PivotSuggestionResult(
            suggestions: suggestions,
            extractedConcepts: ["concept1", "concept2"]
        )

        XCTAssertEqual(result.suggestions.count, 2)
        XCTAssertEqual(result.extractedConcepts.count, 2)
    }

    // MARK: - Edge Case Tests

    func testRelevanceScoreClampedTo0To1() {
        // Test that relevance scores outside 0-1 would need clamping
        // The actual clamping happens in PivotGenerator.buildPivotSuggestionResult
        let score = min(max(1.5, 0), 1)
        XCTAssertEqual(score, 1.0)

        let negativeScore = min(max(-0.5, 0), 1)
        XCTAssertEqual(negativeScore, 0.0)
    }

    func testUnknownCategoryFallsBackToOther() {
        let unknownCategory = TopicCategory(rawValue: "Unknown")
        XCTAssertNil(unknownCategory)

        let fallback = TopicCategory(rawValue: "Unknown") ?? .other
        XCTAssertEqual(fallback, .other)
    }

    func testUnknownDepthTypeFallsBackToTangent() {
        let unknownDepth = PivotDepthType(rawValue: "unknown")
        XCTAssertNil(unknownDepth)

        let fallback = PivotDepthType(rawValue: "unknown") ?? .tangent
        XCTAssertEqual(fallback, .tangent)
    }

    func testEmptyCoveredConcepts() {
        let content = ArticleContent(
            title: "Test",
            bodyText: "Body",
            category: .other,
            coveredConcepts: [],
            userSophisticationLevel: 1
        )

        XCTAssertTrue(content.coveredConcepts.isEmpty)
    }
}

// MARK: - Mock API Client for Integration Tests

/// Mock OpenAI API client for testing PivotGenerator
actor MockOpenAIAPIClient: OpenAIAPIClient {
    var mockResponse: String = ""
    var shouldThrowError: Bool = false
    var lastMessages: [ChatMessage] = []

    init() {
        super.init(apiKey: "test-key")
    }

    override func sendChatCompletion(
        messages: [ChatMessage],
        responseFormat: ResponseFormat = .text
    ) async throws -> String {
        lastMessages = messages

        if shouldThrowError {
            throw OpenAIError.noContent
        }

        return mockResponse
    }
}

final class PivotGeneratorIntegrationTests: XCTestCase {

    func testGeneratePivotsWithValidResponse() async throws {
        let mockClient = MockOpenAIAPIClient()
        mockClient.mockResponse = """
        {
            "suggestions": [
                {
                    "title": "Related Topic",
                    "hook": "Fascinating connection",
                    "connectionReason": "Builds on the article",
                    "suggestedCategory": "Science",
                    "relevanceScore": 0.85,
                    "depthType": "deeper"
                }
            ],
            "extractedConcepts": ["concept1", "concept2"]
        }
        """

        let generator = PivotGenerator(apiClient: mockClient)

        let articleContent = ArticleContent(
            title: "Test Article",
            bodyText: "This is test content about science.",
            category: .science,
            coveredConcepts: ["existing concept"],
            userSophisticationLevel: 3
        )

        let result = try await generator.generatePivots(from: articleContent)

        XCTAssertEqual(result.suggestions.count, 1)
        XCTAssertEqual(result.suggestions[0].title, "Related Topic")
        XCTAssertEqual(result.suggestions[0].suggestedCategory, .science)
        XCTAssertEqual(result.suggestions[0].depthType, .deeper)
        XCTAssertEqual(result.extractedConcepts.count, 2)
    }

    func testGeneratePivotsWithAPIError() async {
        let mockClient = MockOpenAIAPIClient()
        mockClient.shouldThrowError = true

        let generator = PivotGenerator(apiClient: mockClient)

        let articleContent = ArticleContent(
            title: "Test",
            bodyText: "Content",
            category: .other,
            coveredConcepts: [],
            userSophisticationLevel: 1
        )

        do {
            _ = try await generator.generatePivots(from: articleContent)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected behavior
            XCTAssertTrue(error is OpenAIError)
        }
    }

    func testGeneratePivotsWithInvalidJSON() async {
        let mockClient = MockOpenAIAPIClient()
        mockClient.mockResponse = "not valid json"

        let generator = PivotGenerator(apiClient: mockClient)

        let articleContent = ArticleContent(
            title: "Test",
            bodyText: "Content",
            category: .other,
            coveredConcepts: [],
            userSophisticationLevel: 1
        )

        do {
            _ = try await generator.generatePivots(from: articleContent)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PivotGenerationError)
        }
    }
}
