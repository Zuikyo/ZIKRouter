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

protocol SwiftServiceModuleInput: class {
    var constructDestination: (String) -> Void { get }
    var didMakeDestination: ((SwiftServiceInput) -> Void)? { get set }
}

//Router for SwiftService. Generic of ZIKRouter can't be pure swift type, so we use `AnyObject` here.
class SwiftServiceRouter: ZIKServiceRouter<AnyObject, PerformRouteConfig> {
    override class func registerRoutableDestination() {
        registerService(SwiftService.self)
        if TEST_BLOCK_ROUTES == 0 {
            register(RoutableService<SwiftServiceInput>())
            register(RoutableServiceModule<SwiftServiceModuleInput>())
        }
    }
    
    override class func defaultRouteConfiguration() -> PerformRouteConfig {
        let config = ServiceMakeableConfiguration<SwiftServiceInput, (String) -> Void>({ _ in })
        config.constructDestination = { [unowned config] (param) in
            config.makeDestination = { () in
                return SwiftService()
            }
        }
        return config
    }
    
    override func destination(with configuration: PerformRouteConfig) -> AnyObject? {
        if let config = configuration as? ServiceMakeableConfiguration<SwiftServiceInput, (String) -> Void>,
            let makeDestination = config.makeDestination {
            return makeDestination() as AnyObject?
        }
        return SwiftService()
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
extension RoutableServiceModule where Protocol == SwiftServiceModuleInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

extension ServiceMakeableConfiguration: SwiftServiceModuleInput where Destination == SwiftServiceInput, Constructor == (String) -> Void {
    
}
