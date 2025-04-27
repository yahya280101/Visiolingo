//
//  ConversationSetupView.swift
//  Dinopedia
//
//  Created by Syrine Aidani on 26.04.25.
//

import SwiftUI

@MainActor
struct ConversationSetupView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    // Gradient animation
        @State private var pulse             = false
        private let gradientColors: [Color]  = [Color.yellow, Color.green, Color.cyan, Color.purple]

    
    @State private var name: String = ""
    @State private var language = "English"
    @State private var level: Level = .beginner
    @State private var showAlert = false
    
    
    @State private var goal              = "Travel"
    @State private var accent            = "Neutral"
    @State private var sessionLength     = 15.0
    @State private var remindersEnabled  = true
    @State private var sessionsPerWeek   = 3
    @State private var useNativeAccent   = true
    
    private let languages   = ["English", "Spanish", "German", "French", "Arabic", "Japanese", "Chinese", "Portuguese", "Russian"]
    
    
    @Binding var introURL: URL?
    @State private var loading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .center ,spacing: 28) {
                Spacer()

                Text("Set up your learning profile ✍️")
                    .font(.title).bold()
                    .padding(.top, 100)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your name")
                    TextField("Alex", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                .frame(maxWidth: 420)
                
                HStack {
                    Text("Target language")
                    Spacer()
                    Picker("Target language", selection: $language) {
                        ForEach(languages, id: \ .self) { Text($0) }
                    }
                    .pickerStyle(.automatic)
                }
                .frame(maxWidth: 420)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current level")
                    Picker("Level", selection: $level) {
                        ForEach(Level.allCases, id: \ .self) { Text($0.rawValue.capitalized) }
                    }
                    .pickerStyle(.segmented)
                }
                .frame(maxWidth: 420)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Why are you learning?")
                    TextField("Travel, work, exam prep…", text: $goal)
                        .textFieldStyle(.roundedBorder)
                }
                .frame(maxWidth: 420)
                
                Toggle(isOn: $useNativeAccent) {
                    Text("Use native accent pronunciation")
                }
                .toggleStyle(.switch)
                .frame(maxWidth: 420)

                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session length: \(Int(sessionLength)) min")
                    Slider(value: $sessionLength, in: 5...60, step: 5)
                }
                .frame(maxWidth: 420)
                
                Spacer()
                
                Button(action: startSession) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Start immersive conversation")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: 320, maxHeight: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .hueRotation(.degrees(pulse ? 15 : -15))
                    )
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        pulse.toggle()
                    }
                }
                .alert("Please enter your name", isPresented: $showAlert) {}
            }
            .padding(40)
        }
        .overlay { if loading { ProgressView("Fetching video…") } }
                    .disabled(loading)
    }
    
    private func startSession() {
            guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { showAlert = true; return }
        loading = true

        let prefs = Preferences(name: name,
                               language: language,
                               level: level,
                               goal: goal,
                               useNativeAccent: useNativeAccent,
                               sessionMinutes: Int(sessionLength))

       Task {
           do {
               /// uncomment if server is availble
               //let url = try await NetworkUtil.instance.getImage(prefs: prefs)
               loading  = false
               await openSpace(id: VisiolingoApp.culturalImmersive)
           } catch {
               loading = false
               print("❌", error.localizedDescription)
           }
       }
           
    }
    
    func openSpace(id: String) async {
        await dismissImmersiveSpace()
        
        switch await openImmersiveSpace(id: id) {
        case .opened:
            print("Immersive space \(id) successfully opened")
        case .error:
            fatalError("Error opening immersive space with id: \(id)")
        case .userCancelled:
            print("User cancelled")
        default:
            break
        }
    }
}

