//
//  FSWeakTimer.swift
//  FSAdvertisementView
//
//  Created by fengsh on 12/10/15.
//  Copyright © 2015年 fengsh. All rights reserved.
//
/*
let timer = WeakTimerFactory.timerWithTimeInterval(interval, userInfo: userInfo, repeats: repeats) { [weak self] in
// Your code here...
}
*/

import Foundation


public struct WeakTimerFactory {
    public class WeakTimer: NSObject {
        private var timer: NSTimer!
        private let callback: () -> Void
        
        private init(timeInterval: NSTimeInterval, userInfo: AnyObject?, repeats: Bool, callback: () -> Void) {
            self.callback = callback
            super.init()
            self.timer = NSTimer.scheduledTimerWithTimeInterval(timeInterval, target: self, selector:"invokeCallback", userInfo: userInfo, repeats: repeats)
        }
        
        func invokeCallback() {
            callback()
        }
        
        deinit
        {
            //print("weak timer free")
        }
    }
    
    /// Returns a new timer that has not yet executed, and is not scheduled for execution.
    public static func timerWithTimeInterval(timeInterval: NSTimeInterval, userInfo: AnyObject?, repeats: Bool, callback: () -> Void) -> NSTimer {
        return WeakTimer(timeInterval: timeInterval, userInfo: userInfo, repeats: repeats, callback: callback).timer
    }
}


@objc (FSWeakTimer)
public class FSWeakTimer : NSObject
{
    override init() {
        
    }
    
    public func timerWithTimeInterval(timeInterval: NSTimeInterval, userInfo: AnyObject?, repeats: Bool, callback: () -> Void) -> NSTimer
    {
        return WeakTimerFactory.timerWithTimeInterval(timeInterval, userInfo: userInfo, repeats: repeats, callback: callback)
    }
}