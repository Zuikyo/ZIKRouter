//
//  SwiftServiceRouter.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2017/10/14.
//  Copyright © 2017 zuik. All rights reserved.
//

import Foundation
import ZIKRouter
import ZRouter

class SwiftServiceRouter: ZIKServiceRouter<AnyObject, ZIKServiceRouteConfiguration, ZIKRouteConfiguration> {
    override class func registerRoutableDestination() {
        registerService(SwiftService.self)
        Registry.register(RoutableService<SwiftServiceInput>(), forRouter: self)
    }
    
    override func destination(with configuration: ZIKServiceRouteConfiguration) -> AnyObject? {
        return SwiftService()
    }
}

// MARK: Declare Routable

//Declare SwiftService is routable
extension SwiftService: ZIKRoutableService {
}
//Declare SwiftServiceInput is routable
extension RoutableService where Protocol == SwiftServiceInput {
    init() { }
}
extension RoutableService where Protocol == SwiftServiceInput2 {
    init() { }
}
