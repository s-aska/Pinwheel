//
//  TestServer.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 3/25/16.
//  Copyright © 2016 aska. All rights reserved.
//

import UIKit
import Swifter

class TestServer {
    let server: HttpServer
    let port: in_port_t = 14514

    init() {
        server = HttpServer()

        let rect = CGRect.init(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, UIColor.blackColor().CGColor)
        CGContextFillRect(context, rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let data = UIImagePNGRepresentation(image) else {
            fatalError("UIImagePNGRepresentation failure")
        }

        server["black.png"] = { request in
            guard request.method == "GET" else {
                return .BadRequest(.Text("Method must be GET"))
            }
            let res = Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(data.bytes), count: data.length))
            return HttpResponse.RAW(200, "OK", ["Content-Type": "image/png"], { (writer: HttpResponseBodyWriter) in
                writer.write(res)
            })
        }

        server["index.html"] = { request in
            guard request.method == "GET" else {
                return .BadRequest(.Text("Method must be GET"))
            }
            return .OK(.Html("hello world."))
        }
    }

    func start() throws {
        try server.start(port)
    }

    func stop() {
        server.stop()
    }
}
