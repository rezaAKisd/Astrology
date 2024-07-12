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
    
    @Field(key: "name")
    var title: String
    
    init() { }
    
    init(id: UUID? = nil, title: String) {
        self.id = id
        self.title = title
    }
}
