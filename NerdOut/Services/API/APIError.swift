import Foundation

/// Comprehensive error types for API operations
enum APIError: LocalizedError {
    // Network errors
    case noConnection
    case timeout
    case requestFailed(statusCode: Int, data: Data?)

    // Request building errors
    case invalidURL
    case encodingFailed(Error)

    // Response errors
    case decodingFailed(Error)
    case emptyResponse
    case unexpectedResponse

    // Authentication errors
    case unauthorized
    case forbidden
    case invalidAPIKey

    // Rate limiting
    case rateLimited(retryAfter: TimeInterval?)

    // Server errors
    case serverError(statusCode: Int, message: String?)
    case serviceUnavailable

    // OpenAI specific
    case openAIError(code: String?, message: String)
    case contentFiltered
    case modelOverloaded
    case invalidRequest(message: String)

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection. Please check your network settings."
        case .timeout:
            return "The request timed out. Please try again."
        case .requestFailed(let statusCode, _):
            return "Request failed with status code \(statusCode)."
        case .invalidURL:
            return "Invalid URL."
        case .encodingFailed(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .emptyResponse:
            return "Received empty response from server."
        case .unexpectedResponse:
            return "Received unexpected response format."
        case .unauthorized:
            return "Authentication required. Please sign in."
        case .forbidden:
            return "Access denied."
        case .invalidAPIKey:
            return "Invalid API key."
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Rate limited. Please try again in \(Int(seconds)) seconds."
            }
            return "Rate limited. Please try again later."
        case .serverError(let statusCode, let message):
            if let message = message {
                return "Server error (\(statusCode)): \(message)"
            }
            return "Server error (\(statusCode)). Please try again later."
        case .serviceUnavailable:
            return "Service temporarily unavailable. Please try again later."
        case .openAIError(_, let message):
            return "OpenAI error: \(message)"
        case .contentFiltered:
            return "Content was filtered due to safety guidelines."
        case .modelOverloaded:
            return "The AI model is currently overloaded. Please try again."
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .timeout, .rateLimited, .serverError, .serviceUnavailable, .modelOverloaded:
            return true
        default:
            return false
        }
    }

    var suggestedRetryDelay: TimeInterval {
        switch self {
        case .rateLimited(let retryAfter):
            return retryAfter ?? 60.0
        case .modelOverloaded:
            return 30.0
        case .serverError, .serviceUnavailable:
            return 5.0
        case .timeout:
            return 2.0
        default:
            return 0
        }
    }
}

/// OpenAI API error response structure
struct OpenAIErrorResponse: Decodable {
    let error: OpenAIErrorDetail

    struct OpenAIErrorDetail: Decodable {
        let message: String
        let type: String?
        let param: String?
        let code: String?
    }
}
