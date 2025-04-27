//
//  NetworkUtil.swift
//  Visiolingo
//
//  Created by Syrine Aidani on 26.04.25.
//


import RealityKit
import Foundation
import UIKit

class NetworkUtil {
    private var session = URLSession.shared
    static let instance = NetworkUtil()
    
    let baseURL: String = "http://127.0.0.1:8000"
    
    private init () {}
    
    func ping() async {
        guard let url = URL(string: "\(baseURL)") else {
            return
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            let (data, _) = try await self.session.data(for: request)
            print(data)
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    func getImage(prefs: Preferences) async throws -> URL {
        let encoder = JSONEncoder()
        guard let bodyData = try? encoder.encode(prefs) else {
            throw URLError(.cannotDecodeContentData)
        }

        // 2. Build the request
        guard let url = URL(string: "\(baseURL)/hello") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = bodyData

        let (data, response) = try await self.session.data(for: req)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let dest = FileManager.default.temporaryDirectory
                     .appendingPathComponent(UUID().uuidString + ".png")
        try data.write(to: dest)
        print("intro video saved to \(dest.path)")
        print("Background image saved to \(dest.path)")

        return dest
    }
    
    func getVideo() async throws -> URL {
        guard let url = URL(string: "\(baseURL)/video") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await self.session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let dest = FileManager.default.temporaryDirectory
                     .appendingPathComponent(UUID().uuidString + ".mp4")
        try data.write(to: dest)
        print("intro video saved → \(dest.path)")
        print("Background image saved to \(dest.path)")

        return dest
    }
    
    
    func sendAudio(_ srcURL: URL) async throws -> URL {
        guard let url = URL(string: "\(baseURL)/uploadAudio") else {
            throw URLError(.badURL,
                           userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"

        let boundary = "----\(UUID())"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func add(_ s: String) { body.append(s.data(using: .utf8)!) }

        add("--\(boundary)\r\n")
        add("Content-Disposition: form-data; name=\"file\"; filename=\"\(srcURL.lastPathComponent)\"\r\n")
        add("Content-Type: audio/m4a\r\n\r\n")
        body.append(try Data(contentsOf: srcURL))
        add("\r\n--\(boundary)--\r\n")

        let (videoData, _) = try await URLSession.shared.upload(for: req, from: body)

        let dest = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        try videoData.write(to: dest)
        return dest
    }

}
