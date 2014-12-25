//
//  PinwheelDisplayOptions.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 12/15/16.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import Foundation

public extension Pinwheel {
    
    public struct DisplayOptions {
        public let queuePriority: NSOperationQueuePriority?
        public let timeoutIntervalForRequest: NSTimeInterval?
        public let timeoutIntervalForResource: NSTimeInterval?
        public let diskCache: PinwheelDiskCacheProtocol?
        public let memoryCache: PinwheelMemoryCacheProtocol?
        public let beforeDiskFilters: [PinwheelFilter]
        public let beforeMemoryFilters: [PinwheelFilter]
        public let displayer: PinwheelDisplayer
        
        init (_ builder: Builder) {
            self.queuePriority = builder.queuePriority
            self.timeoutIntervalForRequest = builder.timeoutIntervalForRequest
            self.timeoutIntervalForResource = builder.timeoutIntervalForResource
            self.diskCache = builder.diskCache
            self.memoryCache = builder.memoryCache
            self.beforeDiskFilters = builder.beforeDiskFilters
            self.beforeMemoryFilters = builder.beforeMemoryFilters
            self.displayer = builder.displayer
        }
        
        public class Builder {
            var queuePriority: NSOperationQueuePriority?
            var timeoutIntervalForRequest: NSTimeInterval?
            var timeoutIntervalForResource: NSTimeInterval?
            var diskCache: PinwheelDiskCacheProtocol? = Pinwheel.DiskCache.sharedInstance()
            var memoryCache: PinwheelMemoryCacheProtocol? = Pinwheel.MemoryCache.sharedInstance()
            var beforeDiskFilters = [PinwheelFilter]()
            var beforeMemoryFilters = [PinwheelFilter]()
            var displayer: PinwheelDisplayer = Pinwheel.SimpleDisplayer()
            
            public init () {
            }
            
            public func queuePriority(queuePriority: NSOperationQueuePriority) -> Builder {
                self.queuePriority = queuePriority
                return self
            }
            
            public func timeoutIntervalForRequest(timeoutIntervalForRequest: NSTimeInterval) -> Builder {
                self.timeoutIntervalForRequest = timeoutIntervalForRequest
                return self
            }
            
            public func timeoutIntervalForResource(timeoutIntervalForResource: NSTimeInterval) -> Builder {
                self.timeoutIntervalForResource = timeoutIntervalForResource
                return self
            }
            
            public func diskCache(diskCache: PinwheelDiskCacheProtocol?) -> Builder {
                self.diskCache = diskCache
                return self
            }
            
            public func memoryCache(memoryCache: PinwheelMemoryCacheProtocol?) -> Builder {
                self.memoryCache = memoryCache
                return self
            }
            
            public func addFilter(filter: PinwheelFilter, hook: Hook) -> Builder {
                switch hook {
                case .BeforeDisk:
                    beforeDiskFilters.append(filter)
                case .BeforeMemory:
                    beforeMemoryFilters.append(filter)
                }
                return self
            }
            
            public func displayer(displayer: PinwheelDisplayer) -> Builder {
                self.displayer = displayer
                return self
            }
            
            public func build() -> DisplayOptions {
                return DisplayOptions(self)
            }
        }
    }
}
