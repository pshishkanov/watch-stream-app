//
//  CancelButton.swift
//  WatchStream
//
//  Created by Pavel Shishkanov on 03/04/2017.
//  Copyright © 2017 Pavel Shishkanov. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class CancelButton: UIButton {
    
    // MARK: On tap observer
    private var onTapObservers = [() -> Void]()
    
    func onTapNotify() {
        onTapObservers.forEach({ $0() })
    }
    
    public func addOnTapObserver(observer: @escaping () -> Void) {
        onTapObservers.append(observer)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    private func setupButton() {
        setTitle( "Cancel" , for: .normal )        
        sizeToFit()
        addTarget(self, action: #selector(onTapNotify), for: .touchUpInside)
    }
    
}
