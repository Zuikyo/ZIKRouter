//
//  ServiceModuleRouter.swift
//  ZRouter
//
//  Created by zuik on 2017/11/5.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import ZIKRouter

///Type safe service module router for declared service module config protocol. Generic parameter `Module` is the config protocol of the module. See `ViewRoute` to learn how to declare a routable protocol.
open class ServiceModuleRouter<Module> {
    
}

public protocol ServiceModuleRoutable {
    associatedtype Module
}

public extension ServiceModuleRoutable {
    
    /// Perform route with service module config protocol and prepare the module with the protocol.
    ///
    /// - Parameters:
    ///   - configure: Configure the configuration for service route.
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The service router.
    public static func perform(
        routeConfig configure: (ServiceRouteConfig) -> Swift.Void,
        preparation prepare: ((Module) -> Swift.Void)? = nil
        ) -> DefaultServiceRouter? {
        return Router.perform(forServiceModule: Module.self, routeConfig: configure, preparation: prepare)
    }
    
    /// Get service destination with service module config protocol.
    ///
    /// - Parameters:
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The service destination.
    public static func makeDestination<Module>(preparation prepare: ((Module) -> Swift.Void)? = nil) -> Any? {
        return Router.makeDestination(forServiceModule: Module.self, preparation: prepare)
    }
}

///All objc protocols inherited from ZIKServiceModuleRoutable are routable.
public extension ViewModuleRouter where Module: ZIKServiceModuleRoutable {
    public static var route: ServiceModuleRoute<Module>.Type {
        return ServiceModuleRoute<Module>.self
    }
}

///Wrapper router for routable service module protocol.
///SeeAlso: `ViewRoute`.
public struct ServiceModuleRoute<ServiceModule>: ServiceModuleRoutable {
    public typealias Module = ServiceModule
}
