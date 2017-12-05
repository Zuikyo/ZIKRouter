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

class MySwiftServiceRouter: ZIKServiceRouter<AnyObject, SwiftServiceConfiguration> {
    
    override class func registerRoutableDestination() {
        registerService(SwiftService.self)
        Registry.register(RoutableService<SwiftServiceInput>(), forRouter: self)
        Registry.register(RoutableServiceModule<SwiftServiceConfig>(), forRouter: self)
    }
    
    override func destination(with configuration: SwiftServiceConfiguration) -> AnyObject? {
        return SwiftService()
    }
    
    override class func defaultRouteConfiguration() -> SwiftServiceConfiguration {
        return SwiftServiceConfiguration()
    }
    
    override func prepareDestination(_ destination: AnyObject, configuration: SwiftServiceConfiguration) {
        let d = destination as! SwiftService
        print(d)
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
extension RoutableServiceModule where Protocol == SwiftServiceConfig {
    init() { }
}
