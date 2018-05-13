//
//  TestRouteRegistry.swift
//  ZRouterTests
//
//  Created by zuik on 2018/4/28.
//  Copyright © 2018 zuik. All rights reserved.
//

import Foundation
import ZRouter
import ZIKRouter.Internal

class TestRouteRegistry {
    static var registerRoutes: () = {
        ZIKRouteRegistry.autoRegister = false
        
        AServiceRouter.registerRoutableDestination()
        AViewRouter.registerRoutableDestination()
        BSubviewRouter.registerRoutableDestination()
        
        AViewAdapter.registerRoutableDestination()
        AServiceAdapter.registerRoutableDestination()
        
        ZIKRouteRegistry.notifyRegistrationFinished()
    }()
    
    class func setUp() {
        _ = self.registerRoutes
    }
}
