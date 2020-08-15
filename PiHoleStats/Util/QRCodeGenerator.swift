//
//  QRCodeGenerator.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 02/08/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Cocoa
import CoreImage.CIFilterBuiltins

struct QRCodeGenerator {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()

    func generateQRCode(from string: String, with size: NSSize) -> NSImage {
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return NSImage(cgImage: cgimg, size: size)
            }
        }
        return NSImage()
    }
}
