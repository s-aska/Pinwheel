//
//  CancelRequestTests.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 3/26/16.
//  Copyright © 2016 aska. All rights reserved.
//

import UIKit
import XCTest
import Pinwheel

class CancelRequestTests: XCTestCase {

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

    func testListenerForCancelByURL() {
        let listener = TestListener()
        listener.startedExpectation = expectationWithDescription("started")
        listener.cancelExpectation = expectationWithDescription("cancel")
        listener.failedOnFail = true
        listener.completeOnFail = true

        let progressListener = TestProgressListener()
        progressListener.progressOnFail = true

        let options = DisplayOptions.Builder().build()
        ImageLoader.displayImage(NSURL(string: "https://delay-api.herokuapp.com/")!, imageView: UIImageView(), options: options, loadingListener: listener, loadingProgressListener: progressListener)

        ImageLoader.cancelRequest(NSURL(string: "https://delay-api.herokuapp.com/")!)

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testListenerForCancelByUIImageView() {
        let imageView = UIImageView()

        let listener = TestListener()
        listener.startedExpectation = expectationWithDescription("started")
        listener.cancelExpectation = expectationWithDescription("cancel")
        listener.failedOnFail = true
        listener.completeOnFail = true

        let progressListener = TestProgressListener()
        progressListener.progressOnFail = true

        let options = DisplayOptions.Builder().build()
        ImageLoader.displayImage(NSURL(string: "https://delay-api.herokuapp.com/")!, imageView: imageView, options: options, loadingListener: listener, loadingProgressListener: progressListener)

        ImageLoader.cancelRequest(imageView)

        waitForExpectationsWithTimeout(3, handler: nil)
    }
}
