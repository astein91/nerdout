import Foundation

/// Protocol defining an API endpoint
protocol APIEndpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: Encodable? { get }
    var timeout: TimeInterval { get }
}

/// Default implementations for common endpoint properties
extension APIEndpoint {
    var timeout: TimeInterval {
        APIConfiguration.Network.requestTimeout
    }

    var body: Encodable? {
        nil
    }
}

/// Type-erased wrapper for Encodable body
struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T) {
        self.encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
