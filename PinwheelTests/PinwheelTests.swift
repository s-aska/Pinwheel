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
    var startedExpectation: XCTestExpectation?
    var cancelExpectation: XCTestExpectation?
    var failedExpectation: XCTestExpectation?
    var completeExpectation: XCTestExpectation?
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
        do {
            try self.server.start()
        } catch {
            XCTFail("Failed to start server")
        }
        ImageLoader.setup(Configuration.Builder().debug().build())
    }

    override func tearDown() {
        server.stop()
        super.tearDown()
    }

    func testConfiguration() {
        let config = Configuration.Builder()
            .maxConcurrent(6)
            .defaultQueuePriority(NSOperationQueuePriority.VeryHigh)
            .defaultTimeoutIntervalForRequest(8)
            .defaultTimeoutIntervalForResource(9)
            .build()

        XCTAssertEqual(config.maxConcurrent, 6)
        XCTAssertEqual(config.defaultQueuePriority, NSOperationQueuePriority.VeryHigh)
        XCTAssertEqual(config.defaultTimeoutIntervalForRequest!, 8)
        XCTAssertEqual(config.defaultTimeoutIntervalForResource!, 9)
    }

    func testDisplayOptions() {
        let options = DisplayOptions.Builder()
            .queuePriority(NSOperationQueuePriority.VeryLow)
            .timeoutIntervalForRequest(8)
            .timeoutIntervalForResource(9)
            .prepare { (image) -> Void in

            }
            .failure { (image, reason, error, url) -> Void in
                switch reason {
                case .EmptyUri:
                    NSLog("EmptyUri \(error)")
                case .InvalidData:
                    NSLog("InvalidData \(error) \(url ?? false)")
                case .NetworkError:
                    NSLog("NetworkError \(error) \(url ?? false)")
                }
            }
            .build()

        XCTAssertEqual(options.queuePriority!, NSOperationQueuePriority.VeryLow)
        XCTAssertEqual(options.timeoutIntervalForRequest!, 8)
        XCTAssertEqual(options.timeoutIntervalForResource!, 9)
    }

    func testDisplayOptionsSuccess() {
        let expectation = self.expectationWithDescription("")

        let options = DisplayOptions.Builder()
            .queuePriority(NSOperationQueuePriority.VeryLow)
            .timeoutIntervalForRequest(8)
            .timeoutIntervalForResource(9)
            .prepare { (image) -> Void in
                expectation.fulfill()
            }
            .failure { (image, reason, error, url) -> Void in
                XCTFail("failure")
            }
            .build()

        ImageLoader.displayImage(getTestURL("/black.png?testDisplayOptionsSuccess"), imageView: UIImageView(), options: options)

        self.waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testDisplayOptionsEmptyUri() {
        let expectation = self.expectationWithDescription("")

        let options = DisplayOptions.Builder()
            .queuePriority(NSOperationQueuePriority.VeryLow)
            .timeoutIntervalForRequest(8)
            .timeoutIntervalForResource(9)
            .failure { (image, reason, error, url) -> Void in
                switch reason {
                case .EmptyUri:
                    expectation.fulfill()
                    NSLog("EmptyUri \(error)")
                case .InvalidData:
                    NSLog("InvalidData \(error) \(url ?? false)")
                case .NetworkError:
                    NSLog("NetworkError \(error) \(url ?? false)")
                }
            }
            .build()

        ImageLoader.displayImage(NSURL(), imageView: UIImageView(), options: options)

        self.waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testDisplayOptionsInvalidData() {
        let expectation = self.expectationWithDescription("")

        let options = DisplayOptions.Builder()
            .queuePriority(NSOperationQueuePriority.VeryLow)
            .timeoutIntervalForRequest(8)
            .timeoutIntervalForResource(9)
            .failure { (image, reason, error, url) -> Void in
                switch reason {
                case .EmptyUri:
                    NSLog("EmptyUri \(error)")
                case .InvalidData:
                    expectation.fulfill()
                    NSLog("InvalidData \(error) \(url ?? false)")
                case .NetworkError:
                    NSLog("NetworkError \(error) \(url ?? false)")
                }
            }
            .build()

        ImageLoader.displayImage(getTestURL("/index.html"), imageView: UIImageView(), options: options)

        self.waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testDisplayOptionsTimeout() {
        let expectation = self.expectationWithDescription("")

        let options = DisplayOptions.Builder()
            .queuePriority(NSOperationQueuePriority.VeryLow)
            .timeoutIntervalForRequest(1)
            .timeoutIntervalForResource(1)
            .failure { (image, reason, error, url) -> Void in
                switch reason {
                case .EmptyUri:
                    NSLog("EmptyUri \(error)")
                case .InvalidData:
                    NSLog("InvalidData \(error) \(url ?? false)")
                case .NetworkError:
                    expectation.fulfill()
                    NSLog("NetworkError \(error) \(url ?? false)")
                }
            }
            .build()

        ImageLoader.displayImage(getTestURL("/large.png?testDisplayOptionsNetworkError"), imageView: UIImageView(), options: options)

        self.waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testDisplayOptionsNetworkError() {
        let expectation = self.expectationWithDescription("")

        let options = DisplayOptions.Builder()
            .queuePriority(NSOperationQueuePriority.VeryLow)
            .timeoutIntervalForRequest(2)
            .timeoutIntervalForResource(2)
            .failure { (image, reason, error, url) -> Void in
                switch reason {
                case .EmptyUri:
                    NSLog("EmptyUri \(error)")
                case .InvalidData:
                    NSLog("InvalidData \(error) \(url ?? false)")
                case .NetworkError:
                    expectation.fulfill()
                    NSLog("NetworkError \(error) \(url ?? false)")
                }
            }
            .build()

        ImageLoader.displayImage(NSURL(string: "http://example.jp/")!, imageView: UIImageView(), options: options)

        self.waitForExpectationsWithTimeout(5, handler: nil)
    }

    func getTestURL(path: String) -> NSURL {
        guard let url = NSURL(string: "http://127.0.0.1:" + self.server.port.description + path) else {
            fatalError("Failed to getURL")
        }
        return url
    }

    func testListenerForSuccess() {
        let path = "/black.png?testListenerForSuccess"

        let listener = TestListener()
        listener.startedExpectation = self.expectationWithDescription(path + " started")
        listener.cancelOnFail = true
        listener.failedOnFail = true
        listener.completeExpectation = self.expectationWithDescription(path + " complete")

        let progressListener = TestProgressListener()
        progressListener.progressExpectation = self.expectationWithDescription(path + " progress")

        let options = DisplayOptions.Builder().build()
        ImageLoader.displayImage(getTestURL(path), imageView: UIImageView(), options: options, loadingListener: listener, loadingProgressListener: progressListener)

        self.waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testListenerForInvalidURL() {
        let listener = TestListener()
        listener.startedOnFail = true
        listener.cancelOnFail = true
        listener.failedExpectation = self.expectationWithDescription("(null) failed")
        listener.completeOnFail = true

        let progressListener = TestProgressListener()
        progressListener.progressOnFail = true

        let options = DisplayOptions.Builder().build()
        ImageLoader.displayImage(NSURL(), imageView: UIImageView(), options: options, loadingListener: listener, loadingProgressListener: progressListener)

        self.waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testListenerForNotFoundURL() {
        let path = "/error.png"

        let listener = TestListener()
        listener.startedExpectation = self.expectationWithDescription(path + " started")
        listener.cancelOnFail = true
        listener.failedExpectation = self.expectationWithDescription(path + " failed")
        listener.completeOnFail = true

        let progressListener = TestProgressListener()
        progressListener.progressOnFail = true

        let options = DisplayOptions.Builder().build()
        ImageLoader.displayImage(getTestURL(path), imageView: UIImageView(), options: options, loadingListener: listener, loadingProgressListener: progressListener)

        self.waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testListenerForInvalidContentType() {
        let path = "/index.html"

        let listener = TestListener()
        listener.startedExpectation = self.expectationWithDescription(path + " started")
        listener.cancelOnFail = true
        listener.failedExpectation = self.expectationWithDescription(path + " failed")
        listener.completeOnFail = true

        let options = DisplayOptions.Builder().build()
        ImageLoader.displayImage(getTestURL(path), imageView: UIImageView(), options: options, loadingListener: listener)

        self.waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testListenerForCancelByURL() {
        let path = "/large.png"

        let listener = TestListener()
        listener.startedExpectation = self.expectationWithDescription(path + " started")
        listener.cancelExpectation = self.expectationWithDescription(path + " cancel")
        listener.failedOnFail = true
        listener.completeOnFail = true

        let progressListener = TestProgressListener()
        progressListener.progressOnFail = true

        let options = DisplayOptions.Builder().build()
        ImageLoader.displayImage(getTestURL(path), imageView: UIImageView(), options: options, loadingListener: listener, loadingProgressListener: progressListener)

        ImageLoader.cancelRequest(getTestURL(path))

        self.waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testListenerForCancelByUIImageView() {
        let path = "/large.png"
        let imageView = UIImageView()

        let listener = TestListener()
        listener.startedExpectation = self.expectationWithDescription(path + " started")
        listener.cancelExpectation = self.expectationWithDescription(path + " cancel")
        listener.failedOnFail = true
        listener.completeOnFail = true

        let progressListener = TestProgressListener()
        progressListener.progressOnFail = true

        let options = DisplayOptions.Builder().build()
        ImageLoader.displayImage(getTestURL(path), imageView: imageView, options: options, loadingListener: listener, loadingProgressListener: progressListener)

        ImageLoader.cancelRequest(imageView)

        self.waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testDiskCache() {
        let diskCache = DiskCache.sharedInstance()
        diskCache.cacheSize(10 * 1024)

        let saveData = "testDiskCache".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        diskCache.set("test", data: saveData)

        let loadData = diskCache.get("test")
        XCTAssertEqual(saveData, loadData!)
        diskCache.remove("test")

        let loadDataAfterRemove = diskCache.get("test")
        XCTAssertTrue(loadDataAfterRemove == nil)

        diskCache.set("test2", data: saveData)
        diskCache.set("test3", data: saveData)
        diskCache.set("test4", data: saveData)
        diskCache.set("test5", data: saveData)
        diskCache.set("test6", data: saveData)

        diskCache.clear()
        diskCache.waitUntilAllOperationsAreFinished()
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
            DiskCache.sharedInstance().pathForKey("https://pbs.twimg.com/profile_images/540166094875406336/_HVCLxmn_reasonably_small.jpeg")
            return
        }
    }

}
