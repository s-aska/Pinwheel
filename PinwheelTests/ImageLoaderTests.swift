//
//  PinwheelTests.swift
//  PinwheelTests
//
//  Created by Shinichiro Aska on 12/15/16.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import UIKit
import XCTest
import Pinwheel

class TestListener: ImageLoadingListener {
    weak var startedExpectation: XCTestExpectation?
    weak var cancelExpectation: XCTestExpectation?
    weak var failedExpectation: XCTestExpectation?
    weak var completeExpectation: XCTestExpectation?
    var startedOnFail = false
    var cancelOnFail = false
    var failedOnFail = false
    var completeOnFail = false
    internal func onLoadingStarted(url: NSURL, imageView: UIImageView) {
        startedExpectation?.fulfill()
        if startedOnFail {
            XCTFail("onLoadingStarted")
        }
        NSLog("Pinwheel [debug] onLoadingStarted: url:\(url.absoluteString)")
    }
    internal func onLoadingCancelled(url: NSURL, imageView: UIImageView) {
        cancelExpectation?.fulfill()
        if cancelOnFail {
            XCTFail("onLoadingCancelled")
        }
        NSLog("Pinwheel [debug] onLoadingCancelled: url:\(url.absoluteString)")
    }
    internal func onLoadingFailed(url: NSURL, imageView: UIImageView, reason: FailureReason) {
        failedExpectation?.fulfill()
        if failedOnFail {
            XCTFail("onLoadingFailed")
        }
        NSLog("Pinwheel [debug] onLoadingFailed: url:\(url.absoluteString)")
    }
    internal func onLoadingComplete(url: NSURL, imageView: UIImageView, image: UIImage, loadedFrom: LoadedFrom) {
        completeExpectation?.fulfill()
        if completeOnFail {
            XCTFail("onLoadingComplete")
        }
        NSLog("Pinwheel [debug] onLoadingComplete: url:\(url.absoluteString)")
    }
}

class TestProgressListener: ImageLoadingProgressListener {
    var progressExpectation: XCTestExpectation?
    var progressOnFail = false
    internal func onProgressUpdate(url: NSURL, imageView: UIImageView, current: Int64, total: Int64) {
        progressExpectation?.fulfill()
        if progressOnFail {
            XCTFail("onProgressUpdate")
        }
        NSLog("Pinwheel [debug] onProgressUpdate: url:\(url.absoluteString) \(current)/\(total)")
    }
}

class PinwheelTests: XCTestCase {

    let server = TestServer()

    override func setUp() {
        super.setUp()
        DiskCache.sharedInstance().clear()
        MemoryCache.sharedInstance().clear()
        ImageLoader.setup(Configuration.Builder().debug().build())
        do {
            try self.server.start()
        } catch {
            XCTFail("Failed to start server")
        }
    }

    override func tearDown() {
        server.stop()
        super.tearDown()
    }

    func getTestURL(path: String) -> NSURL {
        guard let url = NSURL(string: "http://127.0.0.1:" + self.server.port.description + path) else {
            fatalError("Failed to getURL")
        }
        return url
    }

    func testListenerForSuccess() {
        let path = "/black.png"

        let listener = TestListener()
        listener.startedExpectation = expectationWithDescription(path + " started")
        listener.cancelOnFail = true
        listener.failedOnFail = true
        listener.completeExpectation = expectationWithDescription(path + " complete")

        let progressListener = TestProgressListener()
        progressListener.progressExpectation = expectationWithDescription(path + " progress")

        let options = DisplayOptions.Builder().build()
        ImageLoader.displayImage(getTestURL(path), imageView: UIImageView(), options: options, loadingListener: listener, loadingProgressListener: progressListener)

        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testListenerForInvalidURL() {
        let listener = TestListener()
        listener.startedOnFail = true
        listener.cancelOnFail = true
        listener.failedExpectation = expectationWithDescription("(null) failed")
        listener.completeOnFail = true

        let progressListener = TestProgressListener()
        progressListener.progressOnFail = true

        let options = DisplayOptions.Builder().build()
        ImageLoader.displayImage(NSURL(), imageView: UIImageView(), options: options, loadingListener: listener, loadingProgressListener: progressListener)

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testListenerForNotFoundURL() {
        let path = "/error.png"

        let listener = TestListener()
        listener.startedExpectation = expectationWithDescription(path + " started")
        listener.cancelOnFail = true
        listener.failedExpectation = expectationWithDescription(path + " failed")
        listener.completeOnFail = true

        let progressListener = TestProgressListener()
        progressListener.progressOnFail = true

        let options = DisplayOptions.Builder().build()
        ImageLoader.displayImage(getTestURL(path), imageView: UIImageView(), options: options, loadingListener: listener, loadingProgressListener: progressListener)

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testListenerForInvalidContentType() {
        let path = "/index.html"

        let listener = TestListener()
        listener.startedExpectation = expectationWithDescription(path + " started")
        listener.cancelOnFail = true
        listener.failedExpectation = expectationWithDescription(path + " failed")
        listener.completeOnFail = true

        let options = DisplayOptions.Builder().build()
        ImageLoader.displayImage(getTestURL(path), imageView: UIImageView(), options: options, loadingListener: listener)

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testListenerForCancelByURL() {
        let path = "/large.png"

        let listener = TestListener()
        listener.startedExpectation = expectationWithDescription(path + " started")
        listener.cancelExpectation = expectationWithDescription(path + " cancel")
        listener.failedOnFail = true
        listener.completeOnFail = true

        let progressListener = TestProgressListener()
        progressListener.progressOnFail = true

        let options = DisplayOptions.Builder().build()
        ImageLoader.displayImage(getTestURL(path), imageView: UIImageView(), options: options, loadingListener: listener, loadingProgressListener: progressListener)

        ImageLoader.cancelRequest(getTestURL(path))

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testListenerForCancelByUIImageView() {
        let path = "/large.png"
        let imageView = UIImageView()

        let listener = TestListener()
        listener.startedExpectation = expectationWithDescription(path + " started")
        listener.cancelExpectation = expectationWithDescription(path + " cancel")
        listener.failedOnFail = true
        listener.completeOnFail = true

        let progressListener = TestProgressListener()
        progressListener.progressOnFail = true

        let options = DisplayOptions.Builder().build()
        ImageLoader.displayImage(getTestURL(path), imageView: imageView, options: options, loadingListener: listener, loadingProgressListener: progressListener)

        ImageLoader.cancelRequest(imageView)

        waitForExpectationsWithTimeout(3, handler: nil)
    }
}
