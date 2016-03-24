//
//  RequestBuilder.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 3/18/16.
//  Copyright © 2016 aska. All rights reserved.
//

import Foundation

public class SimpleRequestBuilder: RequestBuilder {

    public init() {
    }

    public func build(URL: NSURL) -> NSURLRequest {
        return NSURLRequest(URL: URL)
    }
}
