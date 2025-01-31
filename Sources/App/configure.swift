import Vapor
import Fluent
import FluentPostgresDriver
import Factory

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.http.client.configuration.timeout = .init(connect: .hours(.max), read: .hours(.max), write: .hours(.max))

    // register postgres
    app.databases.use(
        .postgres(
            configuration: .init(
                hostname: Environment.get("DATABASE_HOST") ?? "localhost",
                port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
                username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
                password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
                database: Environment.get("DATABASE_NAME") ?? "vapor_database",
                tls: .disable
            )
        ),
        as: .psql
    )

    let planetMigrator = PlanetMigration()

    //    manual migrate
    //    try await migrator.prepare(on: app.db)
    //    try await migrator.revert(on: app.db)

    //    auto migrate
    app.migrations.add(planetMigrator)
    try await app.autoMigrate()
//    try await app.autoRevert()

    
    // Factory
    AppDIContainer.shared.db.register { app.db }
    AppDIContainer.shared.httpClient.register { app.client }
    
    Task {
        try await AppDIContainer.shared.loadEphemeris.resolve().loadEphemerisAndConjuction()
    }
    
    // register routes
    try routes(app)
}
