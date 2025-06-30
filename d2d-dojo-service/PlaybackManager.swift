//
//  PlaybackManager.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//


import SwiftUI
import AVFoundation

class PlaybackManager {
    private var player: AVAudioPlayer?
    
    func toggle(fileName: String, currentlyPlayingFile: Binding<String?>) {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)

        if currentlyPlayingFile.wrappedValue == fileName {
            player?.stop()
            currentlyPlayingFile.wrappedValue = nil
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
            currentlyPlayingFile.wrappedValue = fileName
        } catch {
            print("❌ Failed to play: \(error)")
        }
    }
}