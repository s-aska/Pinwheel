//
//  TestListener.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 3/26/16.
//  Copyright © 2016 aska. All rights reserved.
//

import Foundation
import XCTest
import Pinwheel

class TestListener: ImageLoadingListener {
    weak var startedExpectation: XCTestExpectation?
    weak var cancelExpectation: XCTestExpectation?
    weak var failedExpectation: XCTestExpectation?
    weak var completeExpectation: XCTestExpectation?
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
