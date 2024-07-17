import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws -> HTTPStatus in
        return try await AppDIContainer.shared.loadEphemeris.resolve().loadEphemerisAndConjuction()
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    try app.register(collection: PlanetController())
}
