//
//  Transcriber.swift
//  d2d-map-service
//
//  Created by Emin Okic on 6/29/25.
//
import Speech

class Transcriber {
    func transcribe(url: URL, completion: @escaping (String?) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else {
                print("❌ Speech recognition not authorized")
                completion(nil)
                return
            }

            let recognizer = SFSpeechRecognizer()
            let request = SFSpeechURLRecognitionRequest(url: url)

            recognizer?.recognitionTask(with: request) { result, error in
                if let transcription = result?.bestTranscription.formattedString, result?.isFinal == true {
                    completion(transcription)
                } else if let error = error {
                    print("❌ Transcription error: \(error)")
                    completion(nil)
                }
            }
        }
    }
}
