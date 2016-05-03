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
import OHHTTPStubs

class DisplayOptionsTests: XCTestCase {

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

        ImageLoader.displayImage(NSURL(string: "https://pinwheel-test-ok.org/img/logo.png")!, imageView: UIImageView(), options: options)

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

        stub(isHost("pinwheel-test-delay-invalid-data.org")) { _ in
            return OHHTTPStubsResponse.init(data: NSData(), statusCode: 200, headers: ["Content-Type":"image/jpeg"])
        }

        ImageLoader.displayImage(NSURL(string: "http://pinwheel-test-delay-invalid-data.org/")!, imageView: UIImageView(), options: options)

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

        stub(isHost("pinwheel-test-delay-timeout.org")) { _ in
            return OHHTTPStubsResponse.init(data: NSData(), statusCode: 200, headers: ["Content-Type":"image/jpeg"]).requestTime(1.5, responseTime: 2.0)
        }

        ImageLoader.displayImage(NSURL(string: "http://pinwheel-test-delay-timeout.org/")!, imageView: UIImageView(), options: options)

        waitForExpectationsWithTimeout(3, handler: nil)
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
