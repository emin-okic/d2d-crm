//
//  RecordingManager.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/1/25.
//

import AVFoundation
import SwiftData

class RecordingManager {
    private var recorder: AVAudioRecorder?
    private(set) var currentFileName: String?

    func start() -> (started: Bool, fileName: String?) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print("⚠️ Failed to configure audio session: \(error)")
            return (false, nil)
        }

        let fileName = "Recording_\(Date().timeIntervalSince1970).m4a"
        let url = getURL(for: fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.record()
            currentFileName = fileName
            print("🎙️ Recording to: \(url.path)")
            return (true, fileName)
        } catch {
            print("❌ Failed to start recording: \(error)")
            return (false, nil)
        }
    }

    func stop() {
        recorder?.stop()
    }

    func url(for fileName: String) -> URL? {
        let url = getURL(for: fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func rename(recording: Recording, to newFileName: String) {
        let originalURL = getURL(for: recording.fileName)
        let newURL = getURL(for: newFileName)
        do {
            try FileManager.default.moveItem(at: originalURL, to: newURL)
            recording.fileName = newFileName
        } catch {
            print("❌ Failed to rename file: \(error)")
        }
    }

    func delete(recording: Recording, context: ModelContext) {
        let url = getURL(for: recording.fileName)
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        context.delete(recording)
    }

    private func getURL(for fileName: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
}
