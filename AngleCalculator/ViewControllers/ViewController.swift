//
//  ViewController.swift
//  AngleCalculator
//
//  Created by Tushar Gusain on 18/02/20.
//  Copyright © 2020 Hot Cocoa Software. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    //MARK:- IBOutlets
    
    @IBOutlet var drawView: DrawView! {
        didSet {
            drawView.delegate = self
        }
    }
    
    //MARK:- Property Variables
    
    private let defaultName = "Guest"
    private var isLoading: Bool = true
    
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let nameLayer = CATextLayer()
    private let dataOutputQueue = DispatchQueue(
        label: "video data queue",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem)
    
    private var nameTag = "Guest" {
        didSet {
            nameLayer.string = nameTag
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCaptureSession()

        nameLayer.string = nameTag
        nameLayer.foregroundColor = .init(srgbRed: 0, green: 255, blue: 0, alpha: 1)
        nameLayer.alignmentMode = .center
        nameLayer.fontSize = 22
        
        view.isOpaque = false

        session.startRunning()
    }


}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate and Video Processing methods

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func configureCaptureSession() {
        //// Define the capture device we want to use
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .front) else {
                                                    fatalError("No front video camera available")
        }
        
        //// Connect the camera to the capture session input
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            session.addInput(cameraInput)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        //// Create the video data output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        ////  Add the video output to the capture session
        session.addOutput(videoOutput)
        
        let videoConnection = videoOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
        
        ////  Configure the preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        previewLayer.bounds = view.frame
        
        view.layer.insertSublayer(previewLayer, at: 0)
    }
    
    func convert(cmage:CIImage) -> UIImage {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let ciimage : CIImage = CIImage(cvPixelBuffer: imageBuffer)
        let image = self.convert(cmage: ciimage)
    }
}

//MARK:- DrawView delgate Methods

extension ViewController: DrawViewAngleDelegate {
    
    func showAngle(point: CGPoint?, angle: CGFloat?) {
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.nameLayer.removeFromSuperlayer()
            
            if let _point = point, let _angle = angle {
                self.nameTag = "\(String(format: "%.2f", _angle))º"
                self.nameLayer.frame = CGRect(x: _point.x, y: _point.y, width: 80, height: 40)
                self.drawView.layer.addSublayer(self.nameLayer)
            }
        }
    }
}
