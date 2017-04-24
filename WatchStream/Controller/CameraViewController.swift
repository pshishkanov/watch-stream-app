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
import VideoToolbox

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var cameraButton: CameraButton!
    @IBOutlet weak var cancelButton: CancelButton!
    @IBOutlet weak var previewView: PreviewView!
    
    @IBOutlet weak var streamView: UIView!
    private let streamLayer = AVSampleBufferDisplayLayer()
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    
    private let dataOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "com.invasivecode.videoQueue")    
    
    // MARK: Capture
    private let session = AVCaptureSession()
    
    private var h264Encoder: H264Encoder?
    
    private var defaultVideoDevice: AVCaptureDevice = {
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice]
        return devices[0]
    }()
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        setupBlurView()
        setupObservers()
        configureSession()
        
        streamLayer.frame = streamView.bounds
        streamLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        streamLayer.removeFromSuperlayer()
        streamView.layer.addSublayer(streamLayer)
        
        h264Encoder = H264Encoder()
        h264Encoder?.delegate = self
    }
    
    private func setupBlurView() {
        blurView.frame = previewView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.previewView.addSubview(blurView)
    }
    
    func setupObservers() {
        cameraButton.addOnTurnOnObserver {
            self.dataOutput.setSampleBufferDelegate(self, queue: self.queue)
            self.cancelButton.isHidden = true
        }
        cameraButton.addOnTurnOffObserver {
            self.dataOutput.setSampleBufferDelegate(nil, queue: self.queue)
            self.cancelButton.isHidden = false
        }
        cancelButton.addOnTapObserver {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func configureSession() {
        previewView.session = session
        previewView.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSessionPresetHigh
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice)
            if (session.canAddInput(videoDeviceInput)) {
                session.addInput(videoDeviceInput)
                previewView.previewLayer.connection.videoOrientation = .portrait
            }
            dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)]
            dataOutput.alwaysDiscardsLateVideoFrames = true
            if session.canAddOutput(dataOutput) {
                session.addOutput(dataOutput)
            }
            dataOutput.connection(withMediaType: AVMediaTypeVideo).videoOrientation = .portrait
            
        } catch {
            print("Could not add video device input to the session: \(error.localizedDescription)")
            session.commitConfiguration()
            return
        }
        session.commitConfiguration()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !self.session.isRunning {
            self.session.startRunning()
        }
        UIView.animate(withDuration: 0.3) {
            self.blurView.effect = nil
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    // TODO: Remove from this class
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        h264Encoder?.encode(uncompressedSampleBuffer: sampleBuffer)
        if streamLayer.isReadyForMoreMediaData {
            streamLayer.enqueue(sampleBuffer)
        }
    }
    
    // TODO: Remove from this class
    func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
    }
    
    private func handleEncodedSampleBuffer(sampleBuffer: CMSampleBuffer) {
//        print("handleEncodedSampleBuffer ...")
        
        let description = CMSampleBufferGetFormatDescription(sampleBuffer)
        
        var sps: UnsafeMutablePointer<UnsafePointer<UInt8>?> = UnsafeMutablePointer<UnsafePointer<UInt8>?>.allocate(capacity: 1)
        var spsLength: UnsafeMutablePointer<Int> = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        var spsCount: UnsafeMutablePointer<Int> = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        var spsSize: UnsafeMutablePointer<Int32> = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        
        
        var statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description!, 0, sps, spsLength, spsCount, spsSize)
        print(statusCode)
        print(spsLength.pointee)
    }
    
    
}
extension CameraViewController: H264EncoderDelegate {
    func didFinishEncode(sampleBuffer: CMSampleBuffer) {
        print("Successful encode frame.")
    }
}
