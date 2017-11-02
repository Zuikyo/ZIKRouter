//
//  SwiftServiceRouter.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2017/10/14.
//  Copyright © 2017 zuik. All rights reserved.
//

import Foundation
import ZIKRouter
import ZIKRouterSwift

//Declare SwiftService is routable
extension SwiftService: ZIKRoutableService {
}

class SwiftServiceRouter: ZIKServiceRouter<ZIKServiceRouteConfiguration, ZIKRouteConfiguration> {
    override class func registerRoutableDestination() {
        registerService(SwiftService.self)
        Router.register(serviceProtocol: SwiftServiceInput.self, router: self)
        if _swift_typeConformsToProtocol(SwiftService.self, SwiftServiceInput.self) == false {
            fatalError()
        }
    }
    override func destination(with configuration: ZIKServiceRouteConfiguration) -> ZIKRoutableService? {
        return SwiftService()
    }
}
