//
//  DiskCache.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 12/15/16.
//  Copyright (c) 2014 Shinichiro Aska. All rights reserved.
//

import Foundation
import CryptoSwift

public class DiskCache: DiskCacheProtocol {

    // MARK: - Singleton

    struct Static {
        private static let instance = DiskCache(dir: DiskCache.defaultDir())
    }

    public class func sharedInstance() -> DiskCache { return Static.instance }

    // MARK: - Types

    let dir: String
    let dirURL: NSURL
    var totalSize: UInt64 = 0
    var cacheSize: UInt64 = 10 * 1024 * 1024 // 10MB
    let queue = NSOperationQueue()
    var fileURLs = [NSURL]()

    // MARK: - Initializer

    private init (dir: String) {
        self.queue.maxConcurrentOperationCount = 1
        self.dir = dir
        self.dirURL = NSURL(fileURLWithPath: self.dir)

        let fileManager = NSFileManager.defaultManager()
        if !fileManager.fileExistsAtPath(dir) {
            do {
                try fileManager.createDirectoryAtPath(dir, withIntermediateDirectories: true, attributes: nil)
            } catch {
            }
        }

        queue.addOperation(AsyncBlockOperation({ [unowned self] (op: AsyncBlockOperation) in
            do {
                let fileManager = NSFileManager.defaultManager()
                let keys = [NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey]
                let options = NSDirectoryEnumerationOptions()
                let fileURLs = try fileManager.contentsOfDirectoryAtURL(self.dirURL, includingPropertiesForKeys: keys, options: options)
                let sortedFileURLs = fileURLs.sort({(URL1: NSURL, URL2: NSURL) -> Bool in

                    var value1: AnyObject?
                    do {
                        try URL1.getResourceValue(&value1, forKey: NSURLContentModificationDateKey)
                    } catch {
                        return true
                    }

                    var value2: AnyObject?
                    do {
                        try URL2.getResourceValue(&value2, forKey: NSURLContentModificationDateKey)
                    } catch {
                        return false
                    }

                    if let string1 = value1 as? String {
                        if let string2 = value2 as? String {
                            return string1 < string2
                        }
                    }

                    if let date1 = value1 as? NSDate {
                        if let date2 = value2 as? NSDate {
                            return date1.compare(date2) == NSComparisonResult.OrderedAscending
                        }
                    }

                    if let number1 = value1 as? NSNumber {
                        if let number2 = value2 as? NSNumber {
                            return number1.compare(number2) == NSComparisonResult.OrderedAscending
                        }
                    }

                    return false
                })

                self.fileURLs = sortedFileURLs

                for fileURL in sortedFileURLs {
                    self.totalSize += self.size(url: fileURL)
                }
            } catch {
            }
            Loader.DLog("[debug] disk cache init disk usage total \(self.fileURLs.count) files \(self.totalSize) bytes")
            self.diet()
            op.finish()
            }))
    }

    // MARK: - Public Methods

    private class func defaultDir() -> String {
        let cachesPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as NSString
        return cachesPath.stringByAppendingPathComponent("Pinwheel.DiskCache")
    }

    public func cacheSize(cacheSize: UInt64) {
        self.cacheSize = cacheSize
    }

    public func get(key: String) -> NSData? {
        let path = pathForKey(key)

        let fileManager = NSFileManager.defaultManager()
        if !fileManager.fileExistsAtPath(path) {
            return nil
        }

        let data: NSData?
        do {
            data = try NSData(contentsOfFile: path, options: [])
        } catch let error as NSError {
            Loader.DLog("[error] \(key) disk cache read error:\(error.debugDescription)")
            return nil
        }

        queue.addOperation(AsyncBlockOperation({ [unowned self] (op: AsyncBlockOperation) in
            let now = NSDate()
            do {
                try fileManager.setAttributes([NSFileModificationDate : now], ofItemAtPath: path)
            } catch let error as NSError {
                Loader.DLog("[error] \(key) disk cache setAttributes error:\(error.debugDescription)")
            } catch {
                fatalError()
            }
            let fileURL = NSURL(fileURLWithPath: path)
            self.fileURLs = self.fileURLs.filter { $0 != fileURL }
            self.fileURLs.append(fileURL)
            op.finish()
            }))

        return data
    }

    public func set(key: String, data: NSData) {
        let path = pathForKey(key)
        let oldSize = self.size(path: path)
        do {
            try data.writeToFile(path, options: NSDataWritingOptions.AtomicWrite)
        } catch let error as NSError {
            Loader.DLog("[error] \(key) disk cache write error:\(error.debugDescription)")
            return
        }
        let newSize = self.size(path: path)
        queue.addOperation(AsyncBlockOperation({ [unowned self] (op: AsyncBlockOperation) in
            let fileURL = NSURL(fileURLWithPath: path)
            self.fileURLs = self.fileURLs.filter { $0 != fileURL }
            self.fileURLs.append(fileURL)
            self.totalSize -= oldSize
            self.totalSize += newSize
            Loader.DLog("[debug] \(key) disk cache write success size:\(oldSize) => \(newSize) total \(self.fileURLs.count) files \(self.totalSize) bytes")
            self.diet()
            op.finish()
            }))
    }

    public func remove(key: String) {
        let path = pathForKey(key)
        let fileURL = NSURL(fileURLWithPath: path)
        let oldSize = self.size(url: fileURL)
        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.removeItemAtPath(path)
        } catch let error as NSError {
            Loader.DLog("[error] disk cache removeItemAtPath:\(path) error:\(error.description)")
            return
        }
        queue.addOperation(AsyncBlockOperation({ [unowned self] (op: AsyncBlockOperation) in
            self.totalSize -= oldSize
            self.fileURLs = self.fileURLs.filter { $0 != fileURL }
            Loader.DLog("[debug] \(key) disk cache remove success size:\(oldSize) => 0 total \(self.fileURLs.count) files \(self.totalSize) bytes")
            op.finish()
            }))
    }

    public func clear() {
        queue.addOperation(AsyncBlockOperation({ [unowned self] (op: AsyncBlockOperation) in
            let fileManager = NSFileManager.defaultManager()
            self.fileURLs = self.fileURLs.filter({ (fileURL: NSURL) -> Bool in
                if let path = fileURL.path {
                    let oldSize = self.size(url: fileURL)
                    do {
                        try fileManager.removeItemAtPath(path)
                        self.totalSize -= oldSize
                        return false
                    } catch let error as NSError {
                        Loader.DLog("[error] disk cache removeItemAtPath:\(path) error:\(error.description)")
                    } catch {
                        fatalError()
                    }
                }
                return true
            })
            Loader.DLog("[debug] disk cache clear disk usage total \(self.fileURLs.count) files \(self.totalSize) bytes")
            op.finish()
            }))
    }

    public func pathForKey(key: String) -> String {
        let filename = key.md5()
        return NSString(string: dir).stringByAppendingPathComponent(filename)
    }

    public func diet() {
        if self.cacheSize >= self.totalSize {
            return
        }

        let fileManager = NSFileManager.defaultManager()
        self.fileURLs = self.fileURLs.filter({ (fileURL: NSURL) -> Bool in
            if self.cacheSize < self.totalSize {
                if let path = fileURL.path {
                    let oldSize = self.size(url: fileURL)
                    do {
                        try fileManager.removeItemAtPath(path)
                        self.totalSize -= oldSize
                        return false
                    } catch let error as NSError {
                        Loader.DLog("[error] disk cache removeItemAtPath:\(path) error:\(error.description)")
                    } catch {
                        fatalError()
                    }
                }
            }
            return true
        })

        Loader.DLog("[debug] disk cache diet disk usage total \(self.fileURLs.count) files \(self.totalSize) bytes")
    }

    public func waitUntilAllOperationsAreFinished() {
        queue.waitUntilAllOperationsAreFinished()
    }

    // MARK: - Private Methods

    private func size(url url: NSURL) -> UInt64 {
        var value: AnyObject?
        do {
            try url.getResourceValue(&value, forKey: NSURLTotalFileAllocatedSizeKey)
        } catch {
        }
        if let number = value as? NSNumber {
            return UInt64(number.longLongValue)
        } else {
            return 0
        }
    }

    private func size(path path: String) -> UInt64 {
        return self.size(url: NSURL(fileURLWithPath: path))
    }
}
