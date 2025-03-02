import Foundation
import UIKit
import CoreML

public struct Box {
    public let rect: CGRect
    public let label: String
}

class ModelManager {
    static let shared = ModelManager()
    let segModel = try? yolo11sseg()
    let poseModel = try? yolo11npose()
    
    private init() {
    }

    public func predictSegment(for frame: CVPixelBuffer) -> [Box] {
        do {
            let prediction = try segModel?.prediction(image: frame)
            // Dummy implementation: return a box covering the entire frame with label "person"
            return [Box(rect: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(frame),
                                      height: CVPixelBufferGetHeight(frame)), label: "person")]
        } catch {
            print(error)
            return []
        }
    }

    public func predictPose(for region: UIImage) -> [Float] {
        // 调用yolo11npose模型预测，返回dummy数据，共34个浮点数，后续请替换成实际模型调用
        return [Float](repeating: 0.1, count: 34)
    }

    public func predictCls(for poseData: [[Float]]) -> String {
        // 调用cls模型进行分类预测，返回dummy结果，后续请替换成实际模型调用
        return "cls_result_dummy"
    }
}
