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
import OHHTTPStubs

class AccessRequestTests: XCTestCase {

    override func setUp() {
        super.setUp()
        DiskCache.sharedInstance().clear()
        MemoryCache.sharedInstance().clear()
        ImageLoader.useBackground = false
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

        let rect = CGRect.init(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, UIColor.blackColor().CGColor)
        CGContextFillRect(context, rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let data = UIImagePNGRepresentation(image) else {
            fatalError("UIImagePNGRepresentation failure")
        }

        stub(isHost("pinwheel-test-ok.org")) { _ in
            return OHHTTPStubsResponse.init(data: data, statusCode: 200, headers: ["Content-Type":"image/jpeg"])
        }

        ImageLoader.displayImage(NSURL(string: "http://pinwheel-test-ok.org/img/logo.png")!, imageView: UIImageView(), options: options, loadingListener: listener, loadingProgressListener: progressListener)

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

        let options = DisplayOptions.Builder().build()

        stub(isHost("pinwheel-test-ng.org")) { _ in
            return OHHTTPStubsResponse.init(data: NSData(), statusCode: 404, headers: ["Content-Type":"text/plain"])
        }

        ImageLoader.displayImage(NSURL(string: "http://pinwheel-test-ng.org/img/error.png")!, imageView: UIImageView(), options: options, loadingListener: listener)

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

        stub(isHost("pinwheel-test-html.org")) { _ in
            return OHHTTPStubsResponse.init(data: NSData(), statusCode: 200, headers: ["Content-Type":"text/plain"])
        }

        let options = DisplayOptions.Builder().build()
        ImageLoader.displayImage(NSURL(string: "http://pinwheel-test-html.org/")!, imageView: UIImageView(), options: options, loadingListener: listener)

        waitForExpectationsWithTimeout(3) { error in
            ImageLoader.dumpDownloadQueue()
        }
    }


}
