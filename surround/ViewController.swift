//
//  ViewController.swift
//  surround
//
//  Created by Serkan Sokmen on 10/08/2017.
//  Copyright © 2017 Serkan Sokmen. All rights reserved.
//

import UIKit
import SpriteKit
import ARKit
import Vision


class ViewController: UIViewController, ARSKViewDelegate {

    @IBOutlet var sceneView: ARSKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and node count
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true

        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else { fatalError("Model not found") }
        let scene = TrackingScene(withModel: model, andSize: self.view.frame.size)
        sceneView.presentScene(scene)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {

        guard let identifier = ARBridge.shared.anchorsToIdentifiers[anchor] else {
            return nil
        }

        let labelNode = SKLabelNode(text: identifier)
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.preferredMaxLayoutWidth = 240
        labelNode.numberOfLines = 0
        labelNode.lineBreakMode = .byWordWrapping
        labelNode.fontName = UIFont.boldSystemFont(ofSize: 12).fontName
        return labelNode
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print(camera.trackingState)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

