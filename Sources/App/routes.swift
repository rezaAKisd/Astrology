import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    // Create
    app.post("planet", "create") { req async throws -> HTTPStatus in
        let planet = try req.content.decode(Planet.self)
        try await planet.create(on: req.db)
        return .ok
    }

    // Retrieve All
    app.get("planet", "all") { req async throws -> [Planet] in
        try await Planet.query(on: req.db)
            .all()
            .sorted()
    }

    // Retrieve A Single With Query Param
    app.get("planet", "get") { req async throws -> Planet in
        let planetTitle = try req.query.get(String.self, at: "title")
        guard
            let planet = try await Planet.query(on: req.db)
                .filter(\.$title, .equal, planetTitle)
                .first()
        else {
            throw Abort(.notFound)
        }

        return planet
    }

    // Update A Planet
    app.put("planet", "update") { req async throws -> HTTPStatus in
        let planet = try req.content.decode(Planet.self)
        guard
            let planet = try await Planet.query(on: req.db)
                .filter(\.$title, .equal, planet.title)
                .first()
        else {
            throw Abort(.notFound)
        }
        planet.name = planet.title
        try await planet.update(on: req.db)
        return .ok
    }

    try app.register(collection: PlanetController())
}
