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

    override func setUp() {
        super.setUp()
        DiskCache.sharedInstance().clear()
        MemoryCache.sharedInstance().clear()
        ImageLoader.setup(Configuration.Builder().debug().build())
        ImageLoader.dumpDownloadQueue()
    }

    override func tearDown() {
        ImageLoader.dumpDownloadQueue()
        ImageLoader.cancelAllRequests()
        super.tearDown()
    }

    func testListenerForSuccess() {
        let listener = TestListener()
        listener.startedExpectation = expectationWithDescription("started")
        listener.cancelOnFail = true
        listener.failedOnFail = true
        listener.completeExpectation = expectationWithDescription("complete")

        let progressListener = TestProgressListener()
        progressListener.progressExpectation = expectationWithDescription("progress")

        let options = DisplayOptions.Builder().build()
        ImageLoader.displayImage(NSURL(string: "https://justaway.info/img/logo.png")!, imageView: UIImageView(), options: options, loadingListener: listener, loadingProgressListener: progressListener)

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
        let listener = TestListener()
        listener.startedExpectation = expectationWithDescription("started")
        listener.cancelOnFail = true
        listener.failedExpectation = expectationWithDescription("failed")
        listener.completeOnFail = true

        let progressListener = TestProgressListener()
        progressListener.progressExpectation = expectationWithDescription("progress")

        let options = DisplayOptions.Builder().build()
        ImageLoader.displayImage(NSURL(string: "https://justaway.info/img/error.png")!, imageView: UIImageView(), options: options, loadingListener: listener, loadingProgressListener: progressListener)

        waitForExpectationsWithTimeout(3) { error in
            ImageLoader.dumpDownloadQueue()
        }
    }

    func testListenerForInvalidContentType() {
        let listener = TestListener()
        listener.startedExpectation = expectationWithDescription("started")
        listener.cancelOnFail = true
        listener.failedExpectation = expectationWithDescription("failed")
        listener.completeOnFail = true

        let options = DisplayOptions.Builder().build()
        ImageLoader.displayImage(NSURL(string: "https://justaway.info/")!, imageView: UIImageView(), options: options, loadingListener: listener)

        waitForExpectationsWithTimeout(3) { error in
            ImageLoader.dumpDownloadQueue()
        }
    }


}
