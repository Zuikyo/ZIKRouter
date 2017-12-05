//
//  SwiftStructRouter.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2017/11/23.
//  Copyright © 2017年 zuik. All rights reserved.
//

import ZIKRouter.Internal
import ZRouter

protocol SwiftStructConfig {
    var structType: SwiftStructType{get set}
}

open class SwiftStructConfiguration: ZIKPerformRouteConfiguration, SwiftStructConfig {
    var structType: SwiftStructType = .one
    
    override open func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! SwiftStructConfiguration
        copy.structType = self.structType
        return copy
    }
}

//class SwiftStructRouter: ZIKServiceRouter<AnyObject, SwiftStructConfiguration, ZIKRouteConfiguration> {
//    override class func registerRoutableDestination() {
////        registerService(SwiftStruct.self as! AnyClass)
//        Registry.register(swiftType: SwiftStruct.self, forRouter: self)
//        Registry.register(RoutableService<SwiftServiceInput>(), forRouter: self)
//        Registry.register(RoutableServiceModule<SwiftStructConfig>(), forRouter: self)
//    }
//
//    override func destination(with configuration: SwiftStructConfiguration) -> AnyObject? {
//        return SwiftStruct() as AnyObject
//    }
//
//    override func removeDestination(_ destination: AnyObject?, remove removeConfiguration: ZIKRouteConfiguration) {
//        let s = destination as? SwiftStruct
//
//    }
//
//    override class func defaultRouteConfiguration() -> SwiftStructConfiguration {
//        return SwiftStructConfiguration()
//    }
//}

open class SwiftStructRouter: SwiftServiceRouter {
    public typealias Destination = SwiftStruct
    public typealias ModuleConfig = SwiftStructConfiguration
    public typealias RemoveModuleConfig = ZIKRemoveRouteConfiguration

    public var state: RouterState = .notRoute
    public var destination: SwiftStruct?

    public var config: SwiftStructConfiguration

    public var removeConfig: ZIKRemoveRouteConfiguration

    open class func registerRoutableDestination() {

    }

    public static var defaultConfig: SwiftStructConfiguration {
        return SwiftStructConfiguration()
    }

    public required init?(config: SwiftStructConfiguration, removeConfig: ZIKRemoveRouteConfiguration?) {
        self.config = config
        let routerType = Swift.type(of: self)
        self.removeConfig = removeConfig ?? routerType.defaultRemoveConfig
    }

    public func destination(with config: SwiftStructConfiguration) -> SwiftStruct? {
        return SwiftStruct()
    }
}

extension RoutableService where Protocol == SwiftStructInput {
    init() { }
}
extension RoutableServiceModule where Protocol == SwiftStructConfig {
    init() { }
}
