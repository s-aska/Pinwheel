//
//  DisplayOptionsTests.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 3/26/16.
//  Copyright © 2016 aska. All rights reserved.
//

import Foundation
import XCTest
import Pinwheel

class DisplayOptionsTests: XCTestCase {

    let server = TestServer()

    override func setUp() {
        super.setUp()
        DiskCache.sharedInstance().clear()
        MemoryCache.sharedInstance().clear()
        ImageLoader.setup(Configuration.Builder().debug().build())
        ImageLoader.dumpDownloadQueue()
        do {
            try self.server.start(11451)
        } catch {
            XCTFail("Failed to start server")
        }
    }

    override func tearDown() {
        ImageLoader.dumpDownloadQueue()
        server.stop()
        super.tearDown()
    }

    func getTestURL(path: String) -> NSURL {
        guard let url = NSURL(string: "http://127.0.0.1:11451" + path) else {
            fatalError("Failed to getURL")
        }
        return url
    }

    func testDisplayOptions() {
        let options = DisplayOptions.Builder()
            .queuePriority(NSOperationQueuePriority.VeryLow)
            .timeoutIntervalForRequest(8)
            .timeoutIntervalForResource(9)
            .build()

        XCTAssertEqual(options.queuePriority!, NSOperationQueuePriority.VeryLow)
        XCTAssertEqual(options.timeoutIntervalForRequest!, 8)
        XCTAssertEqual(options.timeoutIntervalForResource!, 9)
    }

    func testDisplayOptionsSuccess() {
        let expectation = expectationWithDescription("")

        let options = DisplayOptions.Builder()
            .prepare { (image) -> Void in
                expectation.fulfill()
            }
            .failure { (image, reason, error, url) -> Void in
                XCTFail("failure")
            }
            .build()

        ImageLoader.displayImage(getTestURL("/black.png"), imageView: UIImageView(), options: options)

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testDisplayOptionsEmptyUri() {
        let expectation = expectationWithDescription("")

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

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testDisplayOptionsInvalidData() {
        let expectation = expectationWithDescription("")

        let options = DisplayOptions.Builder()
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

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testDisplayOptionsTimeout() {
        let expectation = expectationWithDescription("")

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

        ImageLoader.displayImage(getTestURL("/large.png"), imageView: UIImageView(), options: options)

        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testDisplayOptionsNetworkError() {
        let expectation = expectationWithDescription("")

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

        ImageLoader.displayImage(NSURL(string: "http://example.jp/")!, imageView: UIImageView(), options: options)

        waitForExpectationsWithTimeout(3, handler: nil)
    }
}
