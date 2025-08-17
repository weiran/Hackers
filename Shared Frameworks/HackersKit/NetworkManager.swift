import Foundation

class NetworkManager: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    private var session: URLSession!

    override init() {
        super.init()
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    func get(url: URL) async throws -> String {
        let request = URLRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return String(data: data, encoding: .utf8) ?? ""
    }

    func post(url: URL, body: String) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await session.data(for: request)
        let html = String(data: data, encoding: .utf8) ?? ""

        return html
    }

    func clearCookies() {
        HTTPCookieStorage.shared.cookies?.forEach(HTTPCookieStorage.shared.deleteCookie(_:))
    }

    func containsCookie(for url: URL) -> Bool {
        guard let cookies = HTTPCookieStorage.shared.cookies(for: url) else {
            return false
        }
        return !cookies.isEmpty
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        // avoid following redirects
        completionHandler(nil)
    }
}
