![Pinwheel](http://aska.pw/img/pinwheel.svg?2014-12-18)

[![Circle CI](https://circleci.com/gh/s-aska/Pinwheel.svg?style=svg)](https://circleci.com/gh/s-aska/Pinwheel)

Pinwheel is an Image Loading library written in Swift

:warning: **DEVELOPER RELEASE**

## Features

- [ ] Comprehensive Unit Test Coverage
- [x] Carthage support
- [x] Priority control in accordance with the visibility
- [x] Combine HTTP Request to the same URL
- [x] Memory Cache
- [x] Disk Cache
- [x] Timeout Settings ( timeoutIntervalForRequest / timeoutIntervalForResource )
- [ ] Cache Settings
- [ ] ImageLoadingListener


## Architecture

![Architecture](http://aska.pw/img/pinwheel-architecture.svg?2014-12-23)

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

struct MyDisplayOptions {
    static let photo = Pinwheel.DisplayOptions.Builder()
        .displayer(Pinwheel.FadeInDisplayer())
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

    static let userIcon = Pinwheel.DisplayOptions.Builder()
        .addFilter(RoundedFilter(r: 6, w: 42, h: 42), hook: .BeforeMemory)
        .displayer(Pinwheel.FadeInDisplayer())
        .build()

    static let userIconXS = Pinwheel.DisplayOptions.Builder()
        .addFilter(RoundedFilter(r: 2, w: 16, h: 16), hook: .BeforeMemory)
        .displayer(Pinwheel.FadeInDisplayer())
        .build()
}

// photo
Pinwheel.displayImage(url, imageView: imageView, options: MyDisplayOptions.photo)

// user icon
Pinwheel.displayImage(url, imageView: imageView, options: MyDisplayOptions.userIcon)

// small user icon
Pinwheel.displayImage(url, imageView: imageView, options: MyDisplayOptions.userIconXS)


```

### Suspend display queue

```swift
func scrollToTop() {
    Pinwheel.suspend = true
    self.tableView.setContentOffset(CGPointZero, animated: true)
}

func scrollEnd() {
    Pinwheel.suspend = false
}
```

## License

Pinwheel is released under the MIT license. See LICENSE for details.
