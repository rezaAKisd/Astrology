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
            .field("name", .string, .required)
            .field("zodiac", .string, .required)
            .field("degree", .string, .required)
            .field("minutes", .string, .required)
            .field("rx", .bool, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("planet").delete()
    }
}
