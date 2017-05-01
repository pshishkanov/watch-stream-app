//
//  VideoDecoder.swift
//  WatchStream
//
//  Created by Pavel Shishkanov on 28/04/2017.
//  Copyright © 2017 Pavel Shishkanov. All rights reserved.
//

import Foundation
import VideoToolbox

class VideoDecoder {
    
    public var delegate: VideoDecoderDelegate?
    
    private var dirtySPS : NALU?
    private var dirtyPPS : NALU?
    private var sps : NALU?
    private var pps : NALU?
    
    private var mutex = pthread_mutex_t()
    
    private var formatDescription : CMVideoFormatDescription!
    
    public init() {
        pthread_mutex_init(&mutex, nil)
    }
    
    deinit{
        invalidate()
        pthread_mutex_destroy(&mutex)
    }
    
    public func decode(_ nalu: NALU) {
        guard nalu.type != .unspec else {
            return
        }
        if nalu.type == .sps || nalu.type == .pps {
            if nalu.type == .sps {
                dirtySPS = nalu.copy()
            } else if nalu.type == .pps {
                dirtyPPS = nalu.copy()
            }
            if dirtySPS != nil && dirtyPPS != nil {
                if sps == nil || pps == nil || sps!.equals(dirtySPS!) || pps!.equals(dirtyPPS!) {
                    invalidate()
                    sps = dirtySPS!.copy()
                    pps = dirtyPPS!.copy()
                    initVideoSession()
                }
                dirtySPS = nil
                dirtyPPS = nil
            }
            return
        }
        
        if nalu.type == .sei {
            return
        }
        
        guard formatDescription != nil else {
            return
        }
        // returns a non-contiguous CMBlockBuffer.
        var bblen = 0
        var biglen = CFSwapInt32HostToBig(UInt32((nalu.data?.count)!))
        memcpy(&bblen, &biglen, 4)
        var _buffer : CMBlockBuffer?
        var status = CMBlockBufferCreateWithMemoryBlock(nil, &bblen, 4, kCFAllocatorNull, nil, 0, 4, 0, &_buffer)
        if status != noErr {
            log.info("CMBlockBufferCreateWithMemoryBlock error: \(status)")
            return
        }
        var bufferData : CMBlockBuffer?
        status = CMBlockBufferCreateWithMemoryBlock(nil, UnsafeMutablePointer<UInt8>(mutating: nalu.data?.baseAddress), (nalu.data?.count)!, kCFAllocatorNull, nil, 0, (nalu.data?.count)!, 0, &bufferData)
        if status != noErr {
            log.info("CMBlockBufferCreateWithMemoryBlock error: \(status)")
            return
        }
        
        status = CMBlockBufferAppendBufferReference(_buffer!, bufferData!, 0, (nalu.data?.count)!, 0)
        if status != noErr {
            log.info("CMBlockBufferAppendBufferReference error: \(status)")
            return
        }
        
        var sampleBuffer : CMSampleBuffer?
        status = CMSampleBufferCreateReady(kCFAllocatorDefault, _buffer, formatDescription, 1, 0, nil, 0, nil, &sampleBuffer)
        guard sampleBuffer != nil else {
            log.info("CMSampleBufferCreateReady error: \(status)")
            return
        }
        let attachments:CFArray? = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer!, true)
        if let attachmentArray = attachments {
            let dic = unsafeBitCast(CFArrayGetValueAtIndex(attachmentArray, 0), to: CFMutableDictionary.self)
            
            CFDictionarySetValue(dic,
                                 Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                                 Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
        }
        delegate?.didFinishDecode(sampleBuffer!)
        
    }
    
    private func invalidate() {
        formatDescription = nil
        sps = nil
        pps = nil
    }
    
    private func initVideoSession() {
        formatDescription = nil
        var _formatDescription : CMFormatDescription?
        let parameterSetPointers : [UnsafePointer<UInt8>] = [ pps!.data!.baseAddress!, sps!.data!.baseAddress! ]
        let parameterSetSizes : [Int] = [ pps!.data!.count, sps!.data!.count ]
        let status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, parameterSetPointers, parameterSetSizes, 4, &_formatDescription);
        if status != noErr {
            log.info("pps: \(pps!.data!.debugDescription)")
            log.info("sps: \(sps!.data!.debugDescription)")
            log.info("dirtyPPS: \(dirtyPPS!.data!.debugDescription)")
            log.info("dirtySPS: \(dirtySPS!.data!.debugDescription)")
            log.warning("CMVideoFormatDescriptionCreateFromH264ParameterSets error: \(status)")
            sps = nil
            pps = nil
            return
        } else {
//            log.warning("CMVideoFormatDescriptionCreateFromH264ParameterSets good ...")
        }
        formatDescription = _formatDescription!
    }

    
}

protocol VideoDecoderDelegate {
    func didFinishDecode(_ sampleBuffer: CMSampleBuffer)
}
