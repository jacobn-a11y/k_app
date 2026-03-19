import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case networkError(Error)
    case unauthorized
    case rateLimited(retryAfter: TimeInterval?)
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .httpError(let code, _): return "HTTP error: \(code)"
        case .decodingError: return "Invalid server response"
        case .networkError: return "Network error. Please check your connection."
        case .unauthorized: return "Unauthorized"
        case .rateLimited: return "Rate limited"
        case .serverError(let code): return "Server error: \(code)"
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct APIRequest {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]
    let queryItems: [URLQueryItem]
    let body: Data?

    init(
        path: String,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
    }

    init<T: Encodable>(
        path: String,
        method: HTTPMethod = .post,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        body: T
    ) throws {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.body = try JSONEncoder().encode(body)
    }
}

actor APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let maxRetries: Int
    private let defaultHeaders: [String: String]

    init(
        baseURL: URL,
        session: URLSession = .shared,
        maxRetries: Int = 3,
        defaultHeaders: [String: String] = [:]
    ) {
        self.baseURL = baseURL
        self.session = session
        self.maxRetries = maxRetries
        self.defaultHeaders = defaultHeaders
    }

    func send<T: Decodable>(_ request: APIRequest) async throws -> T {
        let data = try await sendRaw(request)
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func sendRaw(_ request: APIRequest) async throws -> Data {
        let urlRequest = try buildURLRequest(request)
        var lastError: Error = APIError.invalidResponse

        for attempt in 0...maxRetries {
            if attempt > 0 {
                let delay = pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            do {
                let (data, response) = try await session.data(for: urlRequest)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw APIError.unauthorized
                case 429:
                    let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                        .flatMap { TimeInterval($0) }
                    throw APIError.rateLimited(retryAfter: retryAfter)
                case 500...599:
                    lastError = APIError.serverError(statusCode: httpResponse.statusCode)
                    continue // retry on server errors
                default:
                    throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
                }
            } catch let error as APIError {
                switch error {
                case .serverError, .rateLimited:
                    lastError = error
                    continue
                default:
                    throw error
                }
            } catch {
                lastError = APIError.networkError(error)
                continue
            }
        }

        throw lastError
    }

    private func buildURLRequest(_ request: APIRequest) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(request.path), resolvingAgainstBaseURL: true)
        if !request.queryItems.isEmpty {
            components?.queryItems = request.queryItems
        }

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        // Apply default headers
        for (key, value) in defaultHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Apply request-specific headers (override defaults)
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if request.body != nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return urlRequest
    }
}
