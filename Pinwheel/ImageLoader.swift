//
//  Loader.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 12/15/16.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import UIKit

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

public class ImageLoader {

    // MARK: - Types

    struct Static {
        private static let serial = dispatch_queue_create("pw.aska.pinwheel.serial", DISPATCH_QUEUE_SERIAL)
        private static var defaultDisplayImageOptions: DisplayOptions = DisplayOptions.Builder().build()
        private static var imageViewState = [Int: String]()
        private static var requests = [String: [Request]]()
        private static var config = Configuration.Builder().build()
        private static let downloadQueue = NSOperationQueue()
        private static let displayQueue = NSOperationQueue()
        private static let requestQueue: NSOperationQueue = {
            let queue = NSOperationQueue()
            queue.maxConcurrentOperationCount = 1
            return queue
        }()
    }

    public class var suspend: Bool {
        get { return Static.displayQueue.suspended }
        set { Static.displayQueue.suspended = newValue }
    }

    public class var isDebug: Bool {
        get { return Static.config.isDebug }
    }

    // MARK: - Request

    class Request {
        let url: NSURL
        let imageView: UIImageView
        let options: DisplayOptions
        let downloadKey: String
        let diskCaheKey: String
        let memoryCaheKey: String
        let loadingListener: ImageLoadingListener?
        let loadingProgressListener: ImageLoadingProgressListener?

        init(url: NSURL,
             key: String,
             imageView: UIImageView,
             options: DisplayOptions,
             loadingListener: ImageLoadingListener?,
             loadingProgressListener: ImageLoadingProgressListener?) {
            self.url = url
            self.imageView = imageView
            self.options = options
            self.downloadKey = key
            self.diskCaheKey = ([key] + options.beforeDiskFilters.map { $0.cacheKey() }).joinWithSeparator("\t")
            self.memoryCaheKey = ([diskCaheKey] + options.beforeMemoryFilters.map { $0.cacheKey() }).joinWithSeparator("\t")
            self.loadingListener = loadingListener
            self.loadingProgressListener = loadingProgressListener
        }

        func display(image: UIImage, loadedFrom: LoadedFrom) {
            Static.displayQueue.addOperation(AsyncBlockOperation({ op in
                dispatch_sync(Static.serial) {
                    if Static.imageViewState.removeValueForKey(self.imageView.hashValue) == self.downloadKey {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.options.displayer.display(image, imageView: self.imageView, loadedFrom: loadedFrom)
                            self.loadingListener?.onLoadingComplete(self.url, imageView: self.imageView, image: image, loadedFrom: loadedFrom)
                            op.finish()
                            Logger.log("[debug] \(self.downloadKey) display hashValue:\(self.imageView.hashValue)")
                        })
                    } else {
                        op.finish()
                    }
                }
            }))
        }

        var build: NSURLRequest {
            return options.requestBuilder.build(url)
        }
    }

    // MARK: - Public Methods

    public class func setup(config: Configuration) {
        Static.config = config
        Static.downloadQueue.maxConcurrentOperationCount = config.maxConcurrent
        Static.displayQueue.maxConcurrentOperationCount = config.maxConcurrent
    }

    public class func displayImage(url: NSURL,
                                   imageView: UIImageView,
                                   options: DisplayOptions = Static.defaultDisplayImageOptions,
                                   loadingListener: ImageLoadingListener? = nil,
                                   loadingProgressListener: ImageLoadingProgressListener? = nil) {
        Static.requestQueue.addOperation(AsyncBlockOperation({ op in
            let key = url.absoluteString
            if key.isEmpty {
                loadingListener?.onLoadingFailed(url, imageView: imageView, reason: .EmptyUri)
                if let failure = options.failure {
                    dispatch_async(dispatch_get_main_queue(), {
                        failure(imageView, .EmptyUri, ImageLoader.error("empty url."), url)
                    })
                }
                op.finish()
                return
            }
            let request = Request(url: url, key: key, imageView: imageView, options: options,
                loadingListener: loadingListener, loadingProgressListener: loadingProgressListener)
            dispatch_sync(Static.serial) {
                let oldDownloadKeyOpt = Static.imageViewState[imageView.hashValue]
                Static.imageViewState[imageView.hashValue] = request.downloadKey
                Logger.log("[debug] \(request.downloadKey) request hashValue:\(imageView.hashValue)")
                if let oldDownloadKey = oldDownloadKeyOpt {
                    let visibles = Array(Static.imageViewState.values.filter { $0 == oldDownloadKey })
                    if visibles.count == 0 {
                        let queuePriority = NSOperationQueuePriority.VeryLow
                        let count = self.updateQueuePriorityByName(oldDownloadKey, queuePriority: queuePriority)
                        if count > 0 {
                            Logger.log("[debug] \(oldDownloadKey) priority down \(count) operations")
                        }
                    }
                }
            }

            if let image = options.memoryCache?.get(request.memoryCaheKey) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, UInt(0)), {
                    self.onSuccess(request, image: image, loadedFrom: .Memory)
                })
            } else if let data = options.diskCache?.get(request.diskCaheKey) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, UInt(0)), {
                    if let image = UIImage(data: data) {
                        self.onSuccess(request, image: image, loadedFrom: .Disk)
                    } else {
                        options.diskCache?.remove(request.diskCaheKey)
                        if let failure = options.failure {
                            dispatch_async(dispatch_get_main_queue(), {
                                failure(imageView, .InvalidData, self.error("invalid data from disk cache key:\(request.diskCaheKey)."), url)
                            })
                        }
                    }
                })
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
                            Logger.log("[debug] \(request.downloadKey) priority up \(count) operations")
                        }
                    } else {
                        Static.requests[request.downloadKey] = []
                        let task = DownloadTask(request)
                        if let operation = task.operation {
                            operation.queuePriority = queuePriority
                            Static.downloadQueue.addOperation(operation) // Download from Network
                        }
                    }
                }
            }
            op.finish()
        }))
    }

    public class func cancelRequest(url: NSURL) {
        Static.requestQueue.addOperation(AsyncBlockOperation({ op in
            let key = url.absoluteString
            Static.downloadQueue
                .operations
                .filter({ $0.name == key && !$0.finished })
                .forEach({ $0.cancel() })
            op.finish()
        }))
    }

    public class func cancelRequest(imageView: UIImageView) {
        Static.requestQueue.addOperation(AsyncBlockOperation({ op in
            dispatch_sync(Static.serial) {
                guard let key = Static.imageViewState[imageView.hashValue] else {
                    op.finish()
                    return
                }
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, UInt(0)), {
                    Static.downloadQueue
                        .operations
                        .filter({ $0.name == key && !$0.finished })
                        .forEach({ $0.cancel() })
                    op.finish()
                })
            }
        }))
    }

    public class func cancelAllRequest() {
        Static.requestQueue.addOperation(AsyncBlockOperation({ op in
            Static.downloadQueue
                .operations
                .filter({ !$0.finished })
                .forEach({ $0.cancel() })
            op.finish()
        }))
    }

    // MARK: - QueueManager

    class func updateQueuePriorityByName(name: String, queuePriority: NSOperationQueuePriority) -> Int {
        var count = 0
        for operation in Static.downloadQueue.operations as? [DownloadOperation] ?? [] {
            if operation.name == name && operation.queuePriority != queuePriority {
                operation.queuePriority = queuePriority
                count += 1
            }
        }
        return count
    }

    // MARK: - Filter

    class func filterAndSaveDisk(request: Request, data: NSData) -> UIImage? {
        if var image = UIImage(data: data) {

            if request.options.beforeDiskFilters.count > 0 {
                for filter in request.options.beforeDiskFilters {
                    image = filter.filter(image)
                }
                request.options.diskCache?.set(request.diskCaheKey, data: UIImagePNGRepresentation(image)!)
            } else {
                request.options.diskCache?.set(request.diskCaheKey, data: data)
            }

            return image
        }
        return nil
    }

    class func filterAndSaveMemory(request: Request, image: UIImage) -> UIImage {
        var image = image
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
                displayViews += 1
            }

            if var stacks = Static.requests.removeValueForKey(request.downloadKey) {

                // Check the request has not changed
                stacks = stacks.filter { Static.imageViewState[$0.imageView.hashValue] == request.downloadKey }

                // At a minimum cost
                var stackGroup = [String: [Request]]() // memoryCaheKey -> stacks
                for stack in stacks {
                    if stack.memoryCaheKey == request.memoryCaheKey {
                        stack.display(image, loadedFrom: loadedFrom)
                        displayViews += 1
                    } else if stackGroup[stack.memoryCaheKey] != nil {
                        stackGroup[stack.memoryCaheKey]?.append(stack)
                    } else {
                        stackGroup[stack.memoryCaheKey] = [stack]
                        displayViewGroups += 1
                    }
                }

                for memoryCaheKey in Array(stackGroup.keys) {

                    if let stacksInGroup = stackGroup[memoryCaheKey] {
                        var image: UIImage = sourceImage
                        var isFirst = true

                        for stackInGroup in stacksInGroup {
                            if isFirst {
                                image = self.filterAndSaveMemory(stackInGroup, image: image)
                                isFirst = false
                            }
                            stackInGroup.display(image, loadedFrom: loadedFrom)
                            displayViews += 1
                        }
                    }
                }
            }
        }

        Logger.log("[debug] \(request.downloadKey) views:\(displayViews) groups:\(displayViewGroups) downloadQueue:\(Static.downloadQueue.operationCount)")
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
                if let loadingListener = request.loadingListener {
                    dispatch_async(dispatch_get_main_queue(), {
                        loadingListener.onLoadingFailed(request.url, imageView: request.imageView, reason: reason)
                    })
                }
            }

            if let stacks = Static.requests.removeValueForKey(request.downloadKey) {
                for stack in stacks {
                    if Static.imageViewState[stack.imageView.hashValue] == request.downloadKey {
                        Static.imageViewState.removeValueForKey(stack.imageView.hashValue)
                        if let failure = stack.options.failure {
                            dispatch_async(dispatch_get_main_queue(), {
                                failure(stack.imageView, reason, error, stack.url)
                            })
                        }
                        if let loadingListener = stack.loadingListener {
                            dispatch_async(dispatch_get_main_queue(), {
                                loadingListener.onLoadingFailed(stack.url, imageView: stack.imageView, reason: reason)
                            })
                        }
                    }
                }
            }
        }
    }

    class func onCancel(request: Request) {
        dispatch_sync(Static.serial) {
            if Static.imageViewState[request.imageView.hashValue] == request.downloadKey {
                Static.imageViewState.removeValueForKey(request.imageView.hashValue)
                dispatch_async(dispatch_get_main_queue(), {
                    request.loadingListener?.onLoadingCancelled(request.url, imageView: request.imageView)
                })
            }

            if let stacks = Static.requests.removeValueForKey(request.downloadKey) {
                for stack in stacks {
                    if Static.imageViewState[stack.imageView.hashValue] == request.downloadKey {
                        Static.imageViewState.removeValueForKey(stack.imageView.hashValue)
                        dispatch_async(dispatch_get_main_queue(), {
                            stack.loadingListener?.onLoadingCancelled(stack.url, imageView: stack.imageView)
                        })
                    }
                }
            }
        }
    }

    class func error(description: String) -> NSError {
        let userInfo = [ NSLocalizedDescriptionKey: description ]
        return NSError(domain: "pw.aska.Pinwheel", code: 1, userInfo: userInfo)
    }

    // MARK: - NSURLSessionDownloadDelegate

    class DownloadTask: NSObject, NSURLSessionDownloadDelegate, DownlaodListener {

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
                config.timeoutIntervalForResource = timeoutIntervalForResource
            }

            let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)

            operation = DownloadOperation(task: session.downloadTaskWithRequest(request.build), name: request.downloadKey, listener: self)
        }

        func onStart() {
            request.loadingListener?.onLoadingStarted(request.url, imageView: request.imageView)
        }

        func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            request.loadingProgressListener?.onProgressUpdate(request.url, imageView: request.imageView, current: totalBytesWritten, total: totalBytesExpectedToWrite)
        }

        func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
            if let response = downloadTask.response as? NSHTTPURLResponse {
                if response.statusCode >= 400 {
                    ImageLoader.onFailure(self.request, reason: .InvalidData, error: ImageLoader.error("invalid statusCode [\(response.statusCode)]"))
                    Logger.log("[error] \(self.request.downloadKey) download failure invalid statusCode [\(response.statusCode)]")
                    self.operation?.cancel()
                    self.operation = nil
                    return
                }
                if let contentType = response.allHeaderFields["Content-Type"] as? String {
                    if !contentType.hasPrefix("image/") {
                        ImageLoader.onFailure(self.request, reason: .InvalidData, error: ImageLoader.error("invalid header Content-Type [\(contentType)]"))
                        Logger.log("[error] \(self.request.downloadKey) download failure invalid header Content-Type [\(contentType)]")
                        self.operation?.cancel()
                        self.operation = nil
                        return
                    }
                }
            }
            if let data = NSData(contentsOfURL: location) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, UInt(0)), {
                    // Check UIImage compatible
                    if let image = ImageLoader.filterAndSaveDisk(self.request, data: data) {
                        ImageLoader.onSuccess(self.request, image: image, loadedFrom: .Network)
                    } else {
                        ImageLoader.onFailure(self.request, reason: .InvalidData, error: ImageLoader.error("invalid data from network can't convert UIImage."))
                        Logger.log("[error] \(self.request.downloadKey) download failure:Can't convert UIImage")
                    }
                    self.operation?.finish()
                    self.operation = nil
                })
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, UInt(0)), {
                    ImageLoader.onFailure(self.request, reason: .InvalidData, error: ImageLoader.error("invalid data from network can't convert NSData."))
                    Logger.log("[error] \(self.request.downloadKey) download failure:Can't convert NSData")
                    self.operation?.cancel()
                    self.operation = nil
                })
            }
        }

        func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
            if let e = error {
                if e.localizedDescription == "cancelled" {
                    ImageLoader.onCancel(request)
                    Logger.log("[warn] \(request.downloadKey) download canceled didCompleteWithError:\(e.debugDescription)")
                } else {
                    ImageLoader.onFailure(request, reason: .NetworkError, error: e)
                    Logger.log("[warn] \(request.downloadKey) download failed didCompleteWithError:\(e.debugDescription)")
                }
            }
        }

        func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
            if let e = error {
                if e.localizedDescription == "cancelled" {
                    ImageLoader.onCancel(request)
                    Logger.log("[warn] \(request.downloadKey) download canceled didBecomeInvalidWithError:\(e.debugDescription)")
                } else {
                    ImageLoader.onFailure(request, reason: .NetworkError, error: e)
                    Logger.log("[warn] \(request.downloadKey) download failed didBecomeInvalidWithError:\(e.debugDescription)")
                }
            }
        }
    }
}
