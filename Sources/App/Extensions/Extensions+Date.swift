//
//  Extensions+URL.swift
//
//
//  Created by Reza Akbari on 7/15/24.
//

import Factory
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Vapor

extension Date {
    func fetchContents(retries: Int = 10) async -> (String?, String?) {
        let parameters: [String: String] = [
            "datum_interval": "\(self)",
            "styl_graf": "1",
            "narozeni_mesto": "",
            "nastaveni_toggle": "",
            "aspekty_detail_check": "1",
            "orb": "0",
            "house_system": "none",
            "phours": "",
            "hid_fortune_check": "on",
            "hid_vertex_check": "on",
            "hid_chiron_check": "on",
            "hid_lilith_check": "on",
            "hid_uzel_check": "on",
            "interval_smer": "zpet",
            "interval_hodnota": "1day",
            "aya": ""
        ]

        // ساخت URLComponents
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "horoscopes.astro-seek.com"
        urlComponents.path = "/browse-current-planets/"
        urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = urlComponents.url else {
            return (nil, urlComponents.url?.absoluteString)
        }

        let client = AppDIContainer.shared.httpClient.resolve()!
        do {
            let response = try await client.get(URI(stringLiteral: url.absoluteString))
            guard let body = response.body else {
                throw Abort(.custom(code: 500, reasonPhrase: "can't load content body"))
            }
            let html = String(decoding: body.readableBytesView, as: UTF8.self)
            return (html, nil)
        } catch {
            if retries > 0 {
                return await self.fetchContents(retries: retries - 1)
            } else {
                return (nil, url.absoluteString)
            }
        }
    }
}
