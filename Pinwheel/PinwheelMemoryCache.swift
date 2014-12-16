//
//  PinwheelMemoryCache.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 12/15/16.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import UIKit

extension Pinwheel {
    
    class MemoryCache: PinwheelMemoryCacheProtocol {
        
        struct Static {
            static let instance = MemoryCache()
        }
        
        var cache = NSCache()
        
        func get(key: String) -> UIImage? {
            return Static.instance.cache.objectForKey(key) as? UIImage
        }
        
        func set(key: String, image: UIImage) {
            Static.instance.cache.setObject(image, forKey: key)
        }
    }
}
