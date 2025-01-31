//
//  LoadEphemeris.swift
//
//
//  Created by Reza Akbari on 7/15/24.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Fluent
import Vapor
import SwiftSoup
import Factory

class LoadEphemeris {
    @Injected(\.appDIContainer.db) private var db: Database!
    
    private let oneDay: TimeInterval = 60 * 60 * 24
    private let chunkSize = 60 * 60

    func generateMinuteTimestamps(startDate: Date?) async throws -> AsyncStream<Date> {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "en-US")
        calendar.timeZone = .init(secondsFromGMT: .zero)!
        let startDateComponents = DateComponents(year: 1999, month: 12, day: 31, hour: 0, minute: 0)
        let startDate = startDate ?? calendar.date(from: startDateComponents)!
        let currentDate = Date()

        return AsyncStream { continuation in
            Task {
                let oneMinute: TimeInterval = 60
                
                var date = startDate

                while date <= currentDate {
                    let endDate = min(date.addingTimeInterval(oneDay), currentDate)

                    while date <= endDate {
                        continuation.yield(date)
                        date = date.addingTimeInterval(oneMinute)
                    }
                }

                continuation.finish()
            }
        }
    }

    func savedTimeStamp() async throws -> Set<Date> {
        let timestamps = try await Planet.query(on: db)
            .sort(\.$date, .descending)
            .limit(Int(chunkSize))
            .all(\.$date)
        return Set(timestamps)
    }

    func loadEphemerisAndConjuction() async throws -> HTTPStatus {
        let savedTimestamp = try await savedTimeStamp()
        let asyncTimestamps = try await generateMinuteTimestamps(startDate: Array(savedTimestamp).first)
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
        try await withThrowingTaskGroup(of: [Planet].self) { group in
            for date in timestamps {
                group.addTask {
                    let (content, failUrl) = await date.fetchContents()
                    guard let content else {
                        throw Abort(.custom(code: 500, reasonPhrase: "cant load content \(content), \(String(describing: failUrl))"))
                    }

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
                        print("Failed to parse content for URL: \(date) with error: \(error)")
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
