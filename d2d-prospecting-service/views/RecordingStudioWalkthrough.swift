//
//  RecordingStudioWalkthrough.swift
//  d2d-studio
//
//  Created by Emin Okic on 8/8/25.
//
import SwiftUI

struct RecordingStudioWalkthrough: View {
    var onDone: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Image
                Image(systemName: "mic.and.signal.meter.fill")
                    .font(.system(size: 72))
                    .minimumScaleFactor(0.8)

                // Headline (from part 1)
                Text("Start a Session")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)

                // Subheadline (from part 2)
                Text("Auto Transcribe & Score")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)

                // Description (combine all details, incl. part 3)
                Text("Pick an objection, tap record, and practice your pitch.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal)
                    .minimumScaleFactor(0.8)
                     
                     // Description (combine all details, incl. part 3)
                     Text("We compare your words to best-in-class responses.")
                         .font(.callout)
                         .foregroundColor(.secondary)
                         .multilineTextAlignment(.center)
                         .lineSpacing(3)
                         .padding(.horizontal)
                         .minimumScaleFactor(0.8)
                          
                          // Description (combine all details, incl. part 3)
                          Text("Play back calls, rename, and track your progress.")
                              .font(.callout)
                              .foregroundColor(.secondary)
                              .multilineTextAlignment(.center)
                              .lineSpacing(3)
                              .padding(.horizontal)
                              .minimumScaleFactor(0.8)

                Spacer(minLength: 0)

                Button(action: onDone) {
                    Text("Got it")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
            .navigationTitle("Quick Tour")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
