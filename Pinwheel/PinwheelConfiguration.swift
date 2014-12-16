//
//  PinwheelConfiguration.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 12/17/14.
//  Copyright (c) 2014 aska. All rights reserved.
//

import Foundation

public extension Pinwheel {
    
    public struct Configuration {
        let maxConcurrent: Int
        let defaultQueuePriority: NSOperationQueuePriority
        let isDebug: Bool
        
        init (_ builder: Builder) {
            self.maxConcurrent = builder.maxConcurrent
            self.defaultQueuePriority = builder.defaultQueuePriority
            self.isDebug = builder.isDebug
        }
        
        public class Builder {
            var maxConcurrent = 5
            var defaultQueuePriority = NSOperationQueuePriority.Normal
            var isDebug = false
            
            public init () {
            }
            
            public func maxConcurrent(maxConcurrent: Int) -> Builder {
                self.maxConcurrent = maxConcurrent
                return self
            }
            
            public func defaultQueuePriority(defaultQueuePriority: NSOperationQueuePriority) -> Builder {
                self.defaultQueuePriority = defaultQueuePriority
                return self
            }
            
            public func debug() -> Builder {
                self.isDebug = true
                return self
            }
            
            public func build() -> Configuration {
                return Configuration(self)
            }
        }
    }
}
