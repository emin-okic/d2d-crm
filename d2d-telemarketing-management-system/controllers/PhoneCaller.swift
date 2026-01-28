//
//  PhoneCaller.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/28/26.
//

import Foundation
import UIKit

enum PhoneCaller {
    static func call(_ phone: String) {
        let digits = phone.filter(\.isNumber)
        guard let url = URL(string: "tel://\(digits)") else { return }
        UIApplication.shared.open(url)
    }
}
