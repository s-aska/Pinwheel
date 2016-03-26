//
//  DiskCacheTests.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 3/26/16.
//  Copyright © 2016 aska. All rights reserved.
//

import Foundation
import XCTest
import Pinwheel

class DiskCacheTests: XCTestCase {
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
