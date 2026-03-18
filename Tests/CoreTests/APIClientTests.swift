import Testing
import Foundation
@testable import HallyuCore

@Suite("APIClient Tests")
struct APIClientTests {

    @Test("APIRequest constructs with default values")
    func apiRequestDefaults() {
        let request = APIRequest(path: "/test")
        #expect(request.path == "/test")
        #expect(request.method == .get)
        #expect(request.headers.isEmpty)
        #expect(request.queryItems.isEmpty)
        #expect(request.body == nil)
    }

    @Test("APIRequest constructs with POST and body")
    func apiRequestWithBody() throws {
        struct TestBody: Codable {
            let name: String
        }
        let request = try APIRequest(path: "/test", method: .post, body: TestBody(name: "test"))
        #expect(request.method == .post)
        #expect(request.body != nil)
    }

    @Test("APIRequest with query items")
    func apiRequestWithQuery() {
        let request = APIRequest(
            path: "/items",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "limit", value: "10")
            ]
        )
        #expect(request.queryItems.count == 2)
    }

    @Test("APIError descriptions are meaningful")
    func apiErrorDescriptions() {
        let errors: [APIError] = [
            .invalidURL,
            .invalidResponse,
            .unauthorized,
            .rateLimited(retryAfter: 30),
            .serverError(statusCode: 500)
        ]
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    @Test("HTTPMethod raw values match HTTP standards")
    func httpMethodRawValues() {
        #expect(HTTPMethod.get.rawValue == "GET")
        #expect(HTTPMethod.post.rawValue == "POST")
        #expect(HTTPMethod.put.rawValue == "PUT")
        #expect(HTTPMethod.patch.rawValue == "PATCH")
        #expect(HTTPMethod.delete.rawValue == "DELETE")
    }
}
