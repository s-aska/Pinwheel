//
//  PinwheelDisplayOptions.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 12/15/16.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import UIKit

public extension Pinwheel {

    public struct DisplayOptions {
        public let queuePriority: NSOperationQueuePriority?
        public let timeoutIntervalForRequest: NSTimeInterval?
        public let timeoutIntervalForResource: NSTimeInterval?
        public let diskCache: PinwheelDiskCacheProtocol?
        public let memoryCache: PinwheelMemoryCacheProtocol?
        public let beforeDiskFilters: [PinwheelFilter]
        public let beforeMemoryFilters: [PinwheelFilter]
        public let requestBuilder: PinwheelRequestBuilder
        public let displayer: PinwheelDisplayer
        public let prepare: ((UIImageView) -> Void)?
        public let failure: ((UIImageView, FailureReason, NSError, NSURL) -> Void)?

        init (_ builder: Builder) {
            self.queuePriority = builder.queuePriority
            self.timeoutIntervalForRequest = builder.timeoutIntervalForRequest
            self.timeoutIntervalForResource = builder.timeoutIntervalForResource
            self.diskCache = builder.diskCache
            self.memoryCache = builder.memoryCache
            self.beforeDiskFilters = builder.beforeDiskFilters
            self.beforeMemoryFilters = builder.beforeMemoryFilters
            self.requestBuilder = builder.requestBuilder
            self.displayer = builder.displayer
            self.prepare = builder.prepare
            self.failure = builder.failure
        }

        public class Builder {
            var queuePriority: NSOperationQueuePriority?
            var timeoutIntervalForRequest: NSTimeInterval?
            var timeoutIntervalForResource: NSTimeInterval?
            var diskCache: PinwheelDiskCacheProtocol? = Pinwheel.DiskCache.sharedInstance()
            var memoryCache: PinwheelMemoryCacheProtocol? = Pinwheel.MemoryCache.sharedInstance()
            var beforeDiskFilters = [PinwheelFilter]()
            var beforeMemoryFilters = [PinwheelFilter]()
            var requestBuilder: PinwheelRequestBuilder = Pinwheel.SimpleRequestBuilder()
            var displayer: PinwheelDisplayer = Pinwheel.SimpleDisplayer()
            var prepare: ((UIImageView) -> Void)?
            var failure: ((UIImageView, FailureReason, NSError, NSURL) -> Void)?

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

            public func requestBuilder(requestBuilder: PinwheelRequestBuilder) -> Builder {
                self.requestBuilder = requestBuilder
                return self
            }

            public func displayer(displayer: PinwheelDisplayer) -> Builder {
                self.displayer = displayer
                return self
            }

            public func prepare(prepare: ((UIImageView) -> Void)?) -> Builder {
                self.prepare = prepare
                return self
            }

            public func failure(failure: ((UIImageView, FailureReason, NSError, NSURL) -> Void)?) -> Builder {
                self.failure = failure
                return self
            }

            public func build() -> DisplayOptions {
                return DisplayOptions(self)
            }
        }
    }
}
