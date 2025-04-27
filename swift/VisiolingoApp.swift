//
//  VisiolingoApp.swift
//  VisiolingoApp
//

import SwiftUI

@main
@MainActor
struct VisiolingoApp: App {
    
    public static let homeView = "homeView"
    public static let culturalImmersive = "culturalImmersive"
    public static let avatarView = "avatarView"
    
    @State private var hasSeenOnboarding = false

    
    @State var headsetPositionManager = HeadsetPositionManager()
    
    @State private var introURL: URL?
    @State private var recorder = VoiceRecorder()

    
    var body: some Scene {
        WindowGroup (id: Self.homeView){
            if hasSeenOnboarding {
                ConversationSetupView(introURL: $introURL)
            } else {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
            }
        }
        .defaultSize(width: 1200, height: 1000)
        
        ImmersiveSpace(id: Self.culturalImmersive) {
            ImmersiveCulturalView()
                .environmentObject(recorder)
        }
        

        ImmersiveSpace(id: Self.avatarView) {
            AvatarView()
        }
        .environment(\.introVideoURL, introURL)
        .windowStyle(.volumetric)
        .defaultSize(width: 3, height: 5, depth: 1, in: .meters)
        
    }
}
