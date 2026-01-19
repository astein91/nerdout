import Foundation

/// Mock OpenAI client for testing and development
final class MockOpenAIClient: OpenAIClient, @unchecked Sendable {
    var mockResponse: String?
    var shouldFail: Bool = false
    var failureError: Error = PivotGeneratorError.apiError("Mock failure")

    func sendChatCompletion(messages: [ChatMessage], responseFormat: ResponseFormat) async throws -> String {
        if shouldFail {
            throw failureError
        }

        if let mockResponse = mockResponse {
            return mockResponse
        }

        // Return realistic sample pivots for testing
        return samplePivotResponse
    }

    private var samplePivotResponse: String {
        """
        {
          "pivots": [
            {
              "title": "The Science of Musical Goosebumps",
              "description": "Why certain chord progressions trigger physical chills connects music theory to neuroscience and evolutionary psychology.",
              "category": "Science",
              "relevanceScore": 0.95,
              "sourceContext": "emotional response to music"
            },
            {
              "title": "Vinyl's Unexpected Comeback",
              "description": "How a 'dead' format became the fastest-growing segment of the music industry reveals fascinating insights about nostalgia and tactile experience.",
              "category": "Culture",
              "relevanceScore": 0.88,
              "sourceContext": "analog recording technology"
            },
            {
              "title": "The Mathematics of Rhythm",
              "description": "Ancient Greek discoveries about ratios and harmony laid the foundation for both modern music and Western science.",
              "category": "History",
              "relevanceScore": 0.82,
              "sourceContext": "musical patterns"
            },
            {
              "title": "Synesthesia and Sonic Colors",
              "description": "For some people, sounds literally have colors - and studying this reveals how our brains construct reality.",
              "category": "Science",
              "relevanceScore": 0.79,
              "sourceContext": "perception of sound"
            },
            {
              "title": "The Lost Music of Ancient Civilizations",
              "description": "Archaeologists can now recreate songs from 3,400-year-old clay tablets, revealing surprisingly sophisticated ancient compositions.",
              "category": "History",
              "relevanceScore": 0.75,
              "sourceContext": "musical heritage"
            }
          ]
        }
        """
    }
}

// MARK: - Test Helpers

extension MockOpenAIClient {
    /// Create a client that returns specific pivots
    static func returning(pivots: [TestPivot]) -> MockOpenAIClient {
        let client = MockOpenAIClient()
        let jsonPivots = pivots.map { pivot in
            """
            {
              "title": "\(pivot.title)",
              "description": "\(pivot.description)",
              "category": "\(pivot.category)",
              "relevanceScore": \(pivot.relevanceScore),
              "sourceContext": "\(pivot.sourceContext)"
            }
            """
        }.joined(separator: ",\n")

        client.mockResponse = """
        {
          "pivots": [\(jsonPivots)]
        }
        """
        return client
    }
}

struct TestPivot {
    let title: String
    let description: String
    let category: String
    let relevanceScore: Double
    let sourceContext: String
}
