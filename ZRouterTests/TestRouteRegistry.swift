//
//  TestRouteRegistry.swift
//  ZRouterTests
//
//  Created by zuik on 2018/4/28.
//  Copyright © 2018 zuik. All rights reserved.
//

import Foundation
import ZRouter

class TestRouteRegistry {
    static var registerRoutes: () = {
        AServiceRouter.registerRoutableDestination()
        AViewRouter.registerRoutableDestination()
        BSubviewRouter.registerRoutableDestination()
    }()
    
    class func setUp() {
        _ = self.registerRoutes
    }
}
