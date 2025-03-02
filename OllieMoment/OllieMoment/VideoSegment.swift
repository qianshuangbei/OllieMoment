//
//  VideoSegment.swift
//  Test
//
//  Created by 钱双贝 on 2025/2/26.
//

import Foundation
import UIKit
import AVFoundation

struct Segment {
    var startTime: Double
    var endTime: Double
    var favorite: Bool = false
}

class VideoSegmentProcessor {
    let modelManager = ModelManager.shared


    public func averageSegmentVideo(videoURL: URL) throws -> [Segment] {
        let asset = AVAsset(url: videoURL)
        let duration = asset.duration // Removed async call
        let totalDuration = CMTimeGetSeconds(duration)
        var segments = [Segment]()
        var startTime: Double = 0
        while startTime < totalDuration {
            let endTime = min(startTime + 1.0, totalDuration)
            segments.append(Segment(startTime: startTime, endTime: endTime))
            startTime += 1.0
        }
        return segments
    }
    
    public func sampleFrames(from videoURL: URL) -> [CVPixelBuffer] {
        var buffers = [CVPixelBuffer]()
        let asset = AVAsset(url: videoURL)
        guard let track = asset.tracks(withMediaType: .video).first else { return buffers }
        guard let assetReader = try? AVAssetReader(asset: asset) else { return buffers }
        let readerOutputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: readerOutputSettings)
        trackOutput.alwaysCopiesSampleData = false
        assetReader.add(trackOutput)
        let frameRate = 3.0
        let frameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
        var nextCaptureTime = CMTime.zero
        assetReader.startReading()
        while let sampleBuffer = trackOutput.copyNextSampleBuffer() {
            let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            if currentTime >= nextCaptureTime {
                if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                    buffers.append(imageBuffer)
                }
                nextCaptureTime = CMTimeAdd(nextCaptureTime, frameDuration)
            }
        }
        return buffers
    }

    // 辅助函数：对给定Box区域进行放大20%
    public func enlargedRegion(from frame: UIImage, for box: Box, scale: CGFloat = 1.2) -> UIImage {
        let rect = box.rect
        let newWidth = rect.width * scale
        let newHeight = rect.height * scale
        let newX = rect.midX - newWidth / 2
        let newY = rect.midY - newHeight / 2
        let enlargedRect = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
        
        // 确保放大区域不超过原图范围
        let imageRect = CGRect(origin: .zero, size: frame.size)
        let cropRect = enlargedRect.intersection(imageRect)
        
        if let cgImage = frame.cgImage,
        let croppedCGImage = cgImage.cropping(to: cropRect) {
            return UIImage(cgImage: croppedCGImage)
        }
        return frame
    }

    // 分析视频：逐帧采样并对每帧应用模型预测
    public func analyzeVideo(at videoURL: URL) throws -> [Int: String] {
        var results = [Int: String]()
        let frames = sampleFrames(from: videoURL)
        for (index, frame) in frames.enumerated() {
            // 调用Model.swift中的predictSegment函数进行分割预测
            let boxes = try modelManager.predictSegment(for: frame)
            // 筛选标签为 "person" 的 seg box
            let personBoxes = boxes.filter { $0.label == "person" }
            results[index] = personBoxes.description
        }
        return results
    }

    // 总控制函数：将视频处理与模型预测串联起来
    public func ImageModelProcess(videoURL: URL) -> [Segment] {
        do {
            return try averageSegmentVideo(videoURL: videoURL)
        } catch {
            print("Error: \(error)")
            return []
        }
        
    }
    
    static func exportVideoSegment(asset: AVAsset, startTime: Double, duration: Double, outputURL: URL) async throws {
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset,
                                                     presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "VideoExport", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create export session"])
        }
        
        let startCMTime = CMTime(seconds: startTime, preferredTimescale: 600)
        let durationCMTime = CMTime(seconds: duration, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startCMTime, duration: durationCMTime)
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.timeRange = timeRange
        
        return try await withCheckedThrowingContinuation { continuation in
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume()
                case .failed:
                    continuation.resume(throwing: exportSession.error ?? NSError(domain: "VideoExport", code: -1))
                case .cancelled:
                    continuation.resume(throwing: NSError(domain: "VideoExport", code: -2))
                default:
                    continuation.resume(throwing: NSError(domain: "VideoExport", code: -3))
                }
            }
        }
    }
}
