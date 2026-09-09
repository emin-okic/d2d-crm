//
//  ContactRecordingRow.swift
//  d2d-studio
//
//  Created by Codex on 9/9/26.
//

import SwiftUI

struct ContactRecordingRow: View {
    let recording: Recording
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(recording.date.formatted(date: .abbreviated, time: .shortened))
                    
                    if let rating = recording.rating {
                        Text("\(rating)/5")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}
