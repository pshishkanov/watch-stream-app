//
//  CameraView.swift
//  WatchStream
//
//  Created by Pavel Shishkanov on 21/03/2017.
//  Copyright © 2017 Pavel Shishkanov. All rights reserved.
//

import Foundation
import UIKit

class CameraView: UIView {
    
    // MARK: On start streaming observers
    private var onStartStreamingObservers = [(() -> Void)]()
    
    private func onStartStreamingNotify () {
        onStartStreamingObservers.forEach({ $0() })
    }
    
    func addOnStartStreamingObserver(observer: @escaping (() -> Void)) {
        onStartStreamingObservers.append(observer)
    }
    
    // MARK: On stop streaming observers
    private var onStopStreamingObservers = [(() -> Void)]()
    
    private func onStopStreamingNotify() {
        onStopStreamingObservers.forEach({ $0() })
    }
    
    func addOnStopStreamingObserver(observer: @escaping (() -> Void)) {
        onStopStreamingObservers.append(observer)
    }

    // MARK: On cancel streaming observers
    private var onCancelStremingObservers = [(() -> Void)]()
    
    private func onCancelStreamingNotify () {
        onCancelStremingObservers.forEach({ $0() })
    }
    
    func addOnCancelStreamingObserver(observer: @escaping (() -> Void)) {
        onCancelStremingObservers.append(observer)
    }
    
    // MARK: Buttons
    @IBOutlet weak var cameraButton: CameraButton!
    @IBOutlet weak var cancelButton: CancelButton!
    
    // MARK: Preview View
    @IBOutlet weak var previewView: PreviewView!
    
    // MARK: Constructor
    override init(frame : CGRect) {
        super.init(frame : frame)
    }
    
    public func setupObservers() {
        cameraButton.addOnTurnOnObserver {
            self.onStartStreamingNotify()
        }
        cameraButton.addOnTurnOnObserver {
            self.cancelButton.isHidden = true
        }
        cameraButton.addOnTurnOffObserver {
            self.onStopStreamingNotify()
        }
        cameraButton.addOnTurnOffObserver {
            self.cancelButton.isHidden = false
        }
        cancelButton.addOnTapObserver {
           self.onCancelStreamingNotify()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
