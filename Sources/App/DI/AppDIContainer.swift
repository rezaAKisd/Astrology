//
//  AppDIContainer.swift
//
//
//  Created by Reza Akbari on 7/17/24.
//

import Factory
import Vapor
import Fluent
import Logging

final class AppDIContainer: SharedContainer {
    public static var shared = AppDIContainer()
    public let manager = ContainerManager()

    init() {
        #if DEBUG
            manager.trace = true
            manager.logger = { log in
                Logger(label: "AppDIContainer").debug("\(log)")
            }
        #endif
    }
}

extension SharedContainer {
    var appDIContainer: AppDIContainer { AppDIContainer.shared }
}

extension AppDIContainer {
    var db: Factory<Database?> {
        promised()
    }

    var httpClient: Factory<Client?> {
        promised()
    }
    
    var loadEphemeris: Factory<LoadEphemeris> {
        self {
            LoadEphemeris()
        }
    }
}
