//
//  RecordButton.swift
//  WatchStream
//
//  Created by Pavel Shishkanov on 26/03/2017.
//  Copyright © 2017 Pavel Shishkanov. All rights reserved.
//

import UIKit

@IBDesignable class CameraButton: UIButton {
    
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
    @IBInspectable var diameter: Int = 0 {
        didSet {
            radius = Double(diameter / 2)
            borderLayerRadius = radius * 0.8
            buttonLayerRadius = radius * 0.75
            maskLayerRadius = radius * 0.7
            setupLayers()
        }
    }
    
    private var radius: Double = 0
    private var borderLayerRadius: Double = 0
    private var buttonLayerRadius: Double = 0
    private var maskLayerRadius: Double = 0
    
    private var isCapture: Bool = false {
        didSet {
            if isCapture {
                onTurnOnNotify()
            } else {
                onTurnOffNotify()

            }
        }
    }   
    
    private var borderLayer: CAShapeLayer = CAShapeLayer()
    private var buttonLayer: CAShapeLayer = CAShapeLayer()
    
    private let animation: CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        return animation
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        setupBorderLayer()
        setupButtonLayer()
        
        addTarget(self, action: #selector(touchDown as (Void) -> Void), for: .touchDown)
        addTarget(self, action: #selector(touchUpInside as (Void) -> Void), for: .touchUpInside)
        addTarget(self, action: #selector(touchUpOutside as (Void) -> Void), for: .touchUpOutside)
    }
    
    private func setupBorderLayer() {
        let layer = self.borderLayer
        layer.path = UIBezierPath(arcCenter: CGPoint(x: radius, y: radius),
                                        radius: CGFloat(borderLayerRadius),
                                        startAngle: 0, endAngle: CGFloat(2 * Double.pi),
                                        clockwise: true).cgPath
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.white.cgColor
        layer.lineWidth = 6
        
        self.layer.addSublayer(layer)
    }
    
    private func setupButtonLayer() {
        let layer = self.buttonLayer
        layer.path = UIBezierPath(roundedRect: CGRect(x: radius - buttonLayerRadius,
                                                            y: radius - buttonLayerRadius,
                                                            width: 2 * buttonLayerRadius,
                                                            height: 2 * buttonLayerRadius),
                                        cornerRadius: 6).cgPath
        
        layer.fillColor = UIColor.red.cgColor
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: CGRect(x: radius - maskLayerRadius,
                                                          y: radius - maskLayerRadius,
                                                          width: 2 * maskLayerRadius,
                                                          height: 2 * maskLayerRadius),
                                      cornerRadius: CGFloat(radius)).cgPath
        layer.mask = maskLayer
        
        self.layer.addSublayer(layer)
    }
    
    internal func touchUpInside() {
        buttonLayer.opacity = 1

        if isCapture {
            animation.fromValue = innerPath(offset: radius / 1.7).cgPath
            animation.toValue = innerPath(offset: radius / 5).cgPath
        } else {
            animation.fromValue = innerPath(offset: radius / 5).cgPath
            animation.toValue = innerPath(offset: radius / 1.7).cgPath
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
    
    internal func innerPath(offset: Double) -> UIBezierPath {
        return UIBezierPath(roundedRect: bounds.insetBy(dx: CGFloat(offset), dy: CGFloat(offset)), cornerRadius: 6)
    }
}
