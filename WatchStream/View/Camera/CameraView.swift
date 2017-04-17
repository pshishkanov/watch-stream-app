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
    
    // MARK: Size
    struct Dimensions {
        static let bottomViewHeight = 80
    }
    
    // MARK: Layers
    private let controlsView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    private let bottomView: UIView = {
        let view = UIView()
        view.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        view.backgroundColor = UIColor(white: 0, alpha: 0.4)
        return view
    }()
    
    // MARK: Buttons
    let cameraButton: CameraButton = {
        let button = CameraButton()
        return button
    }()
    
    let cancelButton: CancelButton = {
        let button = CancelButton()       
        return button
    }()
    
    let previewView: PreviewView = {
        let view = PreviewView()
        return view
    }()
    
    // MARK: Constructor
    override init(frame : CGRect) {
        super.init(frame : frame)
        positionSubview()
        addObservers()
    }
    
    func positionSubview() {
        previewView.frame = frame
        addSubview(previewView)
        
        controlsView.frame = frame
        addSubview(controlsView)
        
        bottomView.bounds = CGRect(x: 0, y: 0, width: Int(controlsView.bounds.width), height: Dimensions.bottomViewHeight)
        let bottomViewCenterX = Int(controlsView.bounds.width / 2)
        let bottomViewCenterY = Int(controlsView.bounds.height) - Dimensions.bottomViewHeight / 2
        bottomView.center = CGPoint(x: bottomViewCenterX, y: bottomViewCenterY)
        controlsView.addSubview(bottomView)
        
        cameraButton.center = CGPoint(x: bottomView.bounds.width / 2, y: bottomView.bounds.height / 2)
        bottomView.addSubview(cameraButton)
        
        let cancelButtonCenterX = bottomView.bounds.width / 2 + (bottomView.bounds.width / 2 + cameraButton.bounds.width / 2) / 2
        let cancelButtonCenterY = bottomView.bounds.height / 2
        cancelButton.center = CGPoint(x: cancelButtonCenterX, y: cancelButtonCenterY)
        bottomView.addSubview(cancelButton)
    }
    
    func addObservers() {
        
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
