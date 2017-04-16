//
//  RecordButton.swift
//  WatchStream
//
//  Created by Pavel Shishkanov on 26/03/2017.
//  Copyright © 2017 Pavel Shishkanov. All rights reserved.
//

import UIKit

class CameraButton: UIButton {
    
    // MARK: On turn on observer
    private var onTurnOnObservers = [() -> Void]()
    
    private func onTurnOnNotify() {
        onTurnOnObservers.forEach({ $0() })
    }
    
    public func addOnTurnOnObserver(observer: @escaping () -> Void) {
        onTurnOnObservers.append(observer)
    }
    
    // MARK: On turn off observer
    private var onTurnOffObservers = [() -> Void]()
    
    private func onTurnOffNotify() {
        onTurnOffObservers.forEach({ $0() })
    }
    
    public func addOnTurnOffObserver(observer: @escaping () -> Void) {
        onTurnOffObservers.append(observer)
    }
    
    // MARK: Size
    struct Dimensions {
        static let radius = 40
        static let borderLayerRadius = 32
        static let buttonLayerRadius = 30
        static let maskLayerRadius = 27
    }
    
    private var isCapture: Bool = false {
        didSet {
            if isCapture {
                onTurnOnNotify()
            } else {
                onTurnOffNotify()

            }
        }
    }
    
    private let borderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = UIBezierPath(arcCenter: CGPoint(x: Dimensions.radius, y: Dimensions.radius),
                                  radius: CGFloat(Dimensions.borderLayerRadius),
                                  startAngle: 0, endAngle: CGFloat(2 * Double.pi),
                                  clockwise: true).cgPath
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.white.cgColor
        layer.lineWidth = 6
        return layer
    }()
    
    private let buttonLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.path = UIBezierPath(roundedRect: CGRect(x: Dimensions.radius - Dimensions.buttonLayerRadius,
                                                      y: Dimensions.radius - Dimensions.buttonLayerRadius,
                                                      width: 2 * Dimensions.buttonLayerRadius,
                                                      height: 2 * Dimensions.buttonLayerRadius),
                                  cornerRadius: 6).cgPath
        
        layer.fillColor = UIColor.red.cgColor
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: CGRect(x: Dimensions.radius - Dimensions.maskLayerRadius,
                                                          y: Dimensions.radius - Dimensions.maskLayerRadius,
                                                          width: 2 * Dimensions.maskLayerRadius,
                                                          height: 2 * Dimensions.maskLayerRadius),
                                      cornerRadius: CGFloat(Dimensions.radius)).cgPath
        layer.mask = maskLayer
        
        return layer
    }()
    
    private let animation: CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        return animation
    }()
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 2 * Dimensions.radius, height: 2 * Dimensions.radius))
       
        layer.addSublayer(borderLayer)
        layer.addSublayer(buttonLayer)
        
        addTarget(self, action: #selector(touchDown as (Void) -> Void), for: .touchDown)
        addTarget(self, action: #selector(touchUpInside as (Void) -> Void), for: .touchUpInside)
        addTarget(self, action: #selector(touchUpOutside as (Void) -> Void), for: .touchUpOutside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    internal func touchUpInside() {
        buttonLayer.opacity = 1

        if isCapture {
            animation.fromValue = innerPath(offset: 25).cgPath
            animation.toValue = innerPath(offset: 10).cgPath
        } else {
            animation.fromValue = innerPath(offset: 10).cgPath
            animation.toValue = innerPath(offset: 25).cgPath
        }
        buttonLayer.add(animation, forKey: "path");
        
        self.isCapture = !self.isCapture
    }
    
    internal func touchUpOutside() {
        buttonLayer.opacity = 1
    }
    
    internal func touchDown() {
        buttonLayer.opacity = 0.5
    }
    
    internal func innerPath(offset: Int) -> UIBezierPath {
        return UIBezierPath(roundedRect: bounds.insetBy(dx: CGFloat(offset), dy: CGFloat(offset)), cornerRadius: 6)
    }
}
