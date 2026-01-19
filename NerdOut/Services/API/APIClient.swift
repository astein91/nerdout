import Foundation

/// Protocol for API client operations
protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    func requestData(_ endpoint: APIEndpoint) async throws -> Data
}

/// Core API client with async/await networking
final class APIClient: APIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    /// Shared singleton instance
    static let shared = APIClient()

    init(session: URLSession = .shared) {
        self.session = session

        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
    }

    /// Execute a request and decode the response
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let data = try await requestData(endpoint)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    /// Execute a request and return raw data
    func requestData(_ endpoint: APIEndpoint) async throws -> Data {
        let urlRequest = try buildRequest(for: endpoint)
        return try await executeWithRetry(urlRequest, endpoint: endpoint)
    }

    // MARK: - Private Methods

    private func buildRequest(for endpoint: APIEndpoint) throws -> URLRequest {
        guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.timeout

        // Set headers
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Set body if present
        if let body = endpoint.body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw APIError.encodingFailed(error)
            }
        }

        return request
    }

    private func executeWithRetry(
        _ request: URLRequest,
        endpoint: APIEndpoint,
        attempt: Int = 0
    ) async throws -> Data {
        do {
            return try await execute(request)
        } catch let error as APIError where error.isRetryable && attempt < APIConfiguration.Network.maxRetryAttempts {
            let delay = calculateBackoff(attempt: attempt, baseDelay: error.suggestedRetryDelay)
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            return try await executeWithRetry(request, endpoint: endpoint, attempt: attempt + 1)
        }
    }

    private func execute(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            throw mapURLError(urlError)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unexpectedResponse
        }

        try validateResponse(httpResponse, data: data)

        if data.isEmpty {
            throw APIError.emptyResponse
        }

        return data
    }

    private func validateResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 429:
            let retryAfter = response.value(forHTTPHeaderField: "Retry-After")
                .flatMap { Double($0) }
            throw APIError.rateLimited(retryAfter: retryAfter)
        case 500...599:
            let message = extractErrorMessage(from: data)
            if response.statusCode == 503 {
                throw APIError.serviceUnavailable
            }
            throw APIError.serverError(statusCode: response.statusCode, message: message)
        default:
            throw APIError.requestFailed(statusCode: response.statusCode, data: data)
        }
    }

    private func mapURLError(_ error: URLError) -> APIError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        case .timedOut:
            return .timeout
        default:
            return .requestFailed(statusCode: error.errorCode, data: nil)
        }
    }

    private func extractErrorMessage(from data: Data) -> String? {
        // Try to decode as OpenAI error first
        if let openAIError = try? decoder.decode(OpenAIErrorResponse.self, from: data) {
            return openAIError.error.message
        }
        // Try generic error message
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String ?? json["error"] as? String {
            return message
        }
        return nil
    }

    private func calculateBackoff(attempt: Int, baseDelay: TimeInterval) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...0.5)
        return min(exponentialDelay + jitter, 60.0) // Cap at 60 seconds
    }
}
