//
//  AsyncOperation.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 12/15/16.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import Foundation

class AsyncOperation: NSOperation {

    // MARK: - Types

    enum State: String {
        case Waiting = "isWaiting"
        case Ready = "isReady"
        case Executing = "isExecuting"
        case Finished = "isFinished"
        case Cancelled = "isCancelled"
    }

    // MARK: - Properties

    var state: State {
        willSet {
            willChangeValueForKey(newValue.rawValue)
            willChangeValueForKey(state.rawValue)
        }
        didSet {
            didChangeValueForKey(oldValue.rawValue)
            didChangeValueForKey(state.rawValue)
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

    override var cancelled: Bool {
        return state == .Cancelled
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
        state = .Cancelled
    }

    func finish() {
        state = .Finished
    }

}

class DownloadOperation: AsyncOperation {

    let task: NSURLSessionDownloadTask
    weak var listener: DownlaodListener?

    init(task: NSURLSessionDownloadTask, name: String, listener: DownlaodListener) {
        self.task = task
        self.listener = listener
        super.init()
        self.name = name
    }

    override func start() {
        super.start()
        state = .Executing
        task.resume()
        listener?.onStart()
    }

    override func cancel() {
        super.cancel()
        state = .Cancelled
        task.cancel()
        finish()
    }

    func finish() {
        state = .Finished
    }

}
