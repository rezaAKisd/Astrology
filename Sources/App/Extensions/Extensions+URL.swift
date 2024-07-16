//
//  Extensions+URL.swift
//
//
//  Created by Reza Akbari on 7/15/24.
//

import Foundation

extension URL {
    func fetchContents(retries: Int = 10) async -> (String?, URL?) {
        var request = URLRequest(url: self)
        request.httpMethod = "GET"
        let session = URLSession(configuration: URLSessionConfiguration.default)
        do {
            let (data, response) = try await session.data(for: request)
            let contents = String(data: data, encoding: .ascii)
            return (contents, nil)
        } catch {
            if retries > 0 {
                return await self.fetchContents(retries: retries - 1)
            } else {
                return (nil, self)
            }
        }
    }
}
