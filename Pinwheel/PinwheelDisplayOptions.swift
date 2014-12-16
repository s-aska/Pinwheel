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
        let queuePriority: NSOperationQueuePriority?
        let diskCache: PinwheelDiskCacheProtocol?
        let memoryCache: PinwheelMemoryCacheProtocol?
        let beforeDiskFilters: [PinwheelFilter]
        let beforeMemoryFilters: [PinwheelFilter]
        let displayer: PinwheelDisplayer
        
        init (_ builder: Builder) {
            self.queuePriority = builder.queuePriority
            self.diskCache = builder.diskCache
            self.memoryCache = builder.memoryCache
            self.beforeDiskFilters = builder.beforeDiskFilters
            self.beforeMemoryFilters = builder.beforeMemoryFilters
            self.displayer = builder.displayer
        }
        
        public class Builder {
            var queuePriority: NSOperationQueuePriority?
            var diskCache: PinwheelDiskCacheProtocol? = Pinwheel.DiskCache()
            var memoryCache: PinwheelMemoryCacheProtocol? = Pinwheel.MemoryCache()
            var beforeDiskFilters = [PinwheelFilter]()
            var beforeMemoryFilters = [PinwheelFilter]()
            var displayer: PinwheelDisplayer = Pinwheel.SimpleDisplayer()
            
            public init () {
            }
            
            public func queuePriority(queuePriority: NSOperationQueuePriority) -> Builder {
                self.queuePriority = queuePriority
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
