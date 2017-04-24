//
//  H264EncoderDelegate.swift
//  WatchStream
//
//  Created by Pavel Shishkanov on 24/04/2017.
//  Copyright © 2017 Pavel Shishkanov. All rights reserved.
//

import VideoToolbox

protocol H264EncoderDelegate {
    func didFinishEncode(sampleBuffer: CMSampleBuffer)
}
