//
//  ViewController.swift
//  WatchStream
//
//  Created by Pavel Shishkanov on 14/02/2017.
//  Copyright © 2017 Pavel Shishkanov. All rights reserved.
//

import UIKit
import AVFoundation

class StreamViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    //MARK: Properties
    
    @IBOutlet weak var previewView: UIView!
    
    @IBOutlet weak var streamView: UIView!
    
    var displayLayer:AVSampleBufferDisplayLayer?
    
    var frontDeviceInput : AVCaptureDeviceInput?
    var backDeviceInput : AVCaptureDeviceInput?
    
    var dataOutput: AVCaptureVideoDataOutput?
    
    var currentPosition: AVCaptureDevicePosition = AVCaptureDevicePosition.back {
        willSet {
            setCameraPreview(position: newValue)
        }
    }
    
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    let captureSession = AVCaptureSession()

    override func viewDidLoad() {
        super.viewDidLoad()
        initCameraPreview()
        
        do {
            frontDeviceInput = try AVCaptureDeviceInput(device: camera(AVCaptureDevicePosition.front))
            backDeviceInput = try AVCaptureDeviceInput(device: camera(AVCaptureDevicePosition.back))
        } catch {
            print(error)
        }
        
        currentPosition = AVCaptureDevicePosition.back
        
        dataOutput = AVCaptureVideoDataOutput()
        dataOutput?.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]
        dataOutput?.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(dataOutput) {
           captureSession.addOutput(dataOutput)
        }
        
        let queue = DispatchQueue(label: "org.pshishkanov.videoQueue")
        dataOutput?.setSampleBufferDelegate(self, queue: queue)
    
        displayLayer = AVSampleBufferDisplayLayer()
        displayLayer?.bounds = streamView.bounds
        displayLayer?.frame = streamView.frame
        displayLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill;
        displayLayer?.position = CGPoint(x: streamView.bounds.midX, y: streamView.bounds.midY)
        displayLayer?.removeFromSuperlayer()
        streamView.layer.addSublayer(displayLayer!)
    
    }

    @IBAction func done(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func switchCamera(_ sender: UIButton) {
        switch(currentPosition) {
        case AVCaptureDevicePosition.back:
            currentPosition = AVCaptureDevicePosition.front
        case AVCaptureDevicePosition.front:
            currentPosition = AVCaptureDevicePosition.back
        default:
            currentPosition = AVCaptureDevicePosition.back
        }
    }
    
    private func setCameraPreview(position: AVCaptureDevicePosition) {
        captureSession.stopRunning()
        captureSession.beginConfiguration()
        
        if let currentInputDevice = captureSession.inputs.first as? AVCaptureInput {
            captureSession.removeInput(currentInputDevice)
        }
        
        switch position {
        case .back,
             .unspecified:
            if captureSession.canAddInput(backDeviceInput) {
                captureSession.addInput(backDeviceInput)
            }
        case .front:
            if captureSession.canAddInput(frontDeviceInput) {
                captureSession.addInput(frontDeviceInput)
            }
            
        }
        
        captureSession.commitConfiguration()
        captureSession.startRunning()
    }
    
    private func initCameraPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session:captureSession)
        if let previewLayer = previewLayer {
            previewLayer.frame = previewView.layer.bounds
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            previewView.layer.addSublayer(previewLayer)
        }
    }
    
    private func camera(_ position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        for device in devices! {
            let device = device as! AVCaptureDevice
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if (displayLayer != nil && (displayLayer?.isReadyForMoreMediaData)!) {
            displayLayer?.enqueue(sampleBuffer)
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
//        print("Frame was droped... \(Date())")
    }
    
    func recive(_ sender: UIButton) {
        print("Start recive...")
        let queue = DispatchQueue.global(qos: .background)
        queue.async {
            let server: UDPServer = UDPServer(address: "255.255.255.255", port: 14322)
            let run = true
            print("Start UDP server...")
            while run {
                print("Wait...")
                let (data,remoteip,remoteport)=server.recv(1024)
                print("receive")
                if let d=data{
                    if let str=String(bytes: d, encoding: String.Encoding.utf8){
                        print(str)
                    }
                }
                print(remoteport)
                print(remoteip)
                server.close()
                break
            }
        }

    }
    
    func send(_ sender: UIButton) {
        print("Start send...")
        let queue = DispatchQueue.global(qos: .background)
        queue.async {
            let client: UDPClient = UDPClient(address: "192.168.0.101", port: 14322)
            // client.send(string: "Hello\n")
            client.close()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
//        coordinator.animate(
//            alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
//                let deltaTransform = coordinator.targetTransform
//                let deltaAngle = atan2f(Float(deltaTransform.b), Float(deltaTransform.a))
//                var currentRotation : Float = ((self.previewView!.layer.value(forKeyPath: "transform.rotation.z") as AnyObject).floatValue)!
//                // Adding a small value to the rotation angle forces the animation to occur in a the desired direction, preventing an issue where the view would appear to rotate 2PI radians during a rotation from LandscapeRight -> LandscapeLeft.
//                currentRotation += -1 * deltaAngle + 0.0001;
//                self.previewView!.layer.setValue(currentRotation, forKeyPath: "transform.rotation.z")
//                self.previewView!.layer.frame = self.view.bounds
//        },
//            completion:
//            { (UIViewControllerTransitionCoordinatorContext) in
//                // Integralize the transform to undo the extra 0.0001 added to the rotation angle.
//                var currentTransform : CGAffineTransform = self.previewView!.transform
//                currentTransform.a = round(currentTransform.a)
//                currentTransform.b = round(currentTransform.b)
//                currentTransform.c = round(currentTransform.c)
//                currentTransform.d = round(currentTransform.d)
//                self.previewView!.transform = currentTransform
//        })
    }
}

extension AVCaptureVideoOrientation {
    
    func print() -> String {
        switch self {
        case .portrait:
            return "portrait"
        case .portraitUpsideDown:
            return "portraitUpsideDown"
        case .landscapeRight:
            return "landscapeRight"
        case .landscapeLeft:
            return "landscapeLeft"
        }
    }
}

