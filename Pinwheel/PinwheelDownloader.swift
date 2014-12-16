//
//  PinwheelDownloader.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 12/15/16.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import Foundation

extension Pinwheel {
    
    class DownloadOperation: AsyncOperation {
        
        let task: NSURLSessionDownloadTask
        
        init(_ task: NSURLSessionDownloadTask) {
            self.task = task
            super.init()
        }
        
        override func start() {
            super.start()
            state = .Executing
            task.resume()
        }
        
        override func cancel() {
            super.cancel()
            state = .Finished
            task.cancel()
        }
        
        func finish() {
            state = .Finished
        }
        
    }
    
    class DownloadTask: NSObject, NSURLSessionDownloadDelegate {
        
        let request: Request
        var operation: DownloadOperation?
        
        init(_ request: Request) {
            
            self.request = request
            super.init()
            
            let config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(request.memoryCaheKey + String(NSDate().hashValue))
            let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
            
            operation = DownloadOperation(session.downloadTaskWithURL(request.url))
        }
        
        func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
            let data = NSData(contentsOfURL: location)
            if data != nil && data?.length > 0 {
                Pinwheel.onLoadingComplete(request, data: data!)
                operation?.finish()
            } else {
                operation?.cancel()
            }
            operation = nil
        }
        
        func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
            if let e = error {
                Pinwheel.onLoadingFailed(request, error: e)
            }
        }
    }
}
