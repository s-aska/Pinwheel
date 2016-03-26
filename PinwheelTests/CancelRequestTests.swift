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

    let server = TestServer()

    override func setUp() {
        super.setUp()
        DiskCache.sharedInstance().clear()
        MemoryCache.sharedInstance().clear()
        ImageLoader.setup(Configuration.Builder().debug().build())
        ImageLoader.dumpDownloadQueue()
        do {
            try self.server.start(11453)
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
        guard let url = NSURL(string: "http://127.0.0.1:11453" + path) else {
            fatalError("Failed to getURL")
        }
        return url
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
