//
//  Protocol.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 12/15/16.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import UIKit

public protocol DiskCacheProtocol {

    func get(key: String) -> NSData?

    func set(key: String, data: NSData)

    func remove(key: String)
}

public protocol MemoryCacheProtocol {

    func get(key: String) -> UIImage?

    func set(key: String, image: UIImage)
}

public protocol Filter {

    func filter(image: UIImage) -> UIImage

    func cacheKey() -> String
}

public protocol Displayer {

    func display(image: UIImage, imageView: UIImageView, loadedFrom: LoadedFrom)
}

public protocol RequestBuilder {

    func build(URL: NSURL) -> NSURLRequest
}
