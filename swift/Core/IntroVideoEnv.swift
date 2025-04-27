//
//  IntroVideoURLKey.swift
//  Visiolingo
//
//  Created by Syrine Aidani on 26.04.25.
//


import SwiftUI

// MARK: - Custom EnvironmentKey
private struct IntroVideoURLKey: EnvironmentKey {
    static let defaultValue: URL? = nil
}

// MARK: - Convenience accessor
extension EnvironmentValues {
    
    var introVideoURL: URL? {
        get { self[IntroVideoURLKey.self] }
        set { self[IntroVideoURLKey.self] = newValue }
    }
}
