//
//  TestSwiftRouteRegistry.swift
//  ZIKViewRouterTests
//
//  Created by zuik on 2018/4/26.
//  Copyright © 2018 zuik. All rights reserved.
//

import UIKit

class TestSwiftRouteRegistry: NSObject {
    class func registerRoutes() {
        ASwiftViewRouter.registerRoutableDestination()
        BSwiftSubviewRouter.registerRoutableDestination()
    }
}
