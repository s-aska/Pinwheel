//
//  MemoryCache.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 12/15/16.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import UIKit

public class MemoryCache: MemoryCacheProtocol {

    struct Static {
        static let instance = MemoryCache()
    }

    public class func sharedInstance() -> MemoryCache { return Static.instance }

    var cache = NSCache()

    public func get(key: String) -> UIImage? {
        return Static.instance.cache.objectForKey(key) as? UIImage
    }

    public func set(key: String, image: UIImage) {
        Static.instance.cache.setObject(image, forKey: key)
    }

    public func clear() {
        Static.instance.cache.removeAllObjects()
    }
}
