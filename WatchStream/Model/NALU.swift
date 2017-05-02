//
//  NALU.swift
//  WatchStream
//
//  Created by Pavel Shishkanov on 25/04/2017.
//  Copyright © 2017 Pavel Shishkanov. All rights reserved.
//

import Foundation

enum NALType: UInt8 {
    /* Unspecified */
    case unspec   = 0
    /* Coded slice of a non-IDR picture (P frame) */
    case slice    = 1
    /* Coded slice data partition A */
    case dpa      = 2
    /* Coded slice data partition B */
    case dpb      = 3
    /* Coded slice data partition C */
    case dpc      = 4
    /* Coded slice of an IDR picture (I frame) */
    case idr      = 5
    /* Supplemental enhancement information (SEI) */
    case sei      = 6
    /* Sequence parameter set (SPS) */
    case sps      = 7
    /* Picture parameter set (PPS) */
    case pps      = 8
    /* Access unit delimiter */
    case aud      = 9
    /* End of sequence */
    case eoseq    = 10
    /* End of stream */
    case eostream = 11
    /* Filler data */
    case fill     = 12
}

struct NALU {
    var refIdc: UInt8 = 0
    var type: NALType = .unspec
    var data: UnsafeBufferPointer<UInt8>? = nil
    
    init(_ buffer: UnsafeBufferPointer<UInt8>) {
        guard buffer.count > 0 else {
            return
        }
        guard (buffer[0] >> 7) & 0b000_00001 == 0 else {
            return
        }
        refIdc = (buffer[0] >> 5) & 0b000_00011
        type =  NALType(rawValue: (buffer[0] >> 0) & 0b0001_1111) ?? .unspec
        data = buffer
    }
    
    public func equals(_ nalu: NALU) -> Bool {
        guard data != nil, nalu.data != nil, nalu.data?.count != data?.count else {
            return false
        }
        return memcmp(nalu.data!.baseAddress, data!.baseAddress, data!.count) == 0
    }
    
    public func copy() -> NALU {
        let baseAddress = UnsafeMutablePointer<UInt8>.allocate(capacity: data!.count)
        memcpy(baseAddress, data!.baseAddress, data!.count)
        let nalu = NALU(UnsafeBufferPointer(start: baseAddress, count: data!.count))        
        return nalu
    }
}
