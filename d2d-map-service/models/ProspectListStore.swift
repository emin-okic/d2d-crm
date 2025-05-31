//
//  ProspectListStore.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//
import Foundation

class ProspectListStore: ObservableObject {
    @Published var allLists: [String] = ["Default"]
    @Published var selectedList: String = "Default"
}
