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
            .field("id", .string, .identifier(auto: false))
            .field("date", .datetime, .required)
            .field("name", .string, .required)
            .field("zodiac", .string, .required)
            .field("degree", .string, .required)
            .field("minutes", .string, .required)
            .field("rx", .bool, .required)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .unique(on: "date", "name", "zodiac", "degree", "minutes", "rx")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("planet").delete()
    }
}
