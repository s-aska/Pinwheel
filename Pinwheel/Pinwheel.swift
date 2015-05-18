//
//  Pinwheel.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 12/15/16.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import UIKit

public class Pinwheel {
    
    // MARK: - Types
    
    public enum LoadedFrom {
        case Memory
        case Disk
        case Network
    }
    
    public enum FailureReason {
        case EmptyUri
        case InvalidData
        case NetworkError
    }
    
    public enum Hook {
        case BeforeDisk
        case BeforeMemory
    }
    
    struct Static {
        private static let serial = dispatch_queue_create("pw.aska.pinwheel.serial", DISPATCH_QUEUE_SERIAL)
        private static var defaultDisplayImageOptions: DisplayOptions = DisplayOptions.Builder().build()
        private static var imageViewState = [Int: String]()
        private static let queue = NSOperationQueue()
        private static var requests = [String: [Request]]()
        private static var config = Configuration.Builder().build()
        private static let displayQueue = NSOperationQueue()
    }
    
    public class var suspend: Bool {
        get { return Static.displayQueue.suspended }
        set { Static.displayQueue.suspended = newValue }
    }
    
    // MARK: - Request
    
    class Request {
        let url: NSURL
        let imageView: UIImageView
        let options: DisplayOptions
        let downloadKey: String
        let diskCaheKey: String
        let memoryCaheKey: String
        
        init(url: NSURL, key: String, imageView: UIImageView, options: DisplayOptions) {
            self.url = url
            self.imageView = imageView
            self.options = options
            self.downloadKey = key
            self.diskCaheKey = join("\t", [key] + options.beforeDiskFilters.map { $0.cacheKey() })
            self.memoryCaheKey = join("\t", [diskCaheKey] + options.beforeMemoryFilters.map { $0.cacheKey() })
        }
        
        func display(image: UIImage, loadedFrom: LoadedFrom) {
            Static.displayQueue.addOperation(AsyncBlockOperation({ op in
                dispatch_sync(Static.serial) {
                    if Static.imageViewState.removeValueForKey(self.imageView.hashValue) == self.downloadKey {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.options.displayer.display(image, imageView: self.imageView, loadedFrom: loadedFrom)
                            op.finish()
                            Pinwheel.DLog("[debug] \(self.downloadKey) display hashValue:\(self.imageView.hashValue)")
                        })
                    } else {
                        op.finish()
                    }
                }
            }))
        }
    }
    
    // MARK: - Public Methods
    
    public class func setup(config: Configuration) {
        Static.config = config
        Static.queue.maxConcurrentOperationCount = config.maxConcurrent
        Static.displayQueue.maxConcurrentOperationCount = config.maxConcurrent
    }
    
    public class func displayImage(url: NSURL, imageView: UIImageView) {
        self.displayImage(url, imageView: imageView, options: Static.defaultDisplayImageOptions)
    }
    
    public class func displayImage(url: NSURL, imageView: UIImageView, options: DisplayOptions) {
        if let key = url.absoluteString {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, UInt(0)), { ()->() in
                let request = Request(url: url, key: key, imageView: imageView, options: options)
                dispatch_sync(Static.serial) {
                    let oldDownloadKeyOpt = Static.imageViewState[imageView.hashValue]
                    Static.imageViewState[imageView.hashValue] = request.downloadKey
                    Pinwheel.DLog("[debug] \(request.downloadKey) request hashValue:\(imageView.hashValue)")
                    if let oldDownloadKey = oldDownloadKeyOpt {
                        let visibles = Array(Static.imageViewState.values.filter { $0 == oldDownloadKey })
                        if visibles.count == 0 {
                            let queuePriority = NSOperationQueuePriority.VeryLow
                            let count = self.updateQueuePriorityByName(oldDownloadKey, queuePriority: queuePriority)
                            if count > 0 {
                                Pinwheel.DLog("[debug] \(oldDownloadKey) priority down \(count) operations")
                            }
                        }
                    }
                }
                
                if var image = options.memoryCache?.get(request.memoryCaheKey) {
                    self.onSuccess(request, image: image, loadedFrom: .Memory)
                } else if let data = options.diskCache?.get(request.diskCaheKey) {
                    if var image = UIImage(data: data) {
                        self.onSuccess(request, image: image, loadedFrom: .Disk)
                    } else {
                        options.diskCache?.remove(request.diskCaheKey)
                        if let failure = options.failure {
                            dispatch_async(dispatch_get_main_queue(), {
                                failure(imageView, .InvalidData, self.error("invalid data from disk cache key:\(request.diskCaheKey)."), url)
                            })
                        }
                    }
                } else {
                    if let prepare = options.prepare {
                        dispatch_async(dispatch_get_main_queue(), {
                            prepare(imageView)
                        })
                    }
                    dispatch_sync(Static.serial) {
                        let queuePriority = options.queuePriority ?? Static.config.defaultQueuePriority
                        if let requests = Static.requests[request.downloadKey] {
                            Static.requests[request.downloadKey] = requests + [request]
                            let count = self.updateQueuePriorityByName(request.downloadKey, queuePriority: queuePriority)
                            if count > 0 {
                                Pinwheel.DLog("[debug] \(request.downloadKey) priority up \(count) operations")
                            }
                        } else {
                            Static.requests[request.downloadKey] = []
                            let task = DownloadTask(request)
                            task.operation?.queuePriority = queuePriority
                            Static.queue.addOperation(task.operation!) // Download from Network
                        }
                    }
                }
            })
        } else if let failure = options.failure {
            dispatch_async(dispatch_get_main_queue(), {
                failure(imageView, .EmptyUri, self.error("empty url."), url)
            })
        }
    }
    
    // MARK: - QueueManager
    
    class func updateQueuePriorityByName(name: String, queuePriority: NSOperationQueuePriority) -> Int {
        var count = 0
        for operation in Static.queue.operations as! [Pinwheel.DownloadOperation] {
            if operation.name == name && operation.queuePriority != queuePriority {
                operation.queuePriority = queuePriority
                count++
            }
        }
        return count
    }
    
    // MARK: - Logger
    
    class func DLog(message: String, function: String = __FUNCTION__) {
        if Static.config.isDebug {
            NSLog(message)
        }
    }
    
    // MARK: - Filter
    
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
    
    // MARK: - Event
    
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
                            displayViews++
                        }
                    }
                }
            }
        }
        
        DLog("[debug] \(request.downloadKey) views:\(displayViews) groups:\(displayViewGroups) queue:\(Static.queue.operationCount)")
    }
    
    class func onFailure(request: Request, reason: FailureReason, error: NSError) {
        dispatch_sync(Static.serial) {
            if Static.imageViewState[request.imageView.hashValue] == request.downloadKey {
                Static.imageViewState.removeValueForKey(request.imageView.hashValue)
                if let failure = request.options.failure {
                    dispatch_async(dispatch_get_main_queue(), {
                        failure(request.imageView, reason, error, request.url)
                    })
                }
            }
            
            if var stacks = Static.requests.removeValueForKey(request.downloadKey) {
                for stack in stacks {
                    if Static.imageViewState[stack.imageView.hashValue] == request.downloadKey {
                        Static.imageViewState.removeValueForKey(stack.imageView.hashValue)
                        if let failure = stack.options.failure {
                            dispatch_async(dispatch_get_main_queue(), {
                                failure(stack.imageView, reason, error, stack.url)
                            })
                        }
                    }
                }
            }
        }
        
        // FIXME: implements showImageOnFail.
    }
    
    class func error(description: String) -> NSError {
        let userInfo = [ NSLocalizedDescriptionKey: description ]
        return NSError(domain: "pw.aska.Pinwheel", code: 1, userInfo: userInfo)
    }
    
    // MARK: - NSURLSessionDownloadDelegate
    
    class DownloadTask: NSObject, NSURLSessionDownloadDelegate {
        
        let request: Request
        var operation: DownloadOperation?
        
        init(_ request: Request) {
            
            self.request = request
            super.init()
            
            let config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(request.memoryCaheKey + String(NSDate().hashValue))
            
            if let timeoutIntervalForRequest = request.options.timeoutIntervalForRequest ?? Static.config.defaultTimeoutIntervalForRequest {
                config.timeoutIntervalForRequest = timeoutIntervalForRequest
            }
            
            if let timeoutIntervalForResource = request.options.timeoutIntervalForResource ?? Static.config.defaultTimeoutIntervalForResource {
                config.timeoutIntervalForRequest = timeoutIntervalForResource
            }
            
            let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
            
            operation = DownloadOperation(task: session.downloadTaskWithURL(request.url), name: request.downloadKey)
        }
        
        func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
            if let data = NSData(contentsOfURL: location) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, UInt(0)), {
                    // Check UIImage compatible
                    if var image = Pinwheel.filterAndSaveDisk(self.request, data: data) {
                        Pinwheel.onSuccess(self.request, image: image, loadedFrom: .Network)
                    } else {
                        Pinwheel.onFailure(self.request, reason: .InvalidData, error: Pinwheel.error("invalid data from network can't convert UIImage."))
                        Pinwheel.DLog("[error] \(self.request.downloadKey) download failure:Can't convert UIImage")
                    }
                    self.operation?.finish()
                    self.operation = nil
                })
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, UInt(0)), {
                    Pinwheel.onFailure(self.request, reason: .InvalidData, error: Pinwheel.error("invalid data from network can't convert NSData."))
                    Pinwheel.DLog("[error] \(self.request.downloadKey) download failure:Can't convert NSData")
                    self.operation?.cancel()
                    self.operation = nil
                })
            }
        }
        
        func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
            if let e = error {
                Pinwheel.onFailure(request, reason: .NetworkError, error: e)
                Pinwheel.DLog("[warn] \(request.downloadKey) download failure:\(e.debugDescription)")
            }
        }
    }
}
