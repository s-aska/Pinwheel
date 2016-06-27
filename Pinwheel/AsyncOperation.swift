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
        case Ready = "isReady"
        case Executing = "isExecuting"
        case Finished = "isFinished"
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
        task.cancel()
        finish()
    }

    func finish() {
        switch state {
        case .Ready:
            // Fix warning message `went isFinished=YES without being started by the queue it is in`
            state = .Executing
            state = .Finished
        case .Executing:
            state = .Finished
        case .Finished:
            break
        }
    }

}
