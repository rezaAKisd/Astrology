//
//  Extensions+URL.swift
//
//
//  Created by Reza Akbari on 7/15/24.
//

import Factory
import Foundation
import Vapor

extension URL {
    func fetchContents(retries: Int = 10) async -> (String?, URL?) {
        let client = AppDIContainer.shared.httpClient.resolve()!
        do {
            let response = try await client.get(URI(stringLiteral: self.absoluteString))
            guard let body = response.body else {
                throw Abort(.custom(code: 500, reasonPhrase: "can't load content body"))
            }
            let html = String(decoding: body.readableBytesView, as: UTF8.self)
            return (html, nil)
        } catch {
            if retries > 0 {
                return await self.fetchContents(retries: retries - 1)
            } else {
                return (nil, self)
            }
        }
    }
}

//let response = try await client.get(self)
