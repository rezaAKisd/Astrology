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
    let chunkSize = 1000

    var counter = 0.0
    var jsonFailedURL: [URL] = []
    var planetResult: [Planet] = []

    let db: Database

    init(db: Database) {
        self.db = db
    }

    func generateMinuteTimestamps() async throws -> [Date] {
        var timestamps: [Date] = []

        let calendar = Calendar.current
//        let startDateComponents = DateComponents(year: 1999, month: 12, day: 31, hour: 0, minute: 0)
        let startDateComponents = DateComponents(year: 2024, month: 07, day: 15, hour: 16, minute: 15)
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
        
        let savedTimestamp = try await savedTimeStamp()
        
        return Array(Set(timestamps).subtracting(savedTimestamp))
    }

    func savedTimeStamp() async throws -> [Date] {
        try await Planet.query(on: db)
            .all(\.$date)
            .sorted()
    }
    
    func loadEphemerisAndConjuction() async throws -> HTTPStatus {
        var urls: [Date: String] = [:]

        for date in try await generateMinuteTimestamps() {
            urls[date] =
                "https://horoscopes.astro-seek.com/browse-current-planets/?datum_interval=\(date)&styl_graf=1&narozeni_mesto=&nastaveni_toggle=&aspekty_detail_check=1&orb=0&house_system=none&phours=&hid_fortune_check=on&hid_vertex_check=on&hid_chiron_check=on&hid_lilith_check=on&hid_uzel_check=on&interval_smer=zpet&interval_hodnota=1day&aya="
        }

        let totalCount: CGFloat = CGFloat(urls.count)
        try await withThrowingTaskGroup(of: [Planet].self) { group in
            for (date, urlString) in urls {
                group.addTask { [self] in
                    guard let url = URL(string: urlString) else {
                        throw Abort(.forbidden)
                    }
                    let (content, failedURL) = await url.fetchContents()

                    if let failedURL {
                        jsonFailedURL.append(failedURL)
                    }
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

                        counter += 1
                        print(counter / totalCount * 100)
                        return planetResult
                    } catch {
                        print("Failed to parse content for URL: \(url) with error: \(error)")
                        throw Abort(.forbidden)
                    }
                }

                while let planet = try await group.next() {
                    try await planet.asyncForEach {
                        try await $0.save(on: db)
                    }
                }
            }
        }

        return .ok
    }
}
