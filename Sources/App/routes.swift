import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        "It's Work"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    try app.register(collection: PlanetController())
}
