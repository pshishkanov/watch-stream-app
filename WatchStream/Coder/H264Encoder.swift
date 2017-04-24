//
//  H264Encoder.swift
//  WatchStream
//
//  Created by Pavel Shishkanov on 18/03/2017.
//  Copyright © 2017 Pavel Shishkanov. All rights reserved.
//

import Foundation
import VideoToolbox

class H264Encoder {
    
    public var delegate: H264EncoderDelegate?
    
    private var compressionSession: VTCompressionSession?
    
    private let defaultAttributes: [NSString: AnyObject] = [
        kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA) as AnyObject,
        kCVPixelBufferWidthKey: 1920 as AnyObject,
        kCVPixelBufferHeightKey: 1080 as AnyObject]
    
    // MARK: Callback
    
    private let didFinishEncodeSampleBufferCallback: VTCompressionOutputCallback = {(
        outputCallbackRefCon: UnsafeMutableRawPointer?, sourceFrameRefCon: UnsafeMutableRawPointer?,
        status: OSStatus, infoFlags: VTEncodeInfoFlags, sampleBuffer: CMSampleBuffer?) in
        
        guard status == noErr else {
            print("Error during compress CMSampleBuffer: \(status).")
            return
        }
        guard let sampleBuffer = sampleBuffer else {
            print("Compressed CMSampleBuffer is nil.")
            return
        }
        guard CMSampleBufferDataIsReady(sampleBuffer) else {
            print("Compressed CMSampleBufferData is not ready.")
            return
        }
        let encoder = unsafeBitCast(outputCallbackRefCon, to: H264Encoder.self)
        encoder.delegate?.didFinishEncode(sampleBuffer: sampleBuffer)
    }
    
    // MARK: Constructor
    
    init() {
        let status = VTCompressionSessionCreate(kCFAllocatorDefault, 1920, 1080, kCMVideoCodecType_H264, nil, defaultAttributes as CFDictionary, nil,
                                                didFinishEncodeSampleBufferCallback, unsafeBitCast(self, to: UnsafeMutableRawPointer.self), &compressionSession)
        guard let vtCompressionSession = compressionSession else {
            print("Error during VTCompressionSessionCreate: \(status)")
            return
        }
        setupSession(vtCompressionSession)
    }
    
    public func encode(uncompressedSampleBuffer: CMSampleBuffer) {
        let time = CMSampleBufferGetPresentationTimeStamp(uncompressedSampleBuffer);
        let duration = CMSampleBufferGetDuration(uncompressedSampleBuffer);
        let pixelBuffer = CMSampleBufferGetImageBuffer(uncompressedSampleBuffer);
        
        var flags: VTEncodeInfoFlags = VTEncodeInfoFlags()
        let status = VTCompressionSessionEncodeFrame(compressionSession!, pixelBuffer!, time, duration, nil, nil, &flags)
        guard status == noErr else {
            print("Error during pass frame to encode: \(status).")
            return
        }
        print("Successful pass frame to encode.")
    }
    
    private func setupSession(_ session: VTCompressionSession) {
        VTSessionSetProperty(session, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue)
        VTSessionSetProperty(session, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse)
        VTSessionSetProperty(session, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_High_AutoLevel)
        VTSessionSetProperty(session, kVTCompressionPropertyKey_AverageBitRate, NSNumber(value: 160 * 1024))
        VTSessionSetProperty(session, kVTCompressionPropertyKey_MaxKeyFrameInterval, NSNumber(value: 30))
        VTCompressionSessionPrepareToEncodeFrames(session)
    }
}

