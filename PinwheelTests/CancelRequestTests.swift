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
import OHHTTPStubs

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

        let options = DisplayOptions.Builder().build()

        stub(isHost("pinwheel-test-delay-url.org")) { _ in
            return OHHTTPStubsResponse.init(data: NSData(), statusCode: 200, headers: ["Content-Type":"image/jpeg"]).requestTime(1.0, responseTime: 2.0)
        }

        ImageLoader.displayImage(NSURL(string: "http://pinwheel-test-delay-url.org/")!, imageView: UIImageView(), options: options, loadingListener: listener)

        ImageLoader.cancelRequest(NSURL(string: "http://pinwheel-test-delay-url.org/")!)

        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(ImageLoader.downloadQueueCount, 0, "downloadQueueCount")
    }

    func testListenerForCancelByUIImageView() {
        let imageView = UIImageView()

        let listener = TestListener()
        listener.startedExpectation = expectationWithDescription("started")
        listener.cancelExpectation = expectationWithDescription("cancel")
        listener.failedOnFail = true
        listener.completeOnFail = true

        let options = DisplayOptions.Builder().build()

        stub(isHost("pinwheel-test-delay-image.org")) { _ in
            return OHHTTPStubsResponse.init(data: NSData(), statusCode: 200, headers: ["Content-Type":"image/jpeg"]).requestTime(1.0, responseTime: 2.0)
        }

        ImageLoader.displayImage(NSURL(string: "http://pinwheel-test-delay-image.org/")!, imageView: imageView, options: options, loadingListener: listener)

        ImageLoader.cancelRequest(imageView)

        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(ImageLoader.downloadQueueCount, 0, "downloadQueueCount")
    }

    func testListenerForCancelAllRequests() {
        let listener = TestListener()
        listener.startedExpectation = expectationWithDescription("started")
        listener.cancelExpectation = expectationWithDescription("cancel")
        listener.failedOnFail = true
        listener.completeOnFail = true

        let options = DisplayOptions.Builder().build()

        stub(isHost("pinwheel-test-delay-all.org")) { _ in
            return OHHTTPStubsResponse.init(data: NSData(), statusCode: 200, headers: ["Content-Type":"image/jpeg"]).requestTime(1.0, responseTime: 2.0)
        }

        ImageLoader.displayImage(NSURL(string: "http://pinwheel-test-delay-all.org/")!, imageView: UIImageView(), options: options, loadingListener: listener)
        ImageLoader.cancelAllRequests()

        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(ImageLoader.downloadQueueCount, 0, "downloadQueueCount")
    }

    func testListenerForCancelRequestBeforeStart() {
        let imageView = UIImageView()

        let listener = TestListener()
        listener.startedOnFail = true
        listener.cancelExpectation = expectationWithDescription("cancel")
        listener.failedOnFail = true
        listener.completeOnFail = true

        let options = DisplayOptions.Builder().build()

        ImageLoader.downloadQueueSuspend = true
        ImageLoader.displayImage(NSURL(string: "http://example.jp/1.png")!, imageView: imageView, options: options, loadingListener: listener)
        ImageLoader.dumpDownloadQueue()
        ImageLoader.cancelAllRequests()

        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(ImageLoader.downloadQueueCount, 0, "downloadQueueCount")

        ImageLoader.downloadQueueSuspend = false
    }
}
