//
//  PinwheelRequestBuilder.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 3/18/16.
//  Copyright © 2016 aska. All rights reserved.
//

import Foundation

public extension Pinwheel {

    public class SimpleRequestBuilder: PinwheelRequestBuilder {

        public init() {
        }

        public func build(URL: NSURL) -> NSURLRequest {
            return NSURLRequest(URL: URL)
        }
    }
}
