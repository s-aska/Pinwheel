![Pinwheel](http://aska.pw/img/pinwheel.svg?2014-12-18)

[![Circle CI](https://circleci.com/gh/s-aska/Pinwheel.svg?style=svg)](https://circleci.com/gh/s-aska/Pinwheel)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![](https://img.shields.io/badge/Xcode-7.0%2B-brightgreen.svg?style=flat)]()
[![](https://img.shields.io/badge/iOS-8.0%2B-brightgreen.svg?style=flat)]()

Pinwheel is an Image Loading library written in Swift

## Features

- [ ] Comprehensive Unit Test Coverage
- [x] Carthage support
- [x] Priority control in accordance with the visibility
- [x] Combine HTTP Request to the same URL
- [x] Memory Cache
- [x] Disk Cache
- [x] Timeout Settings ( timeoutIntervalForRequest / timeoutIntervalForResource )
- [x] Cache Settings
- [x] ImageLoadingListener


## Architecture

![Architecture](http://aska.pw/img/pinwheel-architecture.svg?2014-12-23)

## Usage

### Minimum

```swift
ImageLoader.displayImage(url, imageView: imageView)
```

### Optimized for violent scroll. eg. Twitter Client

With `.BeforeMemory`, it is individually cache.

memory Many consume, but the cost of the display is low.

`.BeforeMemory` is sufficient if you do not use waterfall layout.

```swift
import UIKit
import Pinwheel

struct MyDisplayOptions {
    static let photo = DisplayOptions.Builder()
        .displayer(FadeInDisplayer())
        .queuePriority(NSOperationQueuePriority.Low)
        .prepare { (imageView) -> Void in
            // run only at the time of download
            imageView.image = UIImage(named: "Loading")
        }
        .failure { (imageView, reason, error, requestURL) -> Void in
            switch reason {
            case .EmptyUri:
                imageView.image = UIImage(named: "Empty")
            case .InvalidData:
                imageView.image = UIImage(named: "Broken")
            case .NetworkError:
                imageView.image = UIImage(named: "Cancel")
            }
        }
        .build()

    static let userIcon = DisplayOptions.Builder()
        .addFilter(RoundedFilter(r: 6, w: 42, h: 42), hook: .BeforeMemory)
        .displayer(FadeInDisplayer())
        .build()

    static let userIconXS = DisplayOptions.Builder()
        .addFilter(RoundedFilter(r: 2, w: 16, h: 16), hook: .BeforeMemory)
        .displayer(FadeInDisplayer())
        .build()
}

// photo
ImageLoader.displayImage(url, imageView: imageView, options: MyDisplayOptions.photo)

// user icon
ImageLoader.displayImage(url, imageView: imageView, options: MyDisplayOptions.userIcon)

// small user icon
ImageLoader.displayImage(url, imageView: imageView, options: MyDisplayOptions.userIconXS)


```

### Suspend display queue

```swift
func scrollToTop() {
    ImageLoader.suspend = true
    self.tableView.setContentOffset(CGPointZero, animated: true)
}

func scrollEnd() {
    ImageLoader.suspend = false
}
```


### Cache Settings

```swift
// Simple
DiskCache.sharedInstance().cacheSize(10 * 1024 * 1024)

// Professional
DisplayOptions.Builder()
    .diskCache(YourDiskCache())
    .memoryCache(YourMemoryCache())
    .build()
```


### ImageLoadingListener / ImageLoadingProgressListener

```swift
class DebugListener: ImageLoadingListener {
    func onLoadingCancelled(url: NSURL, imageView: UIImageView) {
        NSLog("onLoadingCancelled: url:\(url.absoluteString)")
    }
    func onLoadingComplete(url: NSURL, imageView: UIImageView, image: UIImage, loadedFrom: LoadedFrom) {
        NSLog("onLoadingComplete: url:\(url.absoluteString)")
    }
    func onLoadingFailed(url: NSURL, imageView: UIImageView, reason: FailureReason) {
        NSLog("onLoadingFailed: url:\(url.absoluteString)")
    }
    func onLoadingStarted(url: NSURL, imageView: UIImageView) {
        NSLog("onLoadingStarted: url:\(url.absoluteString)")
    }
}

class DebugProgressListener: ImageLoadingProgressListener {
    func onProgressUpdate(url: NSURL, imageView: UIImageView, current: Int64, total: Int64) {
        NSLog("onProgressUpdate: url:\(url.absoluteString) \(current)/\(total)")
    }
}

ImageLoader.displayImage(url, imageView: imageView, options: Static.defaultOptions,
    loadingListener: DebugListener(),
    loadingProgressListener: DebugProgressListener())
```


## Requirements

- iOS 8.0+
- Xcode 7.3+


## Installation

#### Carthage

Add the following line to your [Cartfile](https://github.com/carthage/carthage)

```
github "s-aska/Pinwheel"
```

#### CocoaPods

Add the following line to your [Podfile](https://guides.cocoapods.org/)

```
use_frameworks!
pod 'Pinwheel', :git => 'git@github.com:s-aska/Pinwheel.git'
```


## License

Pinwheel is released under the MIT license. See LICENSE for details.
