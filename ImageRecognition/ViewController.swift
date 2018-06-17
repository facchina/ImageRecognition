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
    
    @IBOutlet weak var timerLbl: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var userChoiceImg: UIImageView!
    @IBOutlet weak var computerChoiceImg: UIImageView!

    @IBOutlet weak var machineLearning: UILabel!
    var jogadas = ["Pedra", "Papel", "Tesoura"]
    var jokenpoWords = ["JO", "KEN", "PO!"]
    var myTimer = Timer()
    var time = 0
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var play = false
    var imageClassifierResult : String!
    var playerChoice: String!
    var computerChoice : String!
    
    var player: AVAudioPlayer?
    var winner : Int!
    override func viewDidLoad() {
        super.viewDidLoad()
        playSound()
        
        setCaptureSession()
        
        computerChoiceImg.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        computerChoiceImg.isHidden = true
        userChoiceImg.isHidden = true
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

        //setup output, add output to our capture session
        let captureOutput = AVCaptureVideoDataOutput()
        captureSession.addOutput(captureOutput)
        
        //add capture session output as a sublayer to the view controller's view
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = cameraView.frame

        //previewLayer.frame = view.frame
        cameraView.layer.insertSublayer(previewLayer, at: 0)
        
        captureSession.startRunning()
        
        captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video Queue"))
    }
    
    // Each time a fram is captured, the delegate is notified by calling captureOutput().
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        //create a VNCoreMLModel with our custom image classifier
        guard let model = try? VNCoreMLModel(for: MyClassifier().model) else {return}
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
                //self.label.text = "Unable to classify image.\n\(error!.localizedDescription)"
                print("Unable to classify image.\n\(error!.localizedDescription)")
                return
            }
            // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
            let classifications = results as! [VNClassificationObservation]
            
            if classifications.isEmpty {
                print("Nothing recognized.")
            } else {
                // Display top classifications ranked by confidence in the UI.
                let topClassifications = classifications.prefix(2)
                let descriptions = topClassifications.map { classification in
                    // Formats the classification for display; e.g. "(0.37) cliff, drop, drop-off".
                    return String(format: "  (%.2f) %@",classification.confidence, classification.identifier)
                }
                self.imageClassifierResult = descriptions.joined(separator: "\n")
                
                self.machineLearning.text = self.imageClassifierResult
                self.machineLearning.sizeToFit()
                print(descriptions.joined(separator: "\n"))
            }
        }
    }
    
    @IBAction func Play(sender: AnyObject){
        if play == false {
            play = true
            myTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timer), userInfo: nil, repeats: true)
        }
        
    }
    
    @objc func timer(){
        if time <= 1{
            time += 1
            timerLbl.text = jokenpoWords[time]
        }else{
            myTimer.invalidate()
            jokenpo(handFormat: imageClassifierResult.components(separatedBy: " ")[3])
        }
    }
    
    func checkWinner (){
        winner = 1
        if playerChoice == computerChoice {
            winner = 0
        }else{
            if computerChoice == "Pedra" && playerChoice == "Tesoura"{
                winner = -1
            }else if computerChoice == "Papel" && playerChoice == "Pedra"{
                winner = -1
            }else if computerChoice == "Tesoura" && playerChoice == "Papel"{
                winner = -1
            }else if playerChoice == "Nada"{
                winner = -1
            }
        }
        
        print("player: ", playerChoice)
        print("computer: ", computerChoice)
        print("result: ", winner)
        
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(nextView), userInfo: nil, repeats: false)
    }
    
    @objc func nextView() {
        self.performSegue(withIdentifier: "end", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "end" {
            let finalView =  segue.destination as! FinalViewController
            finalView.winner = self.winner
        }
    }
    func jokenpo (handFormat:String){

        print("parou o timer")
        
        computerChoice = jogadas[Int(arc4random_uniform(UInt32(jogadas.count)))]
        let str = imageClassifierResult.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        playerChoice = str[3].trimmingCharacters(in: .whitespaces)
        
        print("procurar 2:", str[3])
        
        computerChoiceImg.image = UIImage(named: computerChoice)
        userChoiceImg.image = UIImage(named: playerChoice)
        computerChoiceImg.isHidden = false
        userChoiceImg.isHidden = false
        
        checkWinner()
    }

    func playSound() {
        guard let url = Bundle.main.url(forResource: "Music", withExtension: "mp3") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let player = player else { return }
            
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

