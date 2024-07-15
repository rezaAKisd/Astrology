//
//  Planet.swift
//
//
//  Created by Reza Akbari on 7/12/24.
//

import Fluent
import Vapor

final class Planet: Model, Content {
    static let schema = "planet"

    @ID(custom: "id", generatedBy: .user) var id: String?

    @Field(key: "date") var date: Date
    @Field(key: "name") var name: String
    @Field(key: "zodiac") var zodiac: String
    @Field(key: "degree") var degree: String
    @Field(key: "minutes") var minutes: String
    @Field(key: "rx") var rx: Bool

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(id: String, date: Date, planet: String, degree: String, minutes: String, zodiac: String, rx: Bool) {
        self.id = id
        self.date = date
        self.name = planet
        self.degree = degree
        self.minutes = minutes
        self.zodiac = zodiac
        self.rx = rx
    }

    var planetType: PlanetType {
        PlanetType(planetName: name)
    }

    var zodiacType: ZodiacType {
        ZodiacType(signName: zodiac)
    }
}

// Enum for planets
enum PlanetType: String, Codable {
    case sun = "Sun"
    case moon = "Moon"
    case mercury = "Mercury"
    case venus = "Venus"
    case mars = "Mars"
    case jupiter = "Jupiter"
    case saturn = "Saturn"
    case uranus = "Uranus"
    case neptune = "Neptune"
    case pluto = "Pluto"
    case nodeM = "Node (M)"
    case nodeT = "Node (T)"
    case lilith = "Lilith"
    case chiron = "Chiron"

    init(planetName: String) {
        self.init(rawValue: planetName.capitalized)!
    }
}

// Enum for zodiac signs
enum ZodiacType: String, Codable {
    case aries = "Aries"
    case taurus = "Taurus"
    case gemini = "Gemini"
    case cancer = "Cancer"
    case leo = "Leo"
    case virgo = "Virgo"
    case libra = "Libra"
    case scorpio = "Scorpio"
    case sagittarius = "Sagittarius"
    case capricorn = "Capricorn"
    case aquarius = "Aquarius"
    case pisces = "Pisces"

    init(signName: String) {
        self.init(rawValue: signName.capitalized)!
    }
}
