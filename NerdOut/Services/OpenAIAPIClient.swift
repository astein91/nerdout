import Foundation

/// Client for interacting with the OpenAI ChatGPT API
actor OpenAIAPIClient {

    private let apiKey: String
    private let baseURL = URL(string: "https://api.openai.com/v1")!
    private let session: URLSession
    private let model: String

    init(apiKey: String, model: String = "gpt-4o", session: URLSession = .shared) {
        self.apiKey = apiKey
        self.model = model
        self.session = session
    }

    /// Sends a chat completion request to the OpenAI API
    /// - Parameters:
    ///   - messages: Array of chat messages
    ///   - responseFormat: Expected response format
    /// - Returns: The assistant's response content
    func sendChatCompletion(
        messages: [ChatMessage],
        responseFormat: ResponseFormat = .text
    ) async throws -> String {
        let url = baseURL.appendingPathComponent("chat/completions")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ChatCompletionRequest(
            model: model,
            messages: messages,
            responseFormat: responseFormat == .json
                ? ResponseFormatSpec(type: "json_object")
                : nil
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIError.httpError(statusCode: httpResponse.statusCode, body: errorBody)
        }

        let completionResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

        guard let content = completionResponse.choices.first?.message.content else {
            throw OpenAIError.noContent
        }

        return content
    }
}

// MARK: - Request/Response Types

struct ChatMessage: Codable {
    let role: ChatRole
    let content: String
}

enum ChatRole: String, Codable {
    case system
    case user
    case assistant
}

enum ResponseFormat {
    case text
    case json
}

private struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let responseFormat: ResponseFormatSpec?

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case responseFormat = "response_format"
    }
}

private struct ResponseFormatSpec: Codable {
    let type: String
}

private struct ChatCompletionResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String?
    }
}

// MARK: - Errors

enum OpenAIError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, body: String)
    case noContent

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        case .httpError(let statusCode, let body):
            return "OpenAI API error (HTTP \(statusCode)): \(body)"
        case .noContent:
            return "OpenAI API returned no content"
        }
    }
}
