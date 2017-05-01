//
//  VideoEncoder.swift
//  WatchStream
//
//  Created by Pavel Shishkanov on 28/04/2017.
//  Copyright © 2017 Pavel Shishkanov. All rights reserved.
//

import Foundation
import VideoToolbox

class VideoEncoder {
    
    public var delegate: VideoEncoderDelegate?
    
    private var compressionSession: VTCompressionSession?
    
    init() {
        let sourceImageBufferAttributes: [NSString: AnyObject] = [kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA) as AnyObject, kCVPixelBufferWidthKey: 540 as AnyObject, kCVPixelBufferHeightKey: 960 as AnyObject]

        VTCompressionSessionCreate(kCFAllocatorDefault, 540, 960, kCMVideoCodecType_H264, nil, sourceImageBufferAttributes as CFDictionary, nil, compressionOutputCallback, unsafeBitCast(self, to: UnsafeMutableRawPointer.self), &compressionSession)
        guard compressionSession != nil else {
            return
        }
        VTSessionSetProperty(compressionSession!, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue)
        VTSessionSetProperty(compressionSession!, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse)
        VTSessionSetProperty(compressionSession!, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel)
        VTSessionSetProperty(compressionSession!, kVTCompressionPropertyKey_AverageBitRate, NSNumber(value: 160 * 1024))
        VTSessionSetProperty(compressionSession!, kVTCompressionPropertyKey_MaxKeyFrameInterval, NSNumber(value: 30))
        VTCompressionSessionPrepareToEncodeFrames(compressionSession!)

    }
    
    private let compressionOutputCallback: VTCompressionOutputCallback = {(
        outputCallbackRefCon: UnsafeMutableRawPointer?, sourceFrameRefCon: UnsafeMutableRawPointer?,
        status: OSStatus, infoFlags: VTEncodeInfoFlags, sampleBuffer: CMSampleBuffer?) in
        
        guard status == noErr, sampleBuffer != nil else {
            return
        }
        
        var naluBuffer: [NALU] = []
        
        let encoder = unsafeBitCast(outputCallbackRefCon, to: VideoEncoder.self)
        
        /* Add Parameter Set (PPS and SPS) to stream before Iframe */
        if let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer!, false) {
            if CFArrayGetCount(attachmentsArray) > 0 {                
                let attachment = CFArrayGetValueAtIndex(attachmentsArray, 0)
                let notSyncValue = CFDictionaryGetValue(unsafeBitCast(attachment, to: CFDictionary.self), unsafeBitCast(kCMSampleAttachmentKey_NotSync, to: UnsafeRawPointer.self))
                if notSyncValue == nil {
                    if let description = CMSampleBufferGetFormatDescription(sampleBuffer!) {
                        var numParameterSet = 0
                        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, 0, nil, nil, &numParameterSet, nil)
                        for i in 0..<numParameterSet {
                            var parameterSetLength = 0
                            var parameterSetPointer:UnsafePointer<UInt8>? = nil
                            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, i, &parameterSetPointer, &parameterSetLength, nil, nil)
                            if parameterSetPointer != nil {
                                let buffer = UnsafeBufferPointer(start: parameterSetPointer!, count: parameterSetLength);
                                let nalu = NALU(buffer)
                                naluBuffer.append(nalu)
                            }
                        }
                    }
                }
            }
        }
        
        /* Get a pointer to the raw AVC NAL unit data in the sample buffer */
        var blockBufferLength: Int = 0
        var blockBufferPointerInt8: UnsafeMutablePointer<Int8>? = nil
        CMBlockBufferGetDataPointer(CMSampleBufferGetDataBuffer(sampleBuffer!)!, 0, nil, &blockBufferLength, &blockBufferPointerInt8)
        
        /* Loop through all the NAL units in the block buffer */
        var offset = 0
        let AVCCHeaderLength = 4
        while (offset < (blockBufferLength - AVCCHeaderLength) ) {
            /* Read the NAL unit length */
            var NALUnitLength: UInt32 =  0
            memcpy(&NALUnitLength, blockBufferPointerInt8! + offset, AVCCHeaderLength)
            /* Big-Endian to Little-Endian */
            NALUnitLength = CFSwapInt32(NALUnitLength)
            if NALUnitLength > 0 {
                let blockBufferPointerUInt8 = UnsafeMutableRawPointer(blockBufferPointerInt8)?.bindMemory(to: UInt8.self, capacity: 1)
                let buffer = UnsafeBufferPointer(start: blockBufferPointerUInt8! + offset + AVCCHeaderLength, count: Int(NALUnitLength));
                let nalu = NALU(buffer)
                naluBuffer.append(nalu)
                offset += AVCCHeaderLength + Int(NALUnitLength);
            }
        }
        naluBuffer.forEach {nalu in
            encoder.delegate?.didFinishEncode(nalu)
        }
    }
            
    public func encode(_ sampleBuffer: CMSampleBuffer) {
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        let duration = CMSampleBufferGetDuration(sampleBuffer);
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//    
//        log.info(CVPixelBufferGetWidth(pixelBuffer!))
//        log.info(CVPixelBufferGetHeight(pixelBuffer!))
        
        guard compressionSession != nil else {
            return
        }
        var flags: VTEncodeInfoFlags = VTEncodeInfoFlags()
        VTCompressionSessionEncodeFrame(compressionSession!, pixelBuffer!, time, duration, nil, nil, &flags)
    }
}

protocol VideoEncoderDelegate {
    func didFinishEncode(_ nalu: NALU)
}
