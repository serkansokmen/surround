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


class Scene: SKScene {

    var model: VNCoreMLModel?
    var handler = VNSequenceRequestHandler()

    override func didMove(to view: SKView) {
        // Setup your scene here

        self.model = try? VNCoreMLModel(for: Inceptionv3().model)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard let sceneView = self.view as? ARSKView else {
            return
        }

        if let touchLocation = touches.first?.location(in: sceneView),
            let model = self.model {

            // Add to planes
            if let hit = sceneView.hitTest(touchLocation, types: .featurePoint).first,
                let currentFrame = sceneView.session.currentFrame {

                let translation = matrix_identity_float4x4
                let transform = simd_mul(hit.worldTransform, translation)

                // Add a new anchor to the session
                let anchor = ARAnchor(transform: transform)
                let request = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
                    DispatchQueue.main.async {
                        //                print(request.results)

                        guard let results = request.results as? [VNClassificationObservation],
                            let result = results.first else {
                                print ("No results")
                                return
                        }

                        // Add a new anchor to the session
                        let anchor = ARAnchor(transform: transform)

                        // Set the identifier
                        guard result.identifier != ARBridge.shared.anchorsToIdentifiers[anchor] else {
                            return
                        }
                        ARBridge.shared.anchorsToIdentifiers[anchor] = result.identifier
                        sceneView.session.add(anchor: anchor)
                    }
                })
                DispatchQueue.global(qos: .background).async {
                    try? self.handler.perform([request], on: currentFrame.capturedImage)
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
