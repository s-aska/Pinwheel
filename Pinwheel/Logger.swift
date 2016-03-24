//
//  Logger.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 3/24/16.
//  Copyright © 2016 aska. All rights reserved.
//

import Foundation

class Logger {
    class func log(message: String, function: String = #function) {
        if ImageLoader.isDebug {
            NSLog("Pinwheel " + message)
        }
    }
}
