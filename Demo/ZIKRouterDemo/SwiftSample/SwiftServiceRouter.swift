//
//  SwiftServiceRouter.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2017/10/14.
//  Copyright © 2017 zuik. All rights reserved.
//

import Foundation
import ZIKRouter

//Declare SwiftService is routable
extension SwiftService: ZIKRoutableService {
}

class SwiftServiceRouter: ZIKServiceRouter<ZIKServiceRouteConfiguration, ZIKRouteConfiguration> {
    override class func registerRoutableDestination() {
        registerService(SwiftService.self)
        registerServiceProtocol(SwiftServiceProtocol.self)
    }
    override func destination(with configuration: ZIKRouteConfiguration) -> Any {
        return SwiftService()
    }
}
