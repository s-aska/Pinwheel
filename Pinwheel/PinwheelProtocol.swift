//
//  PinwheelProtocol.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 12/15/16.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import UIKit

public protocol PinwheelDiskCacheProtocol {
    
    func get(key: String) -> NSData?
    
    func set(key: String, data: NSData)
    
    func remove(key: String)
}

public protocol PinwheelMemoryCacheProtocol {
    
    func get(key: String) -> UIImage?
    
    func set(key: String, image: UIImage)
}

public protocol PinwheelFilter {
    
    func filter(image: UIImage) -> UIImage
    
    func cacheKey() -> String
}

public protocol PinwheelDisplayer {
    
    func display(image: UIImage, imageView: UIImageView, loadedFrom: Pinwheel.LoadedFrom)
}
