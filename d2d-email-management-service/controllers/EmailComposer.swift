//
//  EmailComposer.swift
//  d2d-studio
//
//  Created by Emin Okic on 1/21/26.
//

import UIKit

enum EmailComposer {
    static func compose(
        to recipient: String,
        subject: String,
        body: String
    ) {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlString = "mailto:\(recipient)?subject=\(encodedSubject)&body=\(encodedBody)"

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}
