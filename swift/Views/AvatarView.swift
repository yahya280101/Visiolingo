//
//  FindADinoView.swift
//  Dinopedia
//
//  Created by Syrine Aidani on 26.04.25.
//

import SwiftUI
import AVKit

struct AvatarView: View {
    @State private var player: AVPlayer = {
        guard let url = Bundle.main.url(forResource: "output31", withExtension: "mp4") else {
            fatalError("demo.mp4 not found in app bundle")
        }
        return AVPlayer(url: url)
    }()
    
    @State private var isRecording = false
    @State private var uploading   = false
    
    @EnvironmentObject private var recorder: VoiceRecorder
    @Environment(\.introVideoURL) private var introURL


    var body: some View {
        VStack(spacing: 16) {
            VideoPlayer(player: player)
                .onAppear { player.play() }   // autostart when the window appears
                .onDisappear { player.pause() }
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 0.02, style: .continuous))
                .padding()
            
            HStack(spacing: 30) {
                // Start
                Button {
                    try? recorder.start()
                    isRecording = true
                } label: {
                    Label("Start", systemImage: "mic.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(isRecording || uploading)
                
                // Stop
                Button {
                    if let file = recorder.stop() {
                        isRecording = false
                        uploading = true
                        Task {
                            //await upload(file)
                            try await NetworkUtil.instance.sendAudio(file)
                            uploading = false
                        }
                    }
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(!isRecording)

            }

            if uploading {
                ProgressView("Sending…")
            }
        }
        .padding()
        
    }
    
    private func upload(_ url: URL) async {
            print("⬆️  uploading \(url.lastPathComponent)…")
            try? await Task.sleep(for: .seconds(2))          // pretend latency
            print("✅ backend replied, ready for next turn")
        }

}
