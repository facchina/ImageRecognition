//
//  ViewController.swift
//  ImageRecognition
//
//  Created by Mariana Facchina on 19/05/2018.
//  Copyright © 2018 facchina. All rights reserved.
//

import UIKit
import AVFoundation
import Vision


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setCaptureSession()
        
        view.addSubview(label)
        setupLabel()
    }
    
    func setCaptureSession(){
        /* The AV CaptureSession object handles capture activity and manages
         * the flow of data between input devices (such as the rear camera) and outputs */
        
        //create a new capture session
        let captureSession = AVCaptureSession()
        // search for available capture devices
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices
        
        // setup capture device, add input to our capture session
        do {
            if let captureDevice = availableDevices.first {
                let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
                captureSession.addInput(captureDeviceInput)
            }
        } catch {
            print(error.localizedDescription)
        }
        
//        captureSession.beginConfiguration()
//        //Available capture devices
//        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
//
//        guard
//            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!), captureSession.canAddInput(videoDeviceInput)
//            else { return }
//        //add an input to the capture session
//        captureSession.addInput(videoDeviceInput)
        
        
        /* AVCaptureVideoDataOutput is an output that captures video. It also provides us
         * acess to the frames being captured for processing with a delegate method */
       
        //setup output, add output to our capture session
        let captureOutput = AVCaptureVideoDataOutput()
        captureSession.addOutput(captureOutput)
        
        //add capture session output as a sublayer to the view controller's view
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
        
        captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video Queue"))
    }
    
    // Each time a fram is captured, the delegate is notified by calling captureOutput().
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        //create a VNCoreMLModel with our custom image classifier
        guard let model = try? VNCoreMLModel(for: MyClassifier().model) else {return}
        
        //create our vision request
//        let request = VNCoreMLRequest(model: model) { (finishedRequest, error) in
//
//            guard let results = finishedRequest.results as? [VNClassificationObservation] else { return }
//            guard let Observation = results.first else { return }
//
//            DispatchQueue.main.async(execute: {
//                //update the onscreen UILabel with the identifier returned by our model
//                self.label.text = "\(Observation.identifier)"
//            })
//        }
        let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
            self?.processClassifications(for: request, error: error)
        })
        request.imageCropAndScaleOption = .centerCrop
        //convert the frame passed to us from a CMSampleBUffer to a CVPixerBuffer, because is the formate our model needs for analysis
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // executes request
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.label.text = "Unable to classify image.\n\(error!.localizedDescription)"
                return
            }
            // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
            let classifications = results as! [VNClassificationObservation]
            
            if classifications.isEmpty {
                self.label.text = "Nothing recognized."
            } else {
                // Display top classifications ranked by confidence in the UI.
                let topClassifications = classifications.prefix(2)
                let descriptions = topClassifications.map { classification in
                    // Formats the classification for display; e.g. "(0.37) cliff, drop, drop-off".
                    return String(format: "  (%.2f) %@", classification.confidence, classification.identifier)
                }
                self.label.text = descriptions.joined(separator: "\n")
                self.label.sizeToFit()
                print(descriptions.joined(separator: "\n"))
            }
        }
    }
    func setupLabel() {
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
    }
    //Create a UILabel containing the model's prediction
    let label: UILabel = {
        //create and position it using constraints
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

