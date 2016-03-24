//
//  TestServer.swift
//  Pinwheel
//
//  Created by Shinichiro Aska on 3/25/16.
//  Copyright © 2016 aska. All rights reserved.
//

import Foundation
import Swifter

class TestServer {
    let server: HttpServer
    let port: in_port_t = 14514
    
    init() {
        server = HttpServer()
        server["hoge"] = { request in
            guard request.method == "GET" else {
                return .BadRequest(.Text("Method must be GET"))
            }
            return .OK(.Text("hoge"))
        }
    }

    func start() throws {
        try server.start(port)
    }
    
    func stop() {
        server.stop()
    }
}
