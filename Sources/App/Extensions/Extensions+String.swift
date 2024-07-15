//
//  Extensions+String.swift
//
//
//  Created by Reza Akbari on 7/15/24.
//

import Foundation

extension String {
    func extractDegreeAndMinuets() -> (String, String) {
        guard
            let upperIndex = (self.range(of: "°")?.upperBound),
            let lowerIndex = (self.range(of: "°")?.lowerBound) else {
            preconditionFailure()
        }
        let degree: String = String(self.prefix(upTo: lowerIndex))
        let minuets: String = String(self.suffix(from: upperIndex))

        return (degree, minuets)
    }
}
