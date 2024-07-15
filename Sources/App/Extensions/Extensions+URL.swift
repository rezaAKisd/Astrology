//
//  Extensions+URL.swift
//
//
//  Created by Reza Akbari on 7/15/24.
//

import Foundation

extension URL {
    func fetchContents(retries: Int = 10) async -> (String?, URL?) {
        return await withCheckedContinuation { continuation in
            fetchContents(retries: retries) { content, url in
                continuation.resume(returning: (content, url))
            }
        }
    }
    
    private func fetchContents(retries: Int = 10, completion: @escaping (String?, URL?) -> Void) {
        DispatchQueue.global().async {
            do {
                let content = try String(contentsOf: self)
                completion(content, nil)
            } catch {
                if retries > 0 {
                    print("Retrying... \(self)")
                    self.fetchContents(retries: retries - 1, completion: completion)
                } else {
                    print("Failed to fetch contents for URL: \(self) after retries")
                    completion(nil, self)
                }
            }
        }
    }
}
