//
//  PlanetController.swift
//
//
//  Created by Reza Akbari on 7/12/24.
//

import Fluent
import Vapor
import SwiftSoup

struct PlanetController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let planets = routes.grouped("planets")
        planets.get { req in
            try index(req: req)
        }
        planets.post { req in
            try create(req: req)
        }
    }

    // GET Request /planets route
    func index(req: Request) throws -> EventLoopFuture<[Planet]> {
        Planet.query(on: req.db).all()
    }

    // POST Request /planets route
    func create(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let planets = try req.content.decode(Planet.self)
        return planets.save(on: req.db).transform(to: .ok)
    }
}


class LoadEphemerisAndConjuction {
    var counter = 0
    let chunkSize = 1000
    var jsonFailedURL: [URL] = []
    var planetResult: [Planet2] = []

    func generateMinuteTimestamps() async -> [Date] {
        var timestamps: [Date] = []

        let calendar = Calendar.current
//        let startDateComponents = DateComponents(year: 1999, month: 12, day: 31, hour: 0, minute: 0)
        let startDateComponents = DateComponents(year: 2023, month: 12, day: 31, hour: 0, minute: 0)
        let startDate = calendar.date(from: startDateComponents)!
        let currentDate = Date()

        let oneMinute: TimeInterval = 60
        let totalMinutes = Int(currentDate.timeIntervalSince(startDate) / oneMinute)

        await withTaskGroup(of: [Date].self) { group in
            let numberOfChunks = (totalMinutes / chunkSize) + 1

            for i in 0..<numberOfChunks {
                group.addTask { [self] in
                    var chunkTimestamps: [Date] = []
                    var date = startDate.addingTimeInterval(TimeInterval(i * chunkSize * Int(oneMinute)))

                    for _ in 0..<chunkSize {
                        if date > currentDate { break }
                        chunkTimestamps.append(date)
                        date = date.addingTimeInterval(oneMinute)
                    }

                    return chunkTimestamps
                }
            }

            for await chunk in group {
                timestamps.append(contentsOf: chunk)
            }
        }

        return timestamps
    }

    func loadEphemerisAndConjuction() async {
        var urls: [Date: String] = [:]

        for date in await generateMinuteTimestamps() {
            urls[date] =
                "https://horoscopes.astro-seek.com/browse-current-planets/?datum_interval=\(date)&styl_graf=1&narozeni_mesto=&nastaveni_toggle=&aspekty_detail_check=1&orb=0&house_system=none&phours=&hid_fortune_check=on&hid_vertex_check=on&hid_chiron_check=on&hid_lilith_check=on&hid_uzel_check=on&interval_smer=zpet&interval_hodnota=1day&aya="
        }

        let allUrls = Array(urls) // Convert dictionary to array of tuples
        let chunks = stride(from: 0, to: allUrls.count, by: chunkSize).map {
            Array(allUrls[$0..<min($0 + chunkSize, allUrls.count)])
        }

        for chunk in chunks {
            await withTaskGroup(of: Void.self) { group in
                for (date, urlString) in chunk {
                    group.addTask { [self] in
                        guard let url = URL(string: urlString) else {
                            return
                        }
                        let (content, failedURL) = await url.fetchContents()

                        if let failedURL {
                            jsonFailedURL.append(failedURL)
                        }
                        guard let content else { return }

                        do {
                            let doc: Document = try SwiftSoup.parse(content)
                            let planetColumns = try doc.extractPlanetColumn()
                            let zodiacColumns = try doc.extractZodiacColumn()
                            let degreeAndMinutesColumns = try doc.extractDegreeAndMinutesColumns()
                            let rxColumns = try doc.extractRXColumns()

                            for index in 0..<planetColumns.count {
                                let planet = try planetColumns[index].text()
                                let zodiac = try zodiacColumns[index].select("img").attr("title")
                                let (degree, minutes) = try degreeAndMinutesColumns[index].text().extractDegreeAndMinuets()
                                let rx = try !rxColumns[index].text().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

                                planetResult.append(Planet2(planet: planet, degree: degree, minutes: minutes, zodiac: zodiac, rx: rx))
                            }

                            counter += 1
                            print(date)
                        } catch {
                            print("Failed to parse content for URL: \(url) with error: \(error)")
                        }
                    }
                }
            }
        }
    }
}

extension String {
    func extractDegreeAndMinuets() -> (String, String) {
        guard
            let upperIndex = (self.range(of: "°")?.upperBound),
            let lowerIndex = (self.range(of: "°")?.lowerBound) else {
            preconditionFailure()
        }
        let degree: String = String(self.prefix(upTo: lowerIndex))
        let minuets: String = String(self.suffix(from: upperIndex))
        
        return (degree, minuets)
    }
}

extension URL {
    func fetchContents(retries: Int = 10) async -> (String?, URL?) {
        return await withCheckedContinuation { continuation in
            fetchContents(retries: retries) { content, url in
                continuation.resume(returning: (content, url))
            }
        }
    }
    
    private func fetchContents(retries: Int = 10, completion: @escaping (String?, URL?) -> Void) {
        DispatchQueue.global().async {
            do {
                let content = try String(contentsOf: self)
                completion(content, nil)
            } catch {
                if retries > 0 {
                    print("Retrying... \(self)")
                    self.fetchContents(retries: retries - 1, completion: completion)
                } else {
                    print("Failed to fetch contents for URL: \(self) after retries")
                    completion(nil, self)
                }
            }
        }
    }
}

extension Element {
    func extractPlanetColumn() throws -> [Element] {
        try self.getElementsByAttributeValue("style", "float: left; width: 75px; margin-left: -5px;")
            .array()
    }
    func extractZodiacColumn() throws -> [Element] {
        try self.getElementsByAttributeValue("style", "float: left; width: 19px;").array()
    }
    
    func extractDegreeAndMinutesColumns() throws -> [Element] {
        try self.getElementsByAttributeValue(
            "style",
            "float: left; width: 35px; text-align: left; padding-right: 0px;"
        ).array()
    }
    
    func extractRXColumns() throws -> [Element] {
        try self.getElementsByAttributeValue(
            "style",
            "float: left; width: 10px; padding-left: 10px; font-size: 1.2em;"
        ).array()
    }

}



struct Planet2: Codable, Equatable, Hashable {
    let planet: String
    var planetType: PlanetType {
        PlanetType(planetName: planet)
    }
    let degree: String
    let minutes: String
    let zodiac: String
    var zodiacType: ZodiacType {
        ZodiacType(signName: zodiac)
    }
    let rx: Bool
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
