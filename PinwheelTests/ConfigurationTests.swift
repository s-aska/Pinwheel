//
//  ConfigurationTests.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 3/26/16.
//  Copyright © 2016 aska. All rights reserved.
//

import Foundation
import XCTest
import Pinwheel

class ConfigurationTests: XCTestCase {
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
}
