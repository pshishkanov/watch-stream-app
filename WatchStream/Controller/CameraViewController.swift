//
//  CameraViewController.swift
//  WatchStream
//
//  Created by Pavel Shishkanov on 21/03/2017.
//  Copyright © 2017 Pavel Shishkanov. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import CoreMotion

class CameraViewController: UIViewController {
    
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    private var defaultCaptureDevice = AVCaptureDevicePosition.back
    private var currentDevice: AVCaptureDevice?
    private var captureDeviceFront: AVCaptureDevice?
    private var captureDeviceBack: AVCaptureDevice?
    
    
    @IBOutlet var cameraView: CameraView!
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        cameraView.setupObservers()
        addObservers()
    }
    
    func addObservers() {
        cameraView.addOnCancelStreamingObserver {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        if !self.captureSession.isRunning {
//            self.captureSession.startRunning()
//        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    open func setupDevices() {
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice]
        
        for device in devices {
            if device.position == .back {
                self.captureDeviceBack = device
            }
            if device.position == .front {
                self.captureDeviceFront = device
            }
        }
        
        switch self.defaultCaptureDevice {
        case .front:
            self.currentDevice = self.captureDeviceFront ?? self.captureDeviceBack
        case .back:
            self.currentDevice = self.captureDeviceBack ?? self.captureDeviceFront
        default:
            self.currentDevice = self.captureDeviceBack
        }
    }
    
    open func beginSession() {
        self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        self.setupCurrentDevice()
        
        let stillImageOutput = AVCaptureStillImageOutput()
        if self.captureSession.canAddOutput(stillImageOutput) {
            self.captureSession.addOutput(stillImageOutput)
        }              
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.previewLayer.frame = self.view.bounds
        
        let rootLayer = self.view.layer
        rootLayer.masksToBounds = true
        rootLayer.insertSublayer(self.previewLayer, at: 0)
    }
    
    internal func switchCamera() {
        self.currentDevice = self.currentDevice == self.captureDeviceBack ?
            self.captureDeviceFront : self.captureDeviceBack
        
        self.setupCurrentDevice()
    }
    
    open func setupCurrentDevice() {
        if let currentDevice = self.currentDevice {
            
            for oldInput in self.captureSession.inputs as! [AVCaptureInput] {
                self.captureSession.removeInput(oldInput)
            }
            
            let frontInput = try? AVCaptureDeviceInput(device: self.currentDevice)
            if self.captureSession.canAddInput(frontInput) {
                self.captureSession.addInput(frontInput)
            }
        }
    }
    
    open override var shouldAutorotate : Bool {
        return false
    }
}

public extension UIInterfaceOrientation {
    
    func toDeviceOrientation() -> UIDeviceOrientation {
        switch self {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeRight:
            return .landscapeLeft
        case .landscapeLeft:
            return .landscapeRight
        default:
            return .portrait
        }
    }
}

public extension UIDeviceOrientation {
    
    func toAVCaptureVideoOrientation() -> AVCaptureVideoOrientation {
        switch self {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeRight:
            return .landscapeLeft
        case .landscapeLeft:
            return .landscapeRight
        default:
            return .portrait
        }
    }
    
    func toInterfaceOrientationMask() -> UIInterfaceOrientationMask {
        switch self {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeRight:
            return .landscapeLeft
        case .landscapeLeft:
            return .landscapeRight
        default:
            return .portrait
        }
    }
    
    func toAngleRelativeToPortrait() -> CGFloat {
        switch self {
        case .portrait:
            return 0
        case .portraitUpsideDown:
            return CGFloat(M_PI)
        case .landscapeRight:
            return CGFloat(-M_PI_2)
        case .landscapeLeft:
            return CGFloat(M_PI_2)
        default:
            return 0
        }
    }
    
}

public extension CMAcceleration {
    func toDeviceOrientation() -> UIDeviceOrientation? {
        if self.x >= 0.75 {
            return .landscapeRight
        } else if self.x <= -0.75 {
            return .landscapeLeft
        } else if self.y <= -0.75 {
            return .portrait
        } else if self.y >= 0.75 {
            return .portraitUpsideDown
        } else {
            return nil
        }
    }
}
