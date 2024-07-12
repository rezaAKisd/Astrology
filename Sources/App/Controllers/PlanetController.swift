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
            index(req: req)
        }
        planets.post { req in
            create(req: req)
        }
    }

    // GET Request /planets route
    func index(req: Request) throws -> EventLoopFuture<[Planet]> {
        Planet.query(on: req.db).all()
    }

    // POST Request /planets route
    func create(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let song = try req.content.decode(Planet.self)
        return song.save(on: req.db).transform(to: .ok)
    }
}
