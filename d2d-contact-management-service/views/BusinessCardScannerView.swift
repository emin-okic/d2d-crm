//
//  BusinessCardScannerView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/27/25.
//


import SwiftUI
import VisionKit
import Vision

struct BusinessCardScannerView: UIViewControllerRepresentable {

    let onScanned: (ProspectDraft) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {

        let parent: BusinessCardScannerView

        init(_ parent: BusinessCardScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            controller.dismiss(animated: true)

            guard scan.pageCount > 0 else { return }

            let image = scan.imageOfPage(at: 0)
            recognizeText(from: image)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
            parent.onCancel()
        }

        private func recognizeText(from image: UIImage) {
            guard let cgImage = image.cgImage else { return }

            let request = VNRecognizeTextRequest { request, _ in
                let text = request.results?
                    .compactMap { $0 as? VNRecognizedTextObservation }
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n") ?? ""

                let draft = BusinessCardParser.parse(text: text)
                DispatchQueue.main.async {
                    // self.parent.onScanned(draft)
                }
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }
}
