![Pinwheel](http://aska.pw/img/pinwheel.svg?2014-12-18)

[![Build Status](https://travis-ci.org/s-aska/Pinwheel.svg)](https://travis-ci.org/s-aska/Pinwheel)

Pinwheel is an Image Loading library written in Swift

:warning: **DEVELOPER RELEASE**

## Features

- [ ] Comprehensive Unit Test Coverage
- [ ] Carthage support
- [x] Priority control in accordance with the visibility
- [x] Combine HTTP Request to the same URL
- [x] MemoryCache
- [ ] DiskCache
- [x] Timeout Settings (timeoutIntervalForRequest/timeoutIntervalForResource)
- [ ] Cache Settings
- [ ] ImageLoadingListener


## Requirements

- iOS 8+
- Xcode 6.1


## Installation

Create a Cartfile that lists the frameworks you’d like to use in your project.

```bash
echo 'github "s-aska/Pinwheel"' >> Cartfile
```

Run `carthage update`

```bash
carthage update
```

On your application targets’ “General” settings tab, in the “Embedded Binaries” section, drag and drop each framework you want to use from the Carthage.build folder on disk.


## Usage

### Minimum

```swift
Pinwheel.displayImage(url, imageView: imageView)
```

### Optimized for violent scroll. eg. Twitter Client

With `.BeforeMemory`, it is individually cache.

memory Many consume, but the cost of the display is low.

`.BeforeMemory` is sufficient if you do not use waterfall layout.

```swift
import UIKit
import Pinwheel

class ImageLoaderClient {

    struct Options {
        static let picture = Pinwheel.DisplayOptions.Builder()
            .displayer(Pinwheel.FadeInDisplayer())
            .queuePriority(NSOperationQueuePriority.Low)
            .build()

        static let userIcon = Pinwheel.DisplayOptions.Builder()
            .addFilter(RoundedFilter(r: 6, w: 42, h: 42), hook: .BeforeMemory)
            .displayer(Pinwheel.FadeInDisplayer())
            .build()

        static let userIconXS = Pinwheel.DisplayOptions.Builder()
            .addFilter(RoundedFilter(r: 2, w: 16, h: 16), hook: .BeforeMemory)
            .displayer(Pinwheel.FadeInDisplayer())
            .build()
    }

    class func displayImage(url: NSURL, imageView: UIImageView) {
        Pinwheel.displayImage(url, imageView: imageView, options: Options.picture)
    }

    class func displayUserIcon(url: NSURL, imageView: UIImageView) {
        Pinwheel.displayImage(url, imageView: imageView, options: Options.userIcon)
    }

    class func displayUserIconXS(url: NSURL, imageView: UIImageView) {
        Pinwheel.displayImage(url, imageView: imageView, options: Options.userIconXS)
    }
}
```


## License

Pinwheel is released under the MIT license. See LICENSE for details.
