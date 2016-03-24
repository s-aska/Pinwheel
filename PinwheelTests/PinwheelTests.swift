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

class PinwheelTests: XCTestCase {

    let server = TestServer()

    override func setUp() {
        super.setUp()
        do {
            try server.start()
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

        class TestListener: ImageLoadingListener {
            private func onLoadingCancelled(url: NSURL, imageView: UIImageView) {
                NSLog("onLoadingCancelled: url:\(url.absoluteString)")
            }
            private func onLoadingComplete(url: NSURL, imageView: UIImageView, image: UIImage, loadedFrom: LoadedFrom) {
                NSLog("onLoadingComplete: url:\(url.absoluteString)")
            }
            private func onLoadingFailed(url: NSURL, imageView: UIImageView, reason: FailureReason) {
                NSLog("onLoadingFailed: url:\(url.absoluteString)")
            }
            private func onLoadingStarted(url: NSURL, imageView: UIImageView) {
                NSLog("onLoadingStarted: url:\(url.absoluteString)")
            }
        }

        ImageLoader.displayImage(NSURL(), imageView: UIImageView(), options: options, loadingListener: TestListener())
        ImageLoader.displayImage(NSURL(string: "http://example.com/")!, imageView: UIImageView(), options: options, loadingListener: TestListener())
        ImageLoader.displayImage(NSURL(string: "http://127.0.0.1:" + server.port.description + "/hoge")!, imageView: UIImageView(), options: options, loadingListener: TestListener())

        XCTAssertEqual(options.queuePriority!, NSOperationQueuePriority.VeryLow)
        XCTAssertEqual(options.timeoutIntervalForRequest!, 8)
        XCTAssertEqual(options.timeoutIntervalForResource!, 9)
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
