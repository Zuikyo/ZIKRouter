//
//  AppSwiftRouteRegistry.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//

import Foundation
import ZRouter
import ZIKRouter


///Manually register swift routers
@objc class AppSwiftRouteRegistry: NSObject {
    @objc class func manuallyRegisterEachRouter() {
        SwiftSampleViewRouter.registerRoutableDestination()
        SwiftServiceRouter.registerRoutableDestination()
        
//        let route = ZIKServiceRoute<SwiftService, PerformRouteConfig>
//            .make(withDestination: SwiftService.self,
//                  makeDestination: { (config, router) -> SwiftService? in
//                    return SwiftService()
//            })
//            .makeDefaultConfiguration({
//                return SwiftServiceConfiguration()
//            })
//        route.register(RoutableService<SwiftServiceInput>())
//        route.register(RoutableServiceModule<SwiftServiceConfig>())
    }
}
