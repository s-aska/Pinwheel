//
//  AccessRequestTests.swift
//  PinwheelTests
//
//  Created by Shinichiro Aska on 12/15/16.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import UIKit
import XCTest
import Pinwheel

class AccessRequestTests: XCTestCase {

    let server = TestServer()

    override func setUp() {
        super.setUp()
        DiskCache.sharedInstance().clear()
        MemoryCache.sharedInstance().clear()
        ImageLoader.setup(Configuration.Builder().debug().build())
        ImageLoader.dumpDownloadQueue()
        do {
            try self.server.start(11452)
            sleep(1)
        } catch {
            XCTFail("Failed to start server")
        }
    }

    override func tearDown() {
        ImageLoader.dumpDownloadQueue()
        ImageLoader.cancelAllRequests()
        server.stop()
        super.tearDown()
    }

    func getTestURL(path: String) -> NSURL {
        guard let url = NSURL(string: "http://127.0.0.1:11452" + path) else {
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

        waitForExpectationsWithTimeout(3) { error in
            ImageLoader.dumpDownloadQueue()
        }
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

        waitForExpectationsWithTimeout(3) { error in
            ImageLoader.dumpDownloadQueue()
        }
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

        waitForExpectationsWithTimeout(3) { error in
            ImageLoader.dumpDownloadQueue()
        }
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

        waitForExpectationsWithTimeout(3) { error in
            ImageLoader.dumpDownloadQueue()
        }
    }


}
