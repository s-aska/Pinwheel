//
//  PinwheelDisplayer.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 12/15/16.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import UIKit

public extension Pinwheel {

    public class SimpleDisplayer: PinwheelDisplayer {

        public init() {
        }

        public func display(image: UIImage, imageView: UIImageView, loadedFrom: LoadedFrom) {
            imageView.image = image
        }
    }

    public class FadeInDisplayer: PinwheelDisplayer {

        public init() {
        }

        public func display(image: UIImage, imageView: UIImageView, loadedFrom: LoadedFrom) {
            if loadedFrom == .Network {
                imageView.alpha = 0
                imageView.image = image
                UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: { imageView.alpha = 1 }, completion: nil)
            } else {
                imageView.image = image
            }
        }
    }
}
