//
//  PlanetMigration.swift
//
//
//  Created by Reza Akbari on 7/13/24.
//

import Fluent

struct PlanetMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("planet")
            .id()
            .field("title", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("planet").delete()
    }
}

struct PlanetTwoMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("planet")
            .field("name", .string)
            .field("image", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("planet")
            .deleteField("name")
            .deleteField("zodiac")
            .deleteField("image")
            .update()
    }
}
