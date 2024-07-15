//
//  Planet.swift
//
//
//  Created by Reza Akbari on 7/12/24.
//

import Fluent
import Vapor

final class Planet: Model, Content {
    static let schema = "planet"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String

    @Field(key: "name")
    var name: String?

    @Field(key: "image")
    var image: String?

    init() {}

    init(id: UUID? = nil, title: String, name: String?, image: String?) {
        self.id = id
        self.title = title
    }
}

extension Planet: Comparable {
    static func < (lhs: Planet, rhs: Planet) -> Bool {
        lhs.title < rhs.title
    }
    
    static func == (lhs: Planet, rhs: Planet) -> Bool {
        lhs.title == rhs.title
    }
}
