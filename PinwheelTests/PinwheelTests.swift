//
//  PinwheelTests.swift
//  PinwheelTests
//
//  Created by aska on 2014/12/16.
//  Copyright (c) 2014年 aska. All rights reserved.
//

import UIKit
import XCTest
import Pinwheel

class PinwheelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testConfiguration() {
        var config = Pinwheel.Configuration.Builder()
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
        var options = Pinwheel.DisplayOptions.Builder()
            .queuePriority(NSOperationQueuePriority.VeryLow)
            .timeoutIntervalForRequest(8)
            .timeoutIntervalForResource(9)
            .build()
        
        XCTAssertEqual(options.queuePriority!, NSOperationQueuePriority.VeryLow)
        XCTAssertEqual(options.timeoutIntervalForRequest!, 8)
        XCTAssertEqual(options.timeoutIntervalForResource!, 9)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
