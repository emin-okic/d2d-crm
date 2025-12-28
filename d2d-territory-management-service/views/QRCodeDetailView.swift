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
                VStack(spacing: 10) {
                    Text("QR Code")
                        .font(.title)
                    
                    if let qrImage = generateQRCode(from: qrURL) {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width * 0.5,
                                   height: geo.size.height * 0.5) // 50% of sheet height
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
                        .frame(width: geo.size.width * 0.75,
                               height: geo.size.height * 0.25) // 50% of sheet height
                    
                    Spacer()
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .padding()
            }
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
