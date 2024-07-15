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
        let planets = routes.grouped("planet")

        planets.post("create") { req async throws -> HTTPStatus in
            try await create(req: req)
        }

        planets.get("all") { req async throws -> [Planet] in
            try await getAll(req: req)
        }

        planets.get("get") { req async throws -> Planet in
            try await getPlanet(req: req)
        }

        planets.put("update") { req async throws -> HTTPStatus in
            try await update(req: req)
        }
    }

    // Create
    private func create(req: Request) async throws -> HTTPStatus {
        let planet = try req.content.decode(Planet.self)
        try await planet.create(on: req.db)
        return .ok
    }

    // Retrieve All
    private func getAll(req: Request) async throws -> [Planet] {
        try await Planet.query(on: req.db)
            .all()
    }

    // Retrieve A Single With Query Param
    private func getPlanet(req: Request) async throws -> Planet {
        let planet = try req.query.get(String.self, at: "planet")
        guard
            let planet = try await Planet.query(on: req.db)
                .filter(\.$name, .equal, planet)
                .first()
        else {
            throw Abort(.notFound)
        }

        return planet
    }

    // update A Single With Body
    private func update(req: Request) async throws -> HTTPStatus {
        let planet = try req.content.decode(Planet.self)
        guard
            let planet = try await Planet.query(on: req.db)
                .filter(\.$name, .equal, planet.name)
                .first()
        else {
            throw Abort(.notFound)
        }
        planet.zodiac = "test"
        try await planet.update(on: req.db)
        return .ok
    }
}
