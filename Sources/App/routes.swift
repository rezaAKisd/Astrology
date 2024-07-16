import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws -> HTTPStatus in
        try await LoadEphemeris(db: app.db).loadEphemerisAndConjuction()
        return .ok
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    try app.register(collection: PlanetController())
}
