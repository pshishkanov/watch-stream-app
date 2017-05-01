//
//  StreamViewController.swift
//  WatchStream
//
//  Created by Pavel Shishkanov on 30/04/2017.
//  Copyright © 2017 Pavel Shishkanov. All rights reserved.
//

import Foundation

import Foundation
import UIKit
import AVFoundation
import VideoToolbox
import CocoaAsyncSocket

class StreamViewController: UIViewController, GCDAsyncUdpSocketDelegate {
    
    private let udpQueue = DispatchQueue(label: "org.pshishkanov.udpQueue")
    
    private var _socket: GCDAsyncUdpSocket?
    
    private var socket: GCDAsyncUdpSocket? {
        get {
            if _socket == nil {
                _socket = getNewSocket()
            }
            return _socket
        }
        set {
            if _socket != nil {
                _socket?.close()
            }
            _socket = newValue
        }
    }
    
    private func getNewSocket() -> GCDAsyncUdpSocket? {
        let port = UInt16(55555)
        let sock = GCDAsyncUdpSocket(delegate: self, delegateQueue: udpQueue)
        do {
            try sock.bind(toPort: port)
        } catch {
            log.error(">>>Issue with setting up listener")
            return nil
        }
        return sock
    }
    
    @IBOutlet weak var cancelButton: CancelButton!
    
    @IBOutlet weak var streamView: UIView!
    let streamLayer = AVSampleBufferDisplayLayer()
    
    fileprivate var videoDecoder: VideoDecoder?
    
    // MARK: UIViewController methods
    override open func viewDidLoad() {
        cancelButton.addOnTapObserver {
            self.dismiss(animated: true, completion: nil)
        }        
        do {
            try socket?.beginReceiving()
        } catch {
            log.error("Issue starting listener")
            return
        }
        log.info(">> Server started")
        
        streamLayer.frame = streamView.bounds
        streamLayer.videoGravity = AVLayerVideoGravityResizeAspect
        streamLayer.removeFromSuperlayer()
        streamView.layer.addSublayer(streamLayer)
        
        videoDecoder = VideoDecoder()
        videoDecoder?.delegate = self

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if socket != nil {
            socket?.pauseReceiving()
            log.info(">> Server stopped")
        }
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        let ptr: UnsafeBufferPointer<UInt8> = data.withUnsafeBytes {
            UnsafeBufferPointer(start: $0, count: data.count)
        }
        let nalu = NALU(ptr)
        if nalu.type == .pps || nalu.type == .sps {
            log.info("Recive data \(nalu.type): \(data.debugDescription)")
        }
        videoDecoder?.decode(nalu)
    }
    
    
}

extension StreamViewController: VideoDecoderDelegate {
    func didFinishDecode(_ sampleBuffer: CMSampleBuffer) {        
        if streamLayer.isReadyForMoreMediaData {
            streamLayer.enqueue(sampleBuffer)
        }
    }
}
