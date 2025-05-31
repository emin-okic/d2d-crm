//
//  ProspectsStore.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/30/25.
//

import Foundation
import Combine

class ProspectsStore: ObservableObject {
    static let shared = ProspectsStore()

    @Published var prospects: [Prospect] = []

    private init() {
        loadProspects()
    }

    func loadProspects() {
        let loaded = DatabaseController.shared.getAllProspects()
        DispatchQueue.main.async {
            self.prospects = loaded
        }
    }

    func addProspect(_ prospect: Prospect) {
        DatabaseController.shared.addProspect(uuid: prospect.id, name: prospect.fullName, addr: prospect.address)
        loadProspects()
    }

}
