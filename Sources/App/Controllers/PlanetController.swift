//
//  PlanetController.swift
//
//
//  Created by Reza Akbari on 7/12/24.
//

import Fluent
import Vapor

struct PlanetController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let planets = routes.grouped("planets")
        planets.get { req in
            try index(req: req)
        }
        planets.post { req in
            try create(req: req)
        }
    }

    // GET Request /planets route
    func index(req: Request) throws -> EventLoopFuture<[Planet]> {
        Planet.query(on: req.db).all()
    }

    // POST Request /planets route
    func create(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let planets = try req.content.decode(Planet.self)
        return planets.save(on: req.db).transform(to: .ok)
    }
}
