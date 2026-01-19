import Foundation

/// Client for interacting with the OpenAI ChatGPT and Image APIs
actor OpenAIAPIClient {

    let apiKey: String
    let baseURL = URL(string: "https://api.openai.com/v1")!
    let session: URLSession
    let model: String

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

// MARK: - Image Generation

extension OpenAIAPIClient {

    /// Generates an image using OpenAI's GPT Image API
    /// - Parameter request: Configuration for image generation
    /// - Returns: The generated image response
    func generateImage(request: ImageGenerationRequest) async throws -> ImageGenerationResponse {
        let url = baseURL.appendingPathComponent("images/generations")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageGenerationError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ImageGenerationError.httpError(
                statusCode: httpResponse.statusCode,
                body: errorBody
            )
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(ImageGenerationResponse.self, from: data)
        } catch {
            throw ImageGenerationError.decodingFailed(error)
        }
    }

    /// Generates a single image and returns the base64-encoded data
    /// - Parameters:
    ///   - prompt: Text description of the desired image
    ///   - size: Image dimensions
    ///   - quality: Image quality level
    /// - Returns: Base64-encoded image data
    func generateImageData(
        prompt: String,
        size: ImageSize = .square1024,
        quality: ImageQuality = .medium
    ) async throws -> String {
        let request = ImageGenerationRequest(
            prompt: prompt,
            size: size,
            quality: quality
        )

        let response = try await generateImage(request: request)

        guard let imageData = response.data.first else {
            throw ImageGenerationError.noImageData
        }

        // GPT Image models return base64 data
        if let b64Data = imageData.b64Json {
            return b64Data
        }

        // Fallback: If URL is provided, download and convert to base64
        if let urlString = imageData.url, let url = URL(string: urlString) {
            return try await downloadImageAsBase64(from: url)
        }

        throw ImageGenerationError.noImageData
    }

    /// Downloads an image from a URL and returns base64-encoded data
    private func downloadImageAsBase64(from url: URL) async throws -> String {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ImageGenerationError.downloadFailed
        }

        return data.base64EncodedString()
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

// MARK: - Image Generation Errors

enum ImageGenerationError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, body: String)
    case decodingFailed(Error)
    case noImageData
    case downloadFailed
    case promptTooLong

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from image generation API"
        case .httpError(let statusCode, let body):
            return "Image generation API error (HTTP \(statusCode)): \(body)"
        case .decodingFailed(let error):
            return "Failed to decode image generation response: \(error.localizedDescription)"
        case .noImageData:
            return "No image data returned from API"
        case .downloadFailed:
            return "Failed to download image from URL"
        case .promptTooLong:
            return "Image generation prompt exceeds maximum length (32000 characters)"
        }
    }
}
