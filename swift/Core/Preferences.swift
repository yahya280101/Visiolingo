//
//  Preferences.swift
//  Visiolingo
//
//  Created by Syrine Aidani on 26.04.25.
//


import Foundation

struct Preferences: Codable, Equatable, Hashable {
    var name: String
    var language: String
    var level: Level
    var goal: String

    var useNativeAccent: Bool
    var sessionMinutes: Int

    static var `default`: Preferences {
        .init(
            name: "",
            language: "English",
            level: .beginner,
            goal: "General",
            useNativeAccent: true,
            sessionMinutes: 15,
        )
    }
}
