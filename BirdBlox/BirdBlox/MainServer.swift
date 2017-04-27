//
//  MainServer.swift
//  BirdBlox
//
//  Created by birdbrain on 3/21/17.
//  Copyright © 2017 Birdbrain Technologies LLC. All rights reserved.
//

import Foundation
import Swifter

class MainServer {
    let port = 22179
    var server: HttpServer
    let hummingbird_requests: HummingbirdRequests
    let flutter_requests: FlutterRequests
    let data_requests: DataRequests
    let host_device_requests: HostDeviceRequests
    let view_controller: UIViewController
    
    init(view_controller: ViewController){
        self.view_controller = view_controller
        hummingbird_requests = HummingbirdRequests()
        flutter_requests = FlutterRequests()
        data_requests = DataRequests(view_controller: view_controller)
        host_device_requests = HostDeviceRequests(view_controller: view_controller)
        server = HttpServer()
        
        server["/DragAndDrop/:path1"] = handleFrontEndRequest
        server["/DragAndDrop/:path1/:path2/:path3"] = handleFrontEndRequest
        server["/server/ping"] = {r in return .ok(.text("pong"))}
        hummingbird_requests.loadRequests(server: &server)
        flutter_requests.loadRequests(server: &server)
        data_requests.loadRequests(server: &server)
        host_device_requests.loadRequests(server: &server)
    }
    
    func start() {
        do {
            try server.start(22179, forceIPv4: true, priority: DispatchQoS.default.qosClass)
        } catch {
            return
        }
        
        print (server.routes)
    }
    
}