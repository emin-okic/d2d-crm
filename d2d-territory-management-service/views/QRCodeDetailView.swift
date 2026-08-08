//
//  QRCodeDetailView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/28/25.
//
import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

struct QRCodeDetailView: View {
    @Binding var qrURL: String
    @Binding var sheetDetent: PresentationDetent
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var isEditingURL = false
    @State private var draftURL = ""
    @FocusState private var isURLFieldFocused: Bool

    private let compactSheetDetent = PresentationDetent.fraction(0.58)
    private let editingSheetDetent = PresentationDetent.fraction(0.76)
    private let context = CIContext()

    private var shareMessage: String {
        """
        Here is my digital business card. Scan the QR code or tap the link to save my details:
        \(qrURL)
        """
    }

    private var hasDraftURLChanges: Bool {
        draftURL.trimmingCharacters(in: .whitespacesAndNewlines) != qrURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    backgroundView

                    VStack(spacing: isEditingURL ? 14 : 16) {
                        headerView

                        if let qrImage = generateQRCode(from: qrURL) {
                            qrCodeView(qrImage, size: qrCodeSize(for: geo.size))
                                .contextMenu {
                                    Button {
                                        UIPasteboard.general.image = renderShareCard(qrImage: qrImage)
                                    } label: {
                                        Label("Copy QR Code Image", systemImage: "photo.on.rectangle")
                                    }

                                    Button {
                                        UIPasteboard.general.string = shareMessage
                                    } label: {
                                        Label("Copy Share Text", systemImage: "doc.on.doc")
                                    }
                                }

                            if isEditingURL {
                                urlField
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            actionButtons(for: qrImage)
                        } else {
                            invalidURLView
                            urlField
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 18)
                    .frame(maxWidth: 520)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: shareItems)
            }
            .onAppear {
                draftURL = qrURL
                sheetDetent = compactSheetDetent
            }
        }
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color.blue.opacity(0.08),
                Color(.secondarySystemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var headerView: some View {
        HStack(spacing: 14) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.blue.gradient)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Share QR Code")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                Text("Send the code and a ready-to-use message")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 0)
        }
    }

    private func qrCodeView(_ image: UIImage, size: CGFloat) -> some View {
        let imagePadding: CGFloat = isEditingURL ? 10 : 18
        let imageCornerRadius: CGFloat = isEditingURL ? 18 : 24
        let cardPadding: CGFloat = isEditingURL ? 12 : 18
        let cardCornerRadius: CGFloat = isEditingURL ? 22 : 28

        return VStack(spacing: isEditingURL ? 0 : 14) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .padding(imagePadding)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: imageCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: imageCornerRadius, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )

            if !isEditingURL {
                VStack(spacing: 6) {
                    Text("Share your card")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Scan the QR code or use the link to save my details.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(qrURL)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(cardPadding)
        .background(
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 14)
    }

    private func actionButtons(for qrImage: UIImage) -> some View {
        HStack(spacing: 12) {
            if isEditingURL {
                if hasDraftURLChanges {
                    Button {
                        revertURLEdit()
                    } label: {
                        Label("Revert", systemImage: "arrow.uturn.backward")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }

                Button {
                    saveURLEdit()
                } label: {
                    Label("Save", systemImage: "checkmark")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(Color.blue.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                Button {
                    beginURLEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.blue.opacity(0.18), lineWidth: 1)
                )

                Button {
                    ContactScreenHapticsController.shared.successConfirmationTap()
                    ContactScreenSoundController.shared.playSound1()
                    isURLFieldFocused = false
                    shareItems = [shareMessage, renderShareCard(qrImage: qrImage)]
                    showShareSheet = true
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(Color.blue.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func beginURLEdit() {
        ContactScreenHapticsController.shared.lightTap()
        draftURL = qrURL
        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
            isEditingURL = true
            sheetDetent = editingSheetDetent
        }
        isURLFieldFocused = false
    }

    private func saveURLEdit() {
        ContactScreenHapticsController.shared.successConfirmationTap()
        ContactScreenSoundController.shared.playSound1()
        qrURL = draftURL.trimmingCharacters(in: .whitespacesAndNewlines)
        closeURLEditor()
    }

    private func revertURLEdit() {
        ContactScreenHapticsController.shared.lightTap()
        draftURL = qrURL
        isURLFieldFocused = false
    }

    private func closeURLEditor() {
        isURLFieldFocused = false
        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
            isEditingURL = false
            sheetDetent = compactSheetDetent
        }
    }

    private var invalidURLView: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.orange)

            Text("Invalid URL")
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    private var urlField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Edit URL", systemImage: "pencil")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Image(systemName: "link")
                    .foregroundStyle(.secondary)

                TextField("Enter URL", text: $draftURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .submitLabel(.done)
                    .focused($isURLFieldFocused)
                    .onSubmit {
                        isURLFieldFocused = false
                    }
            }
            .font(.body)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }

    private func qrCodeSize(for sheetSize: CGSize) -> CGFloat {
        let maxSize: CGFloat = isEditingURL ? 132 : 150
        return min(sheetSize.width * 0.44, maxSize)
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")

        guard let outputImage = filter.outputImage else { return nil }

        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            return UIImage(cgImage: cgImage)
        }

        return nil
    }

    private func renderShareCard(qrImage: UIImage) -> UIImage {
        let canvasSize = CGSize(width: 900, height: 1120)
        let renderer = UIGraphicsImageRenderer(size: canvasSize)

        return renderer.image { rendererContext in
            let cgContext = rendererContext.cgContext
            UIColor.systemBlue.setFill()
            cgContext.fill(CGRect(origin: .zero, size: canvasSize))

            let accentRect = CGRect(x: 0, y: 555, width: canvasSize.width, height: 150)
            UIColor(red: 0.10, green: 0.30, blue: 1.00, alpha: 1.00).setFill()
            cgContext.fill(accentRect)

            drawText(
                "Share your card",
                in: CGRect(x: 82, y: 82, width: 736, height: 110),
                font: .systemFont(ofSize: 56, weight: .bold),
                color: .white,
                alignment: .center
            )

            let cardRect = CGRect(x: 100, y: 245, width: 700, height: 750)
            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 44)
            UIColor.white.setFill()
            cardPath.fill()

            let qrRect = CGRect(x: 250, y: 165, width: 400, height: 400)
            let qrBackgroundRect = qrRect.insetBy(dx: -28, dy: -28)
            let qrBackgroundPath = UIBezierPath(roundedRect: qrBackgroundRect, cornerRadius: 38)
            UIColor.white.setFill()
            qrBackgroundPath.fill()

            UIColor.black.withAlphaComponent(0.12).setStroke()
            qrBackgroundPath.lineWidth = 2
            qrBackgroundPath.stroke()

            qrImage.draw(in: qrRect)

            drawText(
                "Scan my QR code",
                in: CGRect(x: 150, y: 650, width: 600, height: 58),
                font: .systemFont(ofSize: 38, weight: .semibold),
                color: .black,
                alignment: .center
            )

            drawText(
                "Open the camera, scan this code, or tap the link in my message to save my details.",
                in: CGRect(x: 170, y: 720, width: 560, height: 130),
                font: .systemFont(ofSize: 26, weight: .regular),
                color: UIColor.black.withAlphaComponent(0.72),
                alignment: .center
            )

            drawText(
                qrURL,
                in: CGRect(x: 160, y: 882, width: 580, height: 40),
                font: .systemFont(ofSize: 20, weight: .medium),
                color: .systemBlue,
                alignment: .center
            )
        }
    }

    private func drawText(_ text: String, in rect: CGRect, font: UIFont, color: UIColor, alignment: NSTextAlignment) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byTruncatingMiddle

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]

        text.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
    }
}
