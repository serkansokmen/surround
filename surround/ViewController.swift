//
//  ViewController.swift
//  surround
//
//  Created by Serkan Sokmen on 10/08/2017.
//  Copyright © 2017 Serkan Sokmen. All rights reserved.
//

import UIKit
import SpriteKit
import Vision
import AVFoundation


class ViewController: UIViewController {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var textView: UITextView!
    
    let session = AVCaptureSession()
    let handler = VNSequenceRequestHandler()
    var requests = [VNRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        startLiveVideo()
        setupDetection()
    }

    override func viewDidLayoutSubviews() {
        imageView.layer.sublayers?[0].frame = imageView.bounds
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    func startLiveVideo() {
        //1
        session.sessionPreset = AVCaptureSession.Preset.photo
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)

        //2
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        session.addInput(deviceInput)
        session.addOutput(deviceOutput)

        //3
        let imageLayer = AVCaptureVideoPreviewLayer(session: session)
        imageLayer.frame = imageView.bounds
        imageView.layer.addSublayer(imageLayer)

        session.startRunning()
    }

    func setupDetection() {

        let objectsRequest = VNDetectRectanglesRequest(completionHandler: self.handleDetectedRectangles)
        objectsRequest.minimumSize = 0.1
        objectsRequest.maximumObservations = 20

        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else { fatalError("Model not found") }
        let classificationRequest = VNCoreMLRequest(model: model, completionHandler: self.handleDetectecRectangles)
        classificationRequest.imageCropAndScaleOption = .centerCrop

        self.requests = [objectsRequest, classificationRequest]
    }

    func handleDetectedRectangles(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            let results = request.results as! [VNRectangleObservation]

            _ = results.filter { $0.confidence > 0.3 }.map { self.highlightRectangle($0) }
        }
    }

    func handleDetectecRectangles(request: VNRequest, error: Error?) {
        guard let results = request.results else {
            print ("No results")
            return
        }
        self.imageView.layer.sublayers?.removeSubrange(1...)
        let result = results.prefix(through: 4)
            .flatMap { $0 as? VNClassificationObservation }
            .filter { $0.confidence > 0.3 }
            .map { $0.identifier }.joined(separator: ", ")

        DispatchQueue.main.async {
            self.textView.text = result
        }
    }

    func highlightRectangle(_ rect: VNRectangleObservation) {

        var maxX: CGFloat = 9999.0
        var minX: CGFloat = 0.0
        var maxY: CGFloat = 9999.0
        var minY: CGFloat = 0.0

        if rect.bottomLeft.x < maxX {
            maxX = rect.bottomLeft.x
        }
        if rect.bottomRight.x > minX {
            minX = rect.bottomRight.x
        }
        if rect.bottomRight.y < maxY {
            maxY = rect.bottomRight.y
        }
        if rect.topRight.y > minY {
            minY = rect.topRight.y
        }

        let xCord = maxX * imageView.frame.size.width
        let yCord = (1 - minY) * imageView.frame.size.height
        let width = (minX - maxX) * imageView.frame.size.width
        let height = (minY - maxY) * imageView.frame.size.height

        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 2.0
        outline.borderColor = UIColor.red.cgColor

        imageView.layer.addSublayer(outline)
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        var requestOptions:[VNImageOption : Any] = [:]

        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }

        DispatchQueue.global(qos: .background).async {
            try? self.handler.perform(self.requests, on: pixelBuffer)
        }
//        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: requestOptions)
//
//        do {
//            try imageRequestHandler.perform(self.requests)
//        } catch {
//            print(error)
//        }
    }
}

