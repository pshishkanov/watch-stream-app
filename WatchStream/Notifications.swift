//
//  NotificationsName.swift
//  WatchStream
//
//  Created by Pavel Shishkanov on 03/04/2017.
//  Copyright © 2017 Pavel Shishkanov. All rights reserved.
//

import Foundation

class Notifications {
    
    struct Camera {
        static let onStartStreaming = Notification.Name(rawValue: "Camera.onStartStreaming")
        static let onStopStreaming = Notification.Name(rawValue: "onStopStreaming")
        static let onCancelStreaming = Notification.Name(rawValue: "onCancelStreaming")
    }
    
    struct Device {
        static let onOrientationChanged = Notification.Name(rawValue: "Device.onOrientationChanged")
    }
}
