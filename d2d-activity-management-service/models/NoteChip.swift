//
//  NoteChip.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/5/26.
//

import SwiftUI
import SwiftData
import UIKit

struct NoteChip: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let text: String
}
