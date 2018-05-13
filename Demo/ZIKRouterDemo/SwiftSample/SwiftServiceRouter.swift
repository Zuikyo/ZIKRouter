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

protocol SwiftServiceConfig {
    
}

//Custom configuration of this router.
class SwiftServiceConfiguration: ZIKPerformRouteConfiguration, SwiftServiceConfig {
    override func copy(with zone: NSZone? = nil) -> Any {
        return super.copy(with: zone)
    }
}

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
}

// MARK: Declare Routable

//Declare SwiftService is routable
extension SwiftService: ZIKRoutableService {
}
//Declare SwiftServiceInput is routable
extension RoutableService where Protocol == SwiftServiceInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}
extension RoutableService where Protocol == SwiftServiceInput2 {
    init() { self.init(declaredProtocol: Protocol.self) }
}
extension RoutableServiceModule where Protocol == SwiftServiceConfig {
    init() { self.init(declaredProtocol: Protocol.self) }
}
