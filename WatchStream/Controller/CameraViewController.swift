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
import CocoaAsyncSocket

class CameraViewController: UIViewController, GCDAsyncUdpSocketDelegate {
    
    var _socket: GCDAsyncUdpSocket?
    var socket: GCDAsyncUdpSocket? {
        get {
            if _socket == nil {
                let sock = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.global(qos: .utility))
                do {
                    try sock.bind(toPort: 0)
                } catch let err as NSError {
                    log.error(">>> Error while initializing socket: \(err.localizedDescription)")
                    sock.close()
                    return nil
                }
                _socket = sock
            }
            return _socket
        }
        set {
            _socket?.close()
            _socket = newValue
        }
    }
    
    deinit {
        socket = nil
    }
    
    // MARK: Interface properties
    private var blurView: UIVisualEffectView!
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var cameraButton: CameraButton!
    @IBOutlet weak var cancelButton: CancelButton!
    
    // MARK: Video session properties
    private let session = AVCaptureSession()
    
    // MARK: Video output properties
    private var videoOutput = AVCaptureVideoDataOutput()
    private let videoOutputQueue = DispatchQueue(label: "org.pshishkanov.videoOutputQueue")
    
    // MARK: Coder properties
    fileprivate var videoEncoder: VideoEncoder?
    fileprivate var videoDecoder: VideoDecoder?
    
    // MARK: Camera devices
    private var defaultCamera: AVCaptureDevice = {
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice]
        return devices[0]
    }()
    
    // MARK: UIViewController methods
    override open func viewDidLoad() {
        super.viewDidLoad()
        setupVideoSession()
        setupBlur()
        setupPreview()
        setupObservers()
        
        videoEncoder = VideoEncoder()
        videoEncoder?.delegate = self
        
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
        super.viewWillDisappear(animated)
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    // MARK: Private methods
    private func setupVideoSession() {
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSessionPresetMedium
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: defaultCamera)
            if (session.canAddInput(videoInput)) {
                session.addInput(videoInput)
            }
        } catch {
            log.warning("Error during add videoDeviceInput to session: \(error.localizedDescription)")
            session.commitConfiguration()
            return
        }
        
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) :
            NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)]
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            /* Setup connection orientation only after add output to session. Else connection is nil. */
            videoOutput.connection(withMediaType: AVMediaTypeVideo).videoOrientation = .portrait
        }

        
        session.commitConfiguration()
    }
    
    private func setupBlur() {
        blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurView.frame = previewView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    private func setupPreview() {
        previewView.session = session
        previewView.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        if previewView.previewLayer.connection != nil {
            previewView.previewLayer.connection.videoOrientation = .portrait
        }
        previewView.addSubview(blurView)
    }

    func setupObservers() {
        cameraButton.addOnTurnOnObserver {
            self.videoOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)
            self.cancelButton.isHidden = true
        }
        cameraButton.addOnTurnOffObserver {
            self.videoOutput.setSampleBufferDelegate(nil, queue: self.videoOutputQueue)
            self.cancelButton.isHidden = false
        }
        cancelButton.addOnTapObserver {
            self.dismiss(animated: true, completion: nil)
        }
    }    
}

// MARK: AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        videoEncoder?.encode(sampleBuffer)
    }
    
}

extension CameraViewController: VideoEncoderDelegate {
    func didFinishEncode(_ nalu: NALU) {
        let data = Data(buffer: nalu.data!)

        let ud = UserDefaults.standard
        ud.synchronize()
        let clientIP = ud.string(forKey: "client_ip_preference")
        socket?.send(data, toHost: clientIP!, port: 55555, withTimeout: -1, tag: 0)
    }
}
