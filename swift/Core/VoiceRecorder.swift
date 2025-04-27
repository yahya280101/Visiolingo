//
//  VoiceRecorder.swift
//  Visiolingo
//
//  Created by Syrine Aidani on 26.04.25.
//


import AVFoundation
import Combine

@MainActor
final class VoiceRecorder: ObservableObject {

    enum State {
        case idle
        case recording(URL)
    }

    @Published private(set) var state: State = .idle

    private func makeURL() -> URL {
        let dir  = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let date = ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")
        return dir.appendingPathComponent("\(date).wav")
    }

    private var session  = AVAudioSession.sharedInstance()
    private var recorder: AVAudioRecorder?

    func requestPermission() async -> Bool {
        await withCheckedContinuation { cont in
            session.requestRecordPermission { cont.resume(returning: $0) }
        }
    }

    func start() throws {
        stop()
        
        let url = FileManager.default
                             .temporaryDirectory
                             .appendingPathComponent("\(UUID()).m4a")

        let fmt: [String : Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 32_000
        ]

        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)

        recorder = try AVAudioRecorder(url: url, settings: fmt)
        recorder?.record()

        state = .recording(url)
        print("Started recording → \(url.lastPathComponent)")
    }

    @discardableResult
    func stop() -> URL? {
        guard case let .recording(url) = state else { return nil }

        recorder?.stop()
        recorder  = nil
        try? session.setActive(false)
        state     = .idle

        print("Saved recording  → \(url.lastPathComponent)")
        return url
    }
}
