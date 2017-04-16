//
//  CancelButton.swift
//  WatchStream
//
//  Created by Pavel Shishkanov on 03/04/2017.
//  Copyright © 2017 Pavel Shishkanov. All rights reserved.
//

import Foundation
import UIKit

class CancelButton: UIButton {
    
    // MARK: On tap observer
    private var onTapObservers = [() -> Void]()
    
    @objc private func onTapNotify() {
        onTapObservers.forEach({ $0() })
    }
    
    public func addOnTapObserver(observer: @escaping () -> Void) {
        onTapObservers.append(observer)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setTitle( "Cancel" , for: .normal )
        autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin]
        sizeToFit()
        addTarget(self, action: #selector(onTapNotify), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
