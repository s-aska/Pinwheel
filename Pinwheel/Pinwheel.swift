//
//  Pinwheel.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 12/15/16.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import UIKit

public class Pinwheel {
    
    public enum LoadedFrom {
        case Memory
        case Disk
        case Network
    }
    
    public enum Hook {
        case BeforeDisk
        case BeforeMemory
    }
    
    class func DLog(message: String, function: String = __FUNCTION__) {
        if Static.config.isDebug {
            NSLog(message)
        }
    }
    
    class Request {
        let url: NSURL
        let imageView: UIImageView
        let options: DisplayOptions
        let downloadKey: String
        let diskCaheKey: String
        let memoryCaheKey: String
        
        init (url: NSURL, imageView: UIImageView, options: DisplayOptions) {
            self.url = url
            self.imageView = imageView
            self.options = options
            if let key = url.absoluteString {
                self.downloadKey = key
                self.diskCaheKey = join("\t", [key] + options.beforeDiskFilters.map { $0.cacheKey() })
                self.memoryCaheKey = join("\t", [diskCaheKey] + options.beforeMemoryFilters.map { $0.cacheKey() })
            } else {
                // FIXME: implements showImageForEmptyUri.
                assertionFailure("Not implements showImageForEmptyUri.")
            }
        }
        
        func display(image: UIImage, loadedFrom: LoadedFrom) {
            dispatch_async(dispatch_get_main_queue(), {
                self.options.displayer.display(image, imageView: self.imageView, loadedFrom: loadedFrom)
                Pinwheel.DLog("[debug] \(self.downloadKey) display hashValue:\(self.imageView.hashValue)")
            })
        }
    }
    
    struct Static {
        private static let serial = dispatch_queue_create("pw.aska.pinwheel.serial", DISPATCH_QUEUE_SERIAL)
        private static var defaultDisplayImageOptions: DisplayOptions = DisplayOptions.Builder().build()
        private static var imageViewState = [Int: String]()
        private static let queue = NSOperationQueue()
        private static var requests = [String: [Request]]()
        private static var config = Configuration.Builder().build()
    }
    
    public class func setup(config: Configuration) {
        Static.config = config
        Static.queue.maxConcurrentOperationCount = config.maxConcurrent
    }
    
    public class func displayImage(url: NSURL, imageView: UIImageView) {
        self.displayImage(url, imageView: imageView, options: Static.defaultDisplayImageOptions)
    }
    
    public class func displayImage(url: NSURL, imageView: UIImageView, options: DisplayOptions) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, UInt(0)), { ()->() in
            let request = Request(url: url, imageView: imageView, options: options)
            
            dispatch_sync(Static.serial) {
                Static.imageViewState[imageView.hashValue] = request.downloadKey
                self.DLog("[debug] \(request.downloadKey) request hashValue:\(imageView.hashValue)")
            }
            
            if var image = options.memoryCache?.get(request.memoryCaheKey) {
                self.onSuccess(request, image: image, loadedFrom: .Memory)
            } else if let data = options.diskCache?.get(request.diskCaheKey) {
                if var image = UIImage(data: data) {
                    self.onSuccess(request, image: image, loadedFrom: .Disk)
                } else {
                    // FIXME: implements showImageOnFail.
                    assertionFailure("Not implements showImageOnFail.")
                }
            } else {
                dispatch_sync(Static.serial) {
                    if let requests = Static.requests[request.downloadKey] {
                        Static.requests[request.downloadKey] = requests + [request]
                    } else {
                        Static.requests[request.downloadKey] = []
                        let task = DownloadTask(request)
                        task.operation?.queuePriority = options.queuePriority ?? Static.config.defaultQueuePriority
                        Static.queue.addOperation(task.operation!) // Download from Network
                    }
                }
            }
        })
    }
    
    class func filterAndSaveDisk(request: Request, data: NSData) -> UIImage? {
        if var image = UIImage(data: data) {
            
            if request.options.beforeDiskFilters.count > 0 {
                for filter in request.options.beforeDiskFilters {
                    image = filter.filter(image)
                }
                request.options.diskCache?.set(request.diskCaheKey, data: UIImagePNGRepresentation(image))
            } else {
                request.options.diskCache?.set(request.diskCaheKey, data: data)
            }
            
            return image
        }
        return nil
    }
    
    class func filterAndSaveMemory(request: Request, var image: UIImage) -> UIImage {
        for filter in request.options.beforeMemoryFilters {
            image = filter.filter(image)
        }
        request.options.memoryCache?.set(request.memoryCaheKey, image: image)
        return image
    }
    
    class func onSuccess(request: Request, image sourceImage: UIImage, loadedFrom: LoadedFrom) {
        
        var image = sourceImage
        
        if loadedFrom != .Memory {
            image = filterAndSaveMemory(request, image: image)
        }
        
        var displayViews = 0
        var displayViewGroups = 0
        
        dispatch_sync(Static.serial) {
            
            if Static.imageViewState[request.imageView.hashValue] == request.downloadKey {
                request.display(image, loadedFrom: loadedFrom)
                Static.imageViewState.removeValueForKey(request.imageView.hashValue)
                displayViews++
            }
            
            if var stacks = Static.requests.removeValueForKey(request.downloadKey) {
                
                // Check the request has not changed
                stacks = stacks.filter { Static.imageViewState[$0.imageView.hashValue] == request.downloadKey }
                
                // At a minimum cost
                var stackGroup = [String: [Request]]() // memoryCaheKey -> stacks
                for stack in stacks {
                    if stack.memoryCaheKey == request.memoryCaheKey {
                        stack.display(image, loadedFrom: loadedFrom)
                        Static.imageViewState.removeValueForKey(stack.imageView.hashValue)
                        displayViews++
                    } else if stackGroup[stack.memoryCaheKey] != nil {
                        stackGroup[stack.memoryCaheKey]?.append(stack)
                    } else {
                        stackGroup[stack.memoryCaheKey] = [stack]
                        displayViewGroups++
                    }
                }
                
                for memoryCaheKey in Array(stackGroup.keys) {
                    
                    if let stacksInGroup = stackGroup[memoryCaheKey] {
                        var image :UIImage = sourceImage
                        var isFirst = true
                        
                        for stackInGroup in stacksInGroup {
                            if isFirst {
                                image = self.filterAndSaveMemory(stackInGroup, image: image)
                                isFirst = false
                            }
                            stackInGroup.display(image, loadedFrom: loadedFrom)
                            Static.imageViewState.removeValueForKey(stackInGroup.imageView.hashValue)
                            displayViews++
                        }
                    }
                }
            }
        }
        
        DLog("[debug] \(request.downloadKey) views:\(displayViews) groups:\(displayViewGroups) queue views:\(Static.imageViewState.count) urls:\(Static.queue.operationCount)")
    }
    
    class func onFailure(request: Request) {
        dispatch_sync(Static.serial) {
            if Static.imageViewState[request.imageView.hashValue] == request.downloadKey {
                Static.imageViewState.removeValueForKey(request.imageView.hashValue)
            }
            
            if var stacks = Static.requests.removeValueForKey(request.downloadKey) {
                for stack in stacks {
                    if Static.imageViewState[stack.imageView.hashValue] == request.downloadKey {
                        Static.imageViewState.removeValueForKey(stack.imageView.hashValue)
                    }
                }
            }
        }
        
        // FIXME: implements showImageOnFail.
    }
    
    class func onLoadingComplete(request: Request, data: NSData) {
        
        // Check UIImage compatible
        if var image = filterAndSaveDisk(request, data: data) {
            onSuccess(request, image: image, loadedFrom: .Network)
        } else {
            onFailure(request)
            
            DLog("[error] \(request.downloadKey) download failure:Can't convert UIImage")
        }
    }
    
    class func onLoadingFailed(request: Request, error: NSError) {
        onFailure(request)
        
        DLog("[warn] \(request.downloadKey) download failure:\(error.debugDescription)")
    }
}
