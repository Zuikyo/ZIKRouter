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
import ZIKRouter.Internal

protocol SwiftServiceConfig {
    
}

//Custom configuration of this router.
class SwiftServiceConfiguration: ZIKPerformRouteConfiguration, SwiftServiceConfig {
    override func copy(with zone: NSZone? = nil) -> Any {
        return super.copy(with: zone)
    }
}

//Router for SwiftService. Generic of ZIKRouter can't be pure swift type, so we use `AnyObject` here.
class SwiftServiceRouter: ZIKServiceRouter<AnyObject, SwiftServiceConfiguration> {
    override class func registerRoutableDestination() {
        registerService(SwiftService.self)
        if TEST_BLOCK_ROUTES == 0 {
            register(RoutableService<SwiftServiceInput>())
            register(RoutableServiceModule<SwiftServiceConfig>())
        }
    }
    
    override func destination(with configuration: SwiftServiceConfiguration) -> AnyObject? {
        return SwiftService()
    }
    
    override class func defaultRouteConfiguration() -> SwiftServiceConfiguration {
        return SwiftServiceConfiguration()
    }
    
    @objc class func applicationDidEnterBackground(_ application: UIApplication) {
        print("\(self) handle applicationDidEnterBackground event")
    }
}

// MARK: Declare Routable

//Declare SwiftService is routable
extension SwiftService: ZIKRoutableService {
}
//Declare SwiftServiceInput is routable
extension RoutableService where Protocol == SwiftServiceInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}
extension RoutableServiceModule where Protocol == SwiftServiceConfig {
    init() { self.init(declaredProtocol: Protocol.self) }
}
