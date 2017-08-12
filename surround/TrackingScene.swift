//
//  Scene.swift
//  surround
//
//  Created by Serkan Sokmen on 10/08/2017.
//  Copyright © 2017 Serkan Sokmen. All rights reserved.
//

import SpriteKit
import ARKit
import Vision


class TrackingScene: SKScene {

    var model: VNCoreMLModel
    var handler: VNSequenceRequestHandler
    var requests = [VNRequest]()

    init(withModel model: VNCoreMLModel, andSize size: CGSize) {

        self.model = model
        self.handler = VNSequenceRequestHandler()

        super.init(size: size)

        let objectsRequest = VNDetectRectanglesRequest(completionHandler: self.handleDetectedRectangles)
        objectsRequest.minimumSize = 0.1
        objectsRequest.maximumObservations = 20

        self.requests = [objectsRequest]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

    private func handleDetectedRectangles(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            let results = request.results as! [VNObservation]
            print(results)
            // draw rectangles
        }
    }

    override func didMove(to view: SKView) {
        // Setup your scene here
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard let sceneView = self.view as? ARSKView else {
            return
        }

        if let touchLocation = touches.first?.location(in: sceneView) {

            // Add to planes
            if let hit = sceneView.hitTest(touchLocation, types: .featurePoint).first,
                let currentFrame = sceneView.session.currentFrame {

                let translation = matrix_identity_float4x4
                let transform = simd_mul(hit.worldTransform, translation)

                // Add a new anchor to the session
//                let anchor = ARAnchor(transform: transform)
                let classificationRequest = VNCoreMLRequest(model: self.model, completionHandler: { request, error in

                    guard let results = request.results else {
                        print ("No results")
                        return
                    }
                    let result = results.prefix(through: 4)
                        .flatMap { $0 as? VNClassificationObservation }
                        .filter { $0.confidence > 0.3 }
                        .map { $0.identifier }.joined(separator: ", ")
                    // Add a new anchor to the session
                    let anchor = ARAnchor(transform: transform)

                    // Set the identifier
//                    guard result != ARBridge.shared.anchorsToIdentifiers[anchor] else {
//                        return
//                    }

                    DispatchQueue.main.async {
                        sceneView.session.add(anchor: anchor)
//                        ARBridge.shared.anchorsToIdentifiers[anchor] = result
                    }
                })
                classificationRequest.imageCropAndScaleOption = .centerCrop

                DispatchQueue.global(qos: .background).async {
                    try? self.handler.perform(self.requests + [classificationRequest], on: currentFrame.capturedImage)
                }
            }

            //            if let hit = sceneView.hitTest(touchLocation, types: .estimatedHorizontalPlane).first {
            //                let translation = matrix_identity_float4x4
            //                let transform = simd_mul(hit.worldTransform, translation)
            //                let obstacle = ObstacleNode(self.currentObstacle)
            //                obstacle.transform = SCNMatrix4(transform)
            //                obstacle.scale = SCNVector3(0.35, 0.35, 0.35)
            //                sceneView.scene.rootNode.addChildNode(obstacle)
            //            }
        }
    }
}
