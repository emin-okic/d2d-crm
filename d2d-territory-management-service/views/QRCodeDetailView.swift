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
            VStack(spacing: 20) {
                Text("QR Code")
                    .font(.headline)
                
                if let qrImage = generateQRCode(from: qrURL) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .shadow(radius: 4)
                        .contextMenu {
                            Button("Copy QR Code URL") {
                                UIPasteboard.general.string = qrURL
                            }
                        }
                } else {
                    Text("Invalid URL")
                        .foregroundColor(.red)
                }
                
                TextField("Enter URL", text: $qrURL)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .frame(width: 300, height: 200)
                
                Spacer()
            }
            .padding()
        }
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
