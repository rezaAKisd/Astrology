//
//  LoadEphemeris.swift
//
//
//  Created by Reza Akbari on 7/15/24.
//

import Fluent
import Vapor
import SwiftSoup

class LoadEphemeris {
    let chunkSize = Int(Environment.get("CHUNCK_SIZE") ?? "50") ?? 50
    let db: Database

    init(db: Database) {
        self.db = db
    }

    func generateMinuteTimestamps() async throws -> AsyncStream<Date> {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "en-US")
        calendar.timeZone = .init(secondsFromGMT: .zero)!
        let startDateComponents = DateComponents(year: 2009, month: 12, day: 31, hour: 0, minute: 0)
        let startDate = calendar.date(from: startDateComponents)!
        let currentDate = Date()

        return AsyncStream { continuation in
            Task {
                let oneMinute: TimeInterval = 60
                var date = startDate

                while date <= currentDate {
                    continuation.yield(date)
                    date = date.addingTimeInterval(oneMinute)
                }

                continuation.finish()
            }
        }
    }

    func savedTimeStamp() async throws -> Set<Date> {
        let timestamps = try await Planet.query(on: db)
            .all(\.$date)
            .sorted()
        return Set(timestamps)
    }

    func loadEphemerisAndConjuction() async throws -> HTTPStatus {
        let savedTimestamp = try await savedTimeStamp()
        let asyncTimestamps = try await generateMinuteTimestamps()
        var chunk: [Date] = []

        for await date in asyncTimestamps {
            if !savedTimestamp.contains(date) {
                chunk.append(date)
                if chunk.count >= chunkSize {
                    try await processChunk(chunk)
                    chunk.removeAll()
                }
            }
        }

        if !chunk.isEmpty {
            try await processChunk(chunk)
        }

        return .ok
    }

    private func processChunk(_ timestamps: [Date]) async throws {
        var urls: [Date: String] = [:]
        
        for date in timestamps {
            urls[date] =
                "https://horoscopes.astro-seek.com/browse-current-planets/?datum_interval=\(date)&styl_graf=1&narozeni_mesto=&nastaveni_toggle=&aspekty_detail_check=1&orb=0&house_system=none&phours=&hid_fortune_check=on&hid_vertex_check=on&hid_chiron_check=on&hid_lilith_check=on&hid_uzel_check=on&interval_smer=zpet&interval_hodnota=1day&aya="
        }

        try await withThrowingTaskGroup(of: [Planet].self) { group in
            for (date, urlString) in urls {
                group.addTask {
                    guard let url = URL(string: urlString) else {
                        throw Abort(.forbidden)
                    }
                    let (content, _) = await url.fetchContents()
                    guard let content else { throw Abort(.forbidden) }

                    do {
                        let doc: Document = try SwiftSoup.parse(content)
                        let planetColumns = try doc.extractPlanetColumn()
                        let zodiacColumns = try doc.extractZodiacColumn()
                        let degreeAndMinutesColumns = try doc.extractDegreeAndMinutesColumns()
                        let rxColumns = try doc.extractRXColumns()

                        var planetResult: [Planet] = []
                        for index in 0..<planetColumns.count {
                            let planet = try planetColumns[index].text()
                            let zodiac = try zodiacColumns[index].select("img").attr("title")
                            let (degree, minutes) = try degreeAndMinutesColumns[index].text().extractDegreeAndMinuets()
                            let rx = try !rxColumns[index].text().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

                            planetResult.append(Planet(
                                id: "\(date)" + "-" + planet + "-" + zodiac + "-" + degree + "-" + minutes + "-" + "\(rx)",
                                date: date,
                                planet: planet,
                                degree: degree,
                                minutes: minutes,
                                zodiac: zodiac,
                                rx: rx
                            ))
                        }

                        print(date)
                        return planetResult
                    } catch {
                        print("Failed to parse content for URL: \(url) with error: \(error)")
                        throw Abort(.forbidden)
                    }
                }
            }

            for try await planets in group {
                for planet in planets {
                    try await planet.save(on: db)
                }
            }
        }
    }
}
