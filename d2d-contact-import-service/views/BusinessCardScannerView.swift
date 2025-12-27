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

    func updateUIViewController(
        _ uiViewController: VNDocumentCameraViewController,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanned: onScanned, onCancel: onCancel)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject {

        private let onScanned: (ProspectDraft) -> Void
        private let onCancel: () -> Void

        init(
            onScanned: @escaping (ProspectDraft) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.onScanned = onScanned
            self.onCancel = onCancel
        }

        // MARK: - OCR (Synchronous, Main Thread)

        private func recognizeText(from image: UIImage) -> String {
            guard let cgImage = image.cgImage else { return "" }

            var recognizedText = ""

            let request = VNRecognizeTextRequest { request, _ in
                recognizedText = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n") ?? ""
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])

            return recognizedText
        }
    }
}

// MARK: - Delegate Conformance (Pre-Concurrency)

extension BusinessCardScannerView.Coordinator:
    @preconcurrency VNDocumentCameraViewControllerDelegate {

    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFinishWith scan: VNDocumentCameraScan
    ) {
        controller.dismiss(animated: true)

        guard scan.pageCount > 0 else { return }

        let image = scan.imageOfPage(at: 0)
        let text = recognizeText(from: image)
        let draft = BusinessCardParser.parse(text: text)

        onScanned(draft)
    }

    func documentCameraViewControllerDidCancel(
        _ controller: VNDocumentCameraViewController
    ) {
        controller.dismiss(animated: true)
        onCancel()
    }
}
