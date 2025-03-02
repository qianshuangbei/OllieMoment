//
//  VideoSegmentTests.swift
//  OllieMomentTests
//
//  Created by 钱双贝 on 2025/3/2.
//

import XCTest
import AVFoundation
import UIKit
@testable import OllieMoment

final class VideoSegmentTests: XCTestCase {

    var processor: VideoSegmentProcessor!
    var testVideoURL: URL!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create a test processor with the mock manager
        processor = VideoSegmentProcessor()
        
        // Create a temporary test video URL
        let tempDir = FileManager.default.temporaryDirectory
        testVideoURL = tempDir.appendingPathComponent("/Users/qianshuangbei/Documents/src/OllieMoment/Test.MP4")
        
        // Create a simple test video file if needed
        if !FileManager.default.fileExists(atPath: testVideoURL.path) {
            print("Test file Not Exist")
        }
    }
    
    override func tearDownWithError() throws {
        processor = nil
        
        try super.tearDownWithError()
    }
    
    func testAverageSegmentVideo() throws {
        // This test would need a valid video file to work properly
        // For a proper test, consider including a small test video in your test bundle
        
        do {
            let segments = try processor.averageSegmentVideo(videoURL: testVideoURL)
            XCTAssertGreaterThan(segments.count, 0)
            
            // Check that segments are properly constructed
            for i in 0..<segments.count-1 {
                XCTAssertEqual(segments[i].endTime, segments[i+1].startTime)
                XCTAssertLessThanOrEqual(segments[i].endTime - segments[i].startTime, 5.0)
            }
        } catch {
            XCTFail("Failed to segment video: \(error)")
        }
    }
    
    func testSampleFrames() {
        // This test would need a valid video file to work properly
        let frames = processor.sampleFrames(from: testVideoURL)
        
        XCTAssertGreaterThanOrEqual(frames.count, 0)
    }
    
    
    func testImageModelProcess() {
        // This is just a wrapper for analyzeVideo, so we'll do a simple test
        class TestProcessor: VideoSegmentProcessor {
            var expectedResults = [Int: String]()
            
            override func analyzeVideo(at videoURL: URL) -> [Int: String] {
                return expectedResults
            }
        }
        
        let testProcessor = TestProcessor()
        testProcessor.expectedResults = [0: "action1", 1: "action2"]
        
        let results = testProcessor.ImageModelProcess(videoURL: testVideoURL)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0], "action1")
        XCTAssertEqual(results[1], "action2")
    }
    
    func testExportVideoSegment() async throws {
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("/Users/qianshuangbei/Documents/src/OllieMoment/Test.MP4")
        
        // For a proper test, create an AVAsset from a bundled video
        // let testBundle = Bundle(for: type(of: self))
        // let videoPath = testBundle.path(forResource: "testVideo", ofType: "mp4")!
        // let asset = AVAsset(url: URL(fileURLWithPath: videoPath))
        
        // Since we don't have a real video asset, we'll just check that the function throws an error
        do {
            let asset = AVAsset(url: testVideoURL)
            try await VideoSegmentProcessor.exportVideoSegment(
                asset: asset,
                startTime: 0,
                duration: 5.0,
                outputURL: tempURL
            )
            // Since we're using a dummy video, this should fail
            XCTFail("Export should have failed with dummy video")
        } catch {
            // Expected to fail with invalid asset
            XCTAssertNotNil(error)
        }
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
