import XCTest
import AVFoundation
@testable import OllieMoment

class ModelManagerTest: XCTestCase {

    func testPredictSegment() {
        // Create a dummy pixel buffer with allowed dimensions.
        guard let pixelBuffer = createDummyPixelBuffer(width: 640, height: 640) else {
            XCTFail("Failed to create dummy pixel buffer")
            return
        }
        
        // Perform segmentation prediction.
        let boxes = ModelManager.shared.predictSegment(for: pixelBuffer)
        
        // Validate that at least one box is returned and that its label is "person".
        XCTAssertFalse(boxes.isEmpty, "predictSegment should return at least one box")
        XCTAssertEqual(boxes.first?.label, "person", "Box label should be 'person'")
    }
    
    func testPredictSegmentRealVideo() {
        // Use the real video file.
        let videoURL = URL(fileURLWithPath: "/Users/qianshuangbei/Documents/src/OllieMoment/Test.MP4")
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        // Capture one frame at 1 second.
        let time = CMTimeMake(value: 1, timescale: 1)
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let image = UIImage(cgImage: cgImage)
            // Resize the image to 640x640.
            let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 640, height: 640))
            // Save the resized image to disk for manual inspection.
            if let pngData = resizedImage.pngData() {
                let fileURL = URL(fileURLWithPath: "/Users/qianshuangbei/Documents/src/OllieMoment/OllieMoment/Test_Resized.png")
                do {
                    try pngData.write(to: fileURL)
                    print("Resized image saved to \(fileURL.path)")
                } catch {
                    XCTFail("Failed to save resized image: \(error)")
                }
            } else {
                XCTFail("Failed to convert resized image to PNG data")
            }
            // Convert the resized image to a pixel buffer.
            guard let pixelBuffer = pixelBufferFromImage(resizedImage) else {
                XCTFail("Failed to convert UIImage to pixel buffer")
                return
            }
            // Perform segmentation prediction.
            let boxes = ModelManager.shared.predictSegment(for: pixelBuffer)
            // Validate that at least one box is returned and that its label is "person".
            XCTAssertFalse(boxes.isEmpty, "predictSegment should return at least one box")
            XCTAssertEqual(boxes.first?.label, "person", "Box label should be 'person'")
        } catch {
            XCTFail("Failed to extract frame from video: \(error)")
        }
    }
    
    // Helper method to create a dummy pixel buffer.
    private func createDummyPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ] as CFDictionary
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess else { return nil }
        return pixelBuffer
    }
    
    // Helper method to resize a UIImage.
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Determine the scale factor that preserves aspect ratio.
        let scaleFactor = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        
        // Draw the resized image.
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0)
        let x = (targetSize.width - newSize.width) / 2.0
        let y = (targetSize.height - newSize.height) / 2.0
        image.draw(in: CGRect(origin: CGPoint(x: x, y: y), size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    // Helper method to convert UIImage to CVPixelBuffer.
    private func pixelBufferFromImage(_ image: UIImage) -> CVPixelBuffer? {
        guard let cgImage = image.cgImage else { return nil }
        
        let options: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        var pixelBuffer: CVPixelBuffer?
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                         kCVPixelFormatType_32BGRA, options as CFDictionary, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let data = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: width, height: height,
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        guard let ctx = context else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            return nil
        }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}
