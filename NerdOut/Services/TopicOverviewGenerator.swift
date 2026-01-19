import Foundation

/// Generates topic overviews with learning paths based on user's clarifying
/// and level-setting responses using ChatGPT
actor TopicOverviewGenerator {

    private let apiClient: OpenAIAPIClient

    init(apiClient: OpenAIAPIClient) {
        self.apiClient = apiClient
    }

    /// Generates a complete topic with learning path
    /// - Parameters:
    ///   - clarifyingResponses: User's answers to clarifying questions
    ///   - levelSettingResponses: User's familiarity assessment
    /// - Returns: A fully generated topic with learning path
    func generateTopic(
        clarifyingResponses: ClarifyingResponses,
        levelSettingResponses: LevelSettingResponses
    ) async throws -> GeneratedTopic {
        let prompt = buildPrompt(
            clarifyingResponses: clarifyingResponses,
            levelSettingResponses: levelSettingResponses
        )

        let response = try await apiClient.sendChatCompletion(
            messages: [
                ChatMessage(role: .system, content: systemPrompt),
                ChatMessage(role: .user, content: prompt)
            ],
            responseFormat: .json
        )

        let apiResponse = try parseResponse(response)
        return buildGeneratedTopic(
            from: apiResponse,
            sophisticationLevel: levelSettingResponses.sophisticationLevel
        )
    }

    // MARK: - Private

    private var systemPrompt: String {
        """
        You are an expert educational content curator for the NerdOut learning app. \
        Your role is to create personalized learning paths that match the user's \
        interests and current knowledge level.

        When generating a topic overview:
        1. Analyze what the user wants to learn from their clarifying responses
        2. Consider their sophistication level to pitch content appropriately
        3. Create a logical learning path with 5-8 article pivots
        4. Each pivot should build on previous knowledge when appropriate
        5. Assign accurate categories (Sports, Music, Science, History, Literature, \
           Technology, Arts, Philosophy, or Other)

        Always respond with valid JSON matching the specified schema.
        """
    }

    private func buildPrompt(
        clarifyingResponses: ClarifyingResponses,
        levelSettingResponses: LevelSettingResponses
    ) -> String {
        var prompt = """
        Create a learning path for the following topic request.

        ## User's Topic Description
        \(clarifyingResponses.topicDescription)

        ## Clarifying Details
        """

        for response in clarifyingResponses.responses {
            prompt += "\nQ: \(response.question)\nA: \(response.answer)\n"
        }

        prompt += """

        ## User's Knowledge Level
        Overall sophistication: \(sophisticationDescription(levelSettingResponses.sophisticationLevel))

        Familiarity with related concepts:
        """

        for response in levelSettingResponses.responses {
            prompt += "\n- \(response.question): \(response.familiarityLevel.rawValue)"
        }

        prompt += """

        ## Required JSON Response Format
        {
            "title": "Concise, engaging topic title",
            "summary": "2-3 sentence summary of what the user will learn",
            "category": "One of: Sports, Music, Science, History, Literature, Technology, Arts, Philosophy, Other",
            "pivots": [
                {
                    "title": "Article title",
                    "description": "Brief description of what this article covers",
                    "estimatedReadingTime": 5,
                    "dependsOn": [0, 1]
                }
            ],
            "keyConcepts": ["concept1", "concept2", "concept3"]
        }

        Notes:
        - Create 5-8 pivots that form a coherent learning journey
        - dependsOn is an array of pivot indices (0-based) that should be read first
        - estimatedReadingTime is in minutes (typically 3-7 minutes per article)
        - Pitch the content complexity to match sophistication level \(levelSettingResponses.sophisticationLevel)/5
        """

        return prompt
    }

    private func sophisticationDescription(_ level: Int) -> String {
        switch level {
        case 1: return "Complete beginner - no prior knowledge"
        case 2: return "Novice - basic awareness only"
        case 3: return "Intermediate - comfortable with fundamentals"
        case 4: return "Advanced - solid understanding"
        case 5: return "Expert - deep domain knowledge"
        default: return "Unknown"
        }
    }

    private func parseResponse(_ response: String) throws -> TopicGenerationAPIResponse {
        guard let data = response.data(using: .utf8) else {
            throw TopicGenerationError.invalidResponse
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(TopicGenerationAPIResponse.self, from: data)
        } catch {
            throw TopicGenerationError.parsingFailed(error)
        }
    }

    private func buildGeneratedTopic(
        from apiResponse: TopicGenerationAPIResponse,
        sophisticationLevel: Int
    ) -> GeneratedTopic {
        var pivotUUIDs: [UUID] = []
        var pivots: [TopicPivot] = []

        for (index, pivotResponse) in apiResponse.pivots.enumerated() {
            let uuid = UUID()
            pivotUUIDs.append(uuid)

            let prerequisites = (pivotResponse.dependsOn ?? []).compactMap { depIndex in
                depIndex < pivotUUIDs.count ? pivotUUIDs[depIndex] : nil
            }

            let pivot = TopicPivot(
                id: uuid,
                title: pivotResponse.title,
                description: pivotResponse.description,
                order: index,
                estimatedReadingTime: pivotResponse.estimatedReadingTime,
                prerequisites: prerequisites
            )
            pivots.append(pivot)
        }

        let totalReadingTime = pivots.reduce(0) { $0 + $1.estimatedReadingTime }

        let learningPath = LearningPath(
            pivots: pivots,
            estimatedReadingTime: totalReadingTime,
            keyConcepts: apiResponse.keyConcepts
        )

        let category = TopicCategory(rawValue: apiResponse.category) ?? .other

        return GeneratedTopic(
            id: UUID(),
            title: apiResponse.title,
            summary: apiResponse.summary,
            category: category,
            sophisticationLevel: sophisticationLevel,
            learningPath: learningPath,
            createdAt: Date()
        )
    }
}

// MARK: - Errors

enum TopicGenerationError: Error, LocalizedError {
    case invalidResponse
    case parsingFailed(Error)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received invalid response from topic generation service"
        case .parsingFailed(let error):
            return "Failed to parse topic generation response: \(error.localizedDescription)"
        case .apiError(let message):
            return "Topic generation API error: \(message)"
        }
    }
}
