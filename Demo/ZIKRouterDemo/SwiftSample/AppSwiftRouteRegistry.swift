//
//  AppSwiftRouteRegistry.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//

import Foundation

///Manually register swift routers
@objc class AppSwiftRouteRegistry: NSObject {
    @objc class func manuallyRegisterEachRouter() {
        SwiftSampleViewRouter.registerRoutableDestination()
        SwiftServiceRouter.registerRoutableDestination()
    }
}
