//
//  PinwheelOperation.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 12/15/16.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import Foundation

extension Pinwheel {
    
    class AsyncOperation: NSOperation {
        
        // MARK: - Types
        
        enum State {
            case Ready, Executing, Finished
            func keyPath() -> String {
                switch self {
                case Ready:
                    return "isReady"
                case Executing:
                    return "isExecuting"
                case Finished:
                    return "isFinished"
                }
            }
        }
        
        // MARK: - Properties
        
        var state: State {
            willSet {
                willChangeValueForKey(newValue.keyPath())
                willChangeValueForKey(state.keyPath())
            }
            didSet {
                didChangeValueForKey(oldValue.keyPath())
                didChangeValueForKey(state.keyPath())
            }
        }
        
        // MARK: - Initializers
        
        override init() {
            state = .Ready
            super.init()
        }
        
        // MARK: - NSOperation
        
        override var ready: Bool {
            return super.ready && state == .Ready
        }
        
        override var executing: Bool {
            return state == .Executing
        }
        
        override var finished: Bool {
            return state == .Finished
        }
        
        override var asynchronous: Bool {
            return true
        }
        
    }
    
    class AsyncBlockOperation: AsyncOperation {
        
        let executionBlock: (op: AsyncBlockOperation) -> Void
        
        init(_ executionBlock: (op: AsyncBlockOperation) -> Void) {
            self.executionBlock = executionBlock
            super.init()
        }
        
        override func start() {
            super.start()
            state = .Executing
            executionBlock(op: self)
        }
        
        override func cancel() {
            super.cancel()
            state = .Finished
        }
        
        func finish() {
            state = .Finished
        }
        
    }
    
    class DownloadOperation: AsyncOperation {
        
        let task: NSURLSessionDownloadTask
        
        init(_ task: NSURLSessionDownloadTask) {
            self.task = task
            super.init()
        }
        
        override func start() {
            super.start()
            state = .Executing
            task.resume()
        }
        
        override func cancel() {
            super.cancel()
            state = .Finished
            task.cancel()
        }
        
        func finish() {
            state = .Finished
        }
        
    }
}

