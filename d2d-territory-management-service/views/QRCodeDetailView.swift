//
//  QRCodeDetailView.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/28/25.
//
import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeDetailView: View {
    @Binding var qrURL: String
    private let context = CIContext()

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    backgroundView

                    VStack(spacing: 18) {
                        headerView

                        if let qrImage = generateQRCode(from: qrURL) {
                            qrCodeView(qrImage, size: qrCodeSize(for: geo.size))
                                .contextMenu {
                                    Button {
                                        UIPasteboard.general.string = qrURL
                                    } label: {
                                        Label("Copy QR Code URL", systemImage: "doc.on.doc")
                                    }
                                }
                        } else {
                            invalidURLView
                        }

                        urlField
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 520)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
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
                Text("QR Code")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                Text("Long press the code to copy its URL")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 0)
        }
    }

    private func qrCodeView(_ image: UIImage, size: CGFloat) -> some View {
        VStack(spacing: 14) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .padding(18)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )

            Text(qrURL)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 14)
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
        HStack(spacing: 10) {
            Image(systemName: "link")
                .foregroundStyle(.secondary)

            TextField("Enter URL", text: $qrURL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
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

    private func qrCodeSize(for sheetSize: CGSize) -> CGFloat {
        min(sheetSize.width * 0.48, sheetSize.height * 0.34, 220)
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        guard let outputImage = filter.outputImage else { return nil }
        
        // Scale the image
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        // Render with CIContext to CGImage
        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return nil
    }
}
