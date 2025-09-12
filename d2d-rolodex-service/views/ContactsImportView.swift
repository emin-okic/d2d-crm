//
//  ContactsImportView.swift
//  d2d-studio
//
//  Created by Emin Okic on 9/12/25.
//


import SwiftUI
import ContactsUI

struct ContactsImportView: UIViewControllerRepresentable {
    let onComplete: ([CNContact]) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactsImportView

        init(_ parent: ContactsImportView) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.onComplete([contact]) // ✅ fixed here
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.onCancel()
        }
    }
}
