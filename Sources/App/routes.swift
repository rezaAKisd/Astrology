import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await LoadEphemeris(db: req.db).loadEphemerisAndConjuction()
        return "ok"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    try app.register(collection: PlanetController())
}
