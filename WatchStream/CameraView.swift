//
//  CameraView.swift
//  WatchStream
//
//  Created by Pavel Shishkanov on 18/03/2017.
//  Copyright © 2017 Pavel Shishkanov. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class CameraView : UIView {
    
    var preview: AVCaptureVideoPreviewLayer?
    
    override init (frame : CGRect) {
        super.init(frame : frame)
        
    }
    
    convenience init (session: AVCaptureSession) {
        self.init(frame:CGRect.zero)
        preview = AVCaptureVideoPreviewLayer(session)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
}
