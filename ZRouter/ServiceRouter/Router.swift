//
//  Router.swift
//  ZRouter
//
//  Created by zuik on 2017/11/6.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import ZIKRouter.Internal
import ZIKRouter.Private

/// Router with type safe convenient methods for ZIKRouter.
public class Router {
    
    // MARK: Routable Discover
    
    /// Get service router type for registered service protocol.
    ///
    /// - Parameter routableService: A routabe entry carrying a service protocol conformed by the service registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The service router type for the service protocol.
    public static func to<Protocol>(_ routableService: RoutableService<Protocol>) -> ServiceRouterType<Protocol, PerformRouteConfig>? {
        return Registry.router(to: routableService)
    }
    
    /// Get service router type for registered servie module config protocol.
    ///
    /// - Parameter routableServiceModule: A routabe entry carrying a cconfg protocol registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The service router type for the config protocol.
    public static func to<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>) -> ServiceRouterType<Any, Protocol>? {
        return Registry.router(to: routableServiceModule)
    }
    
    // MARK: Switchable Discover
    
    /// Get service router type for switchable registered service protocol, when the destination service is switchable from some service protocols.
    ///
    /// - Parameter switchableService: A struct carrying any routable service protocol, but not a specified one.
    /// - Returns: The service router type for the service protocol.
    public static func to(_ switchableService: SwitchableService) -> ServiceRouterType<Any, PerformRouteConfig>? {
        return Registry.router(to: switchableService)
    }
    
    /// Get service router type for switchable registered service module config protocol, when the destination service is switchable from some service module protocols.
    ///
    /// - Parameter switchableServiceModule: A struct carrying any routable service module config protocol, but not a specified one.
    /// - Returns: The service router type for the service module config protocol.
    public static func to(_ switchableServiceModule: SwitchableServiceModule) -> ServiceRouterType<Any, PerformRouteConfig>? {
        return Registry.router(to: switchableServiceModule)
    }
    
    // MARK: Identifier Discover
    
    /// Find service router registered with the unique identifier.
    ///
    /// - Parameter serviceIdentifier: Identifier of the router.
    /// - Returns: The service router type for the identifier. Return nil if the identifier is not registered with any service router.
    public static func to(serviceIdentifier: String) -> ServiceRouterType<Any, PerformRouteConfig>? {
        if let routerType = ZIKAnyServiceRouter.toIdentifier(serviceIdentifier) {
            return ServiceRouterType(routerType: routerType)
        }
        return nil
    }
}

// MARK: Perform

public extension Router {
    
    /// Perform route with service protocol and prepare the destination with the protocol.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a service protocol.
    ///   - configure: Configure the configuration for service route.
    ///     - config: Config for service route.
    ///     - prepareModule: Prepare custom module config.
    ///   - removeConfigure: Configure the configuration for removing service.
    /// - Returns: The service router.
    @discardableResult static func perform<Protocol>(
        to routableService: RoutableService<Protocol>,
        configuring configure: (PerformRouteStrictConfig<Protocol>, ((PerformRouteConfig) -> Void) -> Void) -> Void,
        removing removeConfigure: ((RemoveRouteStrictConfig<Protocol>) -> Void)? = nil
        ) -> ServiceRouter<Protocol, PerformRouteConfig>? {
        let routerType = Registry.router(to: routableService)
        return routerType?.perform(configuring: configure, removing: removeConfigure)
    }
    
    /// Perform route with service protocol and completion.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a service protocol.
    ///   - performerCompletion: Completion for current performing.
    /// - Returns: The service router.
    @discardableResult static func perform<Protocol>(
        to routableService: RoutableService<Protocol>,
        completion performerCompletion: @escaping (Bool, Any?, ZIKRouteAction, Error?) -> Void
        ) -> ServiceRouter<Protocol, PerformRouteConfig>? {
        let routerType = Registry.router(to: routableService)
        return routerType?.perform(completion: performerCompletion)
    }
    
    /// Prepare the destination with destination protocol and perform route.
    ///
    /// - Parameters:
    ///   - routableService: A routable entry carrying a service protocol.
    ///   - preparation: Prepare the destination with destination protocol. It's an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The service router for this route.
    @discardableResult static func perform<Protocol>(
        to routableService: RoutableService<Protocol>,
        preparation prepare: @escaping ((Protocol) -> Void)
        ) -> ServiceRouter<Protocol, PerformRouteConfig>? {
        let routerType = Registry.router(to: routableService)
        return routerType?.perform(preparation: prepare)
    }
    
    /// Perform route with service protocol and success handler and error handler for current performing.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a service protocol.
    ///   - performerSuccessHandler: Success handler for current performing.
    ///   - performerErrorHandler: Error handler for current performing.
    /// - Returns: The service router.
    @discardableResult static func perform<Protocol>(
        to routableService: RoutableService<Protocol>,
        successHandler performerSuccessHandler: ((Protocol) -> Void)? = nil,
        errorHandler performerErrorHandler: ((ZIKRouteAction, Error) -> Void)? = nil
        ) -> ServiceRouter<Protocol, PerformRouteConfig>? {
        let routerType = Registry.router(to: routableService)
        return routerType?.perform(successHandler: performerSuccessHandler, errorHandler: performerErrorHandler)
    }
    
    /// Perform route with service module config protocol and prepare the module with the protocol.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a module config protocol.
    ///   - configure: Configure the configuration for service route.
    ///     - config: Config for service route.
    ///     - prepareModule: Prepare custom module config.
    ///   - removeConfigure: Configure the configuration for removing service.
    /// - Returns: The service router.
    @discardableResult static func perform<Protocol>(
        to routableServiceModule: RoutableServiceModule<Protocol>,
        configuring configure: (PerformRouteStrictConfig<Any>, ((Protocol) -> Void) -> Void) -> Void,
        removing removeConfigure: ((RemoveRouteStrictConfig<Any>) -> Void)? = nil
        ) -> ServiceRouter<Any, Protocol>? {
        let routerType = Registry.router(to: routableServiceModule)
        let router = routerType?.perform(configuring: configure, removing: removeConfigure)
        return router
    }
    
    /// Perform route with service protocol and completion.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a module config protocol.
    ///   - performerCompletion: Completion for current performing.
    /// - Returns: The service router.
    @discardableResult static func perform<Protocol>(
        to routableServiceModule: RoutableServiceModule<Protocol>,
        completion performerCompletion: @escaping (Bool, Any?, ZIKRouteAction, Error?) -> Void
        ) -> ServiceRouter<Any, Protocol>? {
        let routerType = Registry.router(to: routableServiceModule)
        return routerType?.perform(completion: performerCompletion)
    }
    
    /// Prepare the destination module with module protocol and perform route.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routable entry carrying a module config protocol.
    ///   - preparation: Prepare the module with protocol.
    /// - Returns: The service router for this route.
    @discardableResult static func perform<Protocol>(
        to routableServiceModule: RoutableServiceModule<Protocol>,
        preparation prepare: @escaping ((Protocol) -> Void)
        ) -> ServiceRouter<Any, Protocol>? {
        let routerType = Registry.router(to: routableServiceModule)
        return routerType?.perform(configuring: { (_, prepareModule) in
            prepareModule(prepare)
        })
    }
}

// MARK: Factory
public extension Router {
    
    /// Get service destination conforming the service protocol.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a service protocol.
    ///   - prepare: Prepare the destination with the protocol. This is an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The service destination.
    static func makeDestination<Protocol>(
        to routableService: RoutableService<Protocol>,
        preparation prepare: ((Protocol) -> Void)? = nil
        ) -> Protocol? {
        let routerClass = Registry.router(to: routableService)
        return routerClass?.makeDestination(preparation: prepare)
    }
    
    /// Get service destination with service config protocol.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a service protocol.
    ///   - configure: Prepare the destination and other parameters.
    /// - Returns: The service destination.
    static func makeDestination<Protocol>(
        to routableService: RoutableService<Protocol>,
        configuring configure: (PerformRouteStrictConfig<Protocol>, ((PerformRouteConfig) -> Void) -> Void) -> Void
        ) -> Protocol? {
        let routerClass = Registry.router(to: routableService)
        return routerClass?.makeDestination(configuring: configure)
    }
    
    /// Get service destination with service config protocol.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a service module config protocol.
    ///   - prepare: Prepare the module with the protocol. This is an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The service destination.
    static func makeDestination<Protocol>(
        to routableServiceModule: RoutableServiceModule<Protocol>,
        preparation prepare: ((Protocol) -> Void)? = nil
        ) -> Any? {
        let routerType = Registry.router(to: routableServiceModule)
        return routerType?.makeDestination(configuring: { (config, prepareModule) in
            if let prepare = prepare {
                prepareModule(prepare)
            }
        })
    }
    
    /// Get service destination with service config protocol.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a service module config protocol.
    ///   - configure: Prepare the module with the protocol.
    /// - Returns: The service destination.
    static func makeDestination<Protocol>(
        to routableServiceModule: RoutableServiceModule<Protocol>,
        configuring configure: (PerformRouteStrictConfig<Any>, ((Protocol) -> Void) -> Void) -> Void
        ) -> Any? {
        let routerClass = Registry.router(to: routableServiceModule)
        return routerClass?.makeDestination(configuring: configure)
    }
    
    // MARK: Utility
    
    /// Enumerate all service routers. You can notify custom events to service routers with it.
    ///
    /// - Parameter handler: The enumerator gives subclasses of ZIKServiceRouter.
    static func enumerateAllServiceRouters(_ handler: (ZIKAnyServiceRouter.Type) -> Void) -> Void {
        ZIKAnyServiceRouter.enumerateAllServiceRouters { (routerClass) in
            if let routerType = routerClass as? ZIKAnyServiceRouter.Type {
                handler(routerType)
            }
        }
    }
    
}
