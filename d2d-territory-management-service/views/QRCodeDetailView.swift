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
    @State private var generator = CIFilter.qrCodeGenerator()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Edit QR Code URL")
                    .font(.headline)
                
                TextField("Enter URL", text: $qrURL)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
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
                
                Spacer()
            }
            .padding()
            .navigationTitle("QR Code")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        generator.setValue(data, forKey: "inputMessage")
        
        if let outputImage = generator.outputImage {
            let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
            return UIImage(ciImage: scaled)
        }
        return nil
    }
}
