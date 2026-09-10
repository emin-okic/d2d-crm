//
//  RollingRecordingManager.swift
//  d2d-studio
//

import AVFoundation

@MainActor
final class RollingRecordingManager: ObservableObject {
    private var recorder: AVAudioRecorder?
    private var sourceFileName: String?

    var isRecording: Bool {
        recorder?.isRecording == true
    }

    func startIfNeeded() {
        guard !isRecording else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to configure rolling audio session: \(error)")
            return
        }

        let fileName = "RollingRecording_\(Date().timeIntervalSince1970).m4a"
        let url = documentsURL(for: fileName)
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.record()
            sourceFileName = fileName
        } catch {
            print("Failed to start rolling recording: \(error)")
            recorder = nil
            sourceFileName = nil
        }
    }

    func stopAndExportRecentClip(maxDuration: TimeInterval = 600) async -> String? {
        guard let sourceFileName else { return nil }

        recorder?.stop()
        recorder = nil
        self.sourceFileName = nil

        let sourceURL = documentsURL(for: sourceFileName)
        guard FileManager.default.fileExists(atPath: sourceURL.path) else { return nil }

        let outputFileName = "Recording_\(Date().timeIntervalSince1970).m4a"
        let outputURL = documentsURL(for: outputFileName)
        let asset = AVURLAsset(url: sourceURL)
        let assetDuration: CMTime

        do {
            assetDuration = try await asset.load(.duration)
        } catch {
            try? FileManager.default.removeItem(at: sourceURL)
            return nil
        }

        let duration = CMTimeGetSeconds(assetDuration)

        guard duration > 0 else {
            try? FileManager.default.removeItem(at: sourceURL)
            return nil
        }

        let startSeconds = max(0, duration - maxDuration)
        let startTime = CMTime(seconds: startSeconds, preferredTimescale: 600)
        let clipDuration = CMTime(seconds: duration - startSeconds, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startTime, duration: clipDuration)

        let didExport = await export(asset: asset, timeRange: timeRange, to: outputURL)
        try? FileManager.default.removeItem(at: sourceURL)

        return didExport ? outputFileName : nil
    }

    func stopAndDiscard() {
        let fileName = sourceFileName
        recorder?.stop()
        recorder = nil
        sourceFileName = nil

        if let fileName {
            try? FileManager.default.removeItem(at: documentsURL(for: fileName))
        }
    }

    private func export(asset: AVAsset, timeRange: CMTimeRange, to outputURL: URL) async -> Bool {
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            return false
        }

        exportSession.timeRange = timeRange

        do {
            try await exportSession.export(to: outputURL, as: .m4a)
            return true
        } catch {
            print("Failed to export rolling recording clip: \(error)")
            return false
        }
    }

    private func documentsURL(for fileName: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
}
