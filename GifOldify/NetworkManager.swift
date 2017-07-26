//
//  NetworkManager.swift
//  GifOldify
//
//  Created by keith martin on 7/26/17.
//  Copyright © 2017 Keith Martin. All rights reserved.
//

import Foundation
import AFNetworking

class NetworkManager {
    
    static var sharedNetworkManager: AFHTTPSessionManager = {
        let manager = AFHTTPSessionManager(baseURL: URL(string: "https://api.giphy.com/v1/"), sessionConfiguration: .default)
        manager.session.configuration.httpMaximumConnectionsPerHost = 3
        return manager
    }()
    
    class func shared() -> AFHTTPSessionManager {
        return sharedNetworkManager
    }
    
}
