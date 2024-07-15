//
//  Extensions+Element.swift
//
//
//  Created by Reza Akbari on 7/15/24.
//

import SwiftSoup

extension Element {
    func extractPlanetColumn() throws -> [Element] {
        try self.getElementsByAttributeValue("style", "float: left; width: 75px; margin-left: -5px;")
            .array()
    }
    func extractZodiacColumn() throws -> [Element] {
        try self.getElementsByAttributeValue("style", "float: left; width: 19px;").array()
    }
    
    func extractDegreeAndMinutesColumns() throws -> [Element] {
        try self.getElementsByAttributeValue(
            "style",
            "float: left; width: 35px; text-align: left; padding-right: 0px;"
        ).array()
    }
    
    func extractRXColumns() throws -> [Element] {
        try self.getElementsByAttributeValue(
            "style",
            "float: left; width: 10px; padding-left: 10px; font-size: 1.2em;"
        ).array()
    }
}
