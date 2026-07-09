//
//  URLProtocolStub.swift
//  MedicAppRemindTests
//
//  FX.S2 — In-process network double for CIMAServiceTests. No request ever leaves
//  the device; responses are canned per absolute URL string on an actor-backed
//  store, which also counts hits so tests can prove the in-memory cache works.
//

import Foundation

actor URLProtocolStubStore {
    static let shared = URLProtocolStubStore()

    private var responses: [String: (data: Data, statusCode: Int)] = [:]
    private var requestCounts: [String: Int] = [:]

    func stub(url: String, data: Data, statusCode: Int = 200) {
        responses[url] = (data, statusCode)
    }

    func reset() {
        responses = [:]
        requestCounts = [:]
    }

    func requestCount(for url: String) -> Int {
        requestCounts[url, default: 0]
    }

    /// Records the hit and returns the canned response, if any.
    func resolve(_ url: String) -> (data: Data, statusCode: Int)? {
        requestCounts[url, default: 0] += 1
        return responses[url]
    }
}

/// `URLProtocol` predates Swift concurrency and is never called concurrently on the
/// same instance — `URLSession` serializes `startLoading()`/`stopLoading()` per
/// instance on its own private queue. That documented contract is what makes
/// bridging into `URLProtocolStubStore` (an actor) from this nonisolated override
/// safe in practice, even though the compiler can't see it across the Foundation
/// boundary. Approved with Adolfo (FX.S2) as the one deliberate `@unchecked
/// Sendable` in the test target — do not copy this pattern into production code.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let key = url.absoluteString
        Task {
            guard let stub = await URLProtocolStubStore.shared.resolve(key) else {
                client?.urlProtocol(self, didFailWithError: URLError(.fileDoesNotExist))
                return
            }
            guard let response = HTTPURLResponse(
                url: url,
                statusCode: stub.statusCode,
                httpVersion: nil,
                headerFields: nil
            ) else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: stub.data)
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}
