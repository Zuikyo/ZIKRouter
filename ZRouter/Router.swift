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

///Router with type safe convenient methods for ZIKRouter.
public class Router {
    
    // MARK: Routable Discover
    
    /// Get view router for registered view protocol.
    ///
    /// - Parameter routableView: A routabe entry carrying a view protocol conformed by the view registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router for the view protocol.
    public static func to<Destination>(_ routableView: RoutableView<Destination>) -> ViewRouter<Destination, ViewRouteConfig>? {
        return Registry.router(to: routableView)
    }
    
    /// Get view router for registered view module config protocol.
    ///
    /// - Parameter routableViewModule: A routabe entry carrying a view module config protocol registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router for the config protocol.
    public static func to<Module>(_ routableViewModule: RoutableViewModule<Module>) -> ViewRouter<Any, Module>? {
        return Registry.router(to: routableViewModule)
    }
    
    /// Get service router for registered service protocol.
    ///
    /// - Parameter routableService: A routabe entry carrying a service protocol conformed by the service registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router for the service protocol.
    public static func to<Destination>(_ routableService: RoutableService<Destination>) -> ServiceRouter<Destination, PerformRouteConfig>? {
        return Registry.router(to: routableService)
    }
    
    /// Get service router for registered servie module config protocol.
    ///
    /// - Parameter routableServiceModule: A routabe entry carrying a cconfg protocol registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The service router for the config protocol.
    public static func to<Module>(_ routableServiceModule: RoutableServiceModule<Module>) -> ServiceRouter<Any, Module>? {
        return Registry.router(to: routableServiceModule)
    }
    
    // MARK: Switchable Discover
    
    /// Get view router for switchable registered view protocol, when the destination view is switchable from some view protocols.
    ///
    /// - Parameter switchableView: A struct carrying any routable view protocol, but not a specified one.
    /// - Returns: The view router for the view protocol.
    public static func to(_ switchableView: SwitchableView) -> ViewRouter<Any, ViewRouteConfig>? {
        return Registry.router(to: switchableView)
    }
    
    /// Get view router for switchable registered view module protocol, when the destination view is switchable from some view module protocols.
    ///
    /// - Parameter switchableViewModule: A struct carrying any routable view module config protocol, but not a specified one.
    /// - Returns: The view router for the view module config protocol.
    public static func to(_ switchableViewModule: SwitchableViewModule) -> ViewRouter<Any, ViewRouteConfig>? {
        return Registry.router(to: switchableViewModule)
    }
    
    /// Get service router for switchable registered service protocol, when the destination service is switchable from some service protocols.
    ///
    /// - Parameter switchableService: A struct carrying any routable service protocol, but not a specified one.
    /// - Returns: The service router for the service protocol.
    public static func to(_ switchableService: SwitchableService) -> ServiceRouter<Any, PerformRouteConfig>? {
        return Registry.router(to: switchableService)
    }
    
    /// Get service router for switchable registered service module config protocol, when the destination service is switchable from some service module protocols.
    ///
    /// - Parameter switchableServiceModule: A struct carrying any routable service module config protocol, but not a specified one.
    /// - Returns: The service router for the service module config protocol.
    public static func to(_ switchableServiceModule: SwitchableServiceModule) -> ServiceRouter<Any, PerformRouteConfig>? {
        return Registry.router(to: switchableServiceModule)
    }
    
    // MARK: Dynamic Discover
    
    /// Get view router for registered view protocol name.
    /// - Warning: Only use this when the business logic requires highly dynamic route, e.g. handling open URL from outside and show dynamic view.
    ///
    /// - Parameter viewProtocolName: The name string of the view protocol.
    /// - Returns: The view router for the view protocol.
    public static func to(dynamicView viewProtocolName: String) -> ViewRouter<Any, ViewRouteConfig>? {
        return Registry.router(toDynamicView: viewProtocolName)
    }
    
    /// Get view router for registered view module protocol name.
    /// - Warning: Only use this when the business logic requires highly dynamic route, e.g. handling open URL from outside and show dynamic view.
    ///
    /// - Parameter configProtocolName: The name string of the view module config protocol.
    /// - Returns: The view router for the view module config protocol.
    public static func to(dynamicViewModule configProtocolName: String) -> ViewRouter<Any, ViewRouteConfig>? {
        return Registry.router(toDynamicViewModule: configProtocolName)
    }
    
    /// Get service router class for registered service protocol name.
    /// - Warning: Only use this when the business logic requires highly dynamic route.
    ///
    /// - Parameter serviceProtocolName: The name string of the service protocol.
    /// - Returns: The service router class for the service protocol.
    public static func to(dynamicService serviceProtocolName: String) -> ServiceRouter<Any, PerformRouteConfig>? {
        return Registry.router(toDynamicService: serviceProtocolName)
    }
    
    /// Get service router for registered service module protocol name.
    /// - Warning: Only use this when the business logic requires highly dynamic route.
    ///
    /// - Parameter configProtocolName: The name string of the service module config protocol.
    /// - Returns: The service router for the service module config protocol.
    public static func to(dynamicServiceModule configProtocolName: String) -> ServiceRouter<Any, PerformRouteConfig>? {
        return Registry.router(toDynamicServiceModule: configProtocolName)
    }
}

// MARK: Perform

public extension Router {
    
    /// Perform route with view protocol and prepare the destination with the protocol.
    ///
    /// - Parameters:
    ///   - routableView: A routable entry carrying a view protocol.
    ///   - source: Source UIViewController or UIView. See ZIKViewRouteConfiguration's source.
    ///   - configure: Configure the configuration for performing view route.
    ///     - config: Config for view route.
    ///     - prepareDestination: Prepare destination before performing route. It's an escaping block, use weakSelf to avoid retain cycle.
    ///     - prepareModule: Prepare custom moudle config.
    ///   - removeConfigure: Configure the configuration for removing view.
    ///     - config: Config for removing view route.
    ///     - prepareDestination: Prepare destination before removing route. It's an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The view router.
    @discardableResult public static func perform<Destination>(
        to routableView: RoutableView<Destination>,
        from source: ZIKViewRouteSource?,
        configuring configure: @escaping (ViewRouteConfig, (@escaping (Destination) -> Void) -> Void, ((ViewRouteConfig) -> Void) -> Void) -> Void,
        removing removeConfigure: ((ViewRemoveConfig, (@escaping (Destination) -> Void) -> Void) -> Void)? = nil
        ) -> ViewRouter<Destination, ViewRouteConfig>? {
        let r = Registry.router(to: routableView)
        r?.perform(from: source,
                   configuring: { config, prepareDestination, prepareModule  in
                    configure(config, prepareDestination, prepareModule)
        }, removing: removeConfigure)
        return r
    }
    
    /// Perform route with view protocol and route type.
    ///
    /// - Parameters:
    ///   - routableView: A routable entry carrying a view protocol.
    ///   - source: Source UIViewController or UIView. See ZIKViewRouteConfiguration's source.
    ///   - routeType: Transition type.
    /// - Returns: The view router.
    @discardableResult public static func perform<Destination>(
        to routableView: RoutableView<Destination>,
        from source: ZIKViewRouteSource?,
        routeType: ViewRouteType) -> ViewRouter<Destination, ViewRouteConfig>? {
        return perform(to: routableView, from: source, configuring: { (config, _, _) in
            config.routeType = routeType
        })
    }
    
    /// Perform route with view config protocol and prepare the module with the protocol.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a view module config protocol.
    ///   - source: Source UIViewController or UIView. See ZIKViewRouteConfiguration's source.
    ///   - configure: Configure the configuration for view route.
    ///     - config: Config for view route.
    ///     - prepareDestination: Prepare destination before performing route. It's an escaping block, use weakSelf to avoid retain cycle.
    ///     - prepareModule: Prepare custom moudle config.
    ///   - removeConfigure: Configure the configuration for removing view.
    /// - Returns: The view router.
    @discardableResult public static func perform<Module>(
        to routableViewModule: RoutableViewModule<Module>,
        from source: ZIKViewRouteSource?,
        configuring configure: @escaping (ViewRouteConfig, (@escaping (Any) -> Void) -> Void, ((Module) -> Void) -> Void) -> Void,
        removing removeConfigure: ((ViewRemoveConfig, (@escaping (Any) -> Void) -> Void) -> Void)? = nil
        ) -> ViewRouter<Any, Module>? {
        let r = Registry.router(to: routableViewModule)
        r?.perform(from: source,
                   configuring: { config, prepareDestination, prepareModule  in
                    configure(config, prepareDestination, prepareModule)
        }, removing: removeConfigure)
        return r
    }
    
    /// Perform route with view config protocol and route type.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a view module config protocol.
    ///   - source: Source UIViewController or UIView. See ZIKViewRouteConfiguration's source.
    ///   - routeType: Transition type.
    /// - Returns: The view router.
    @discardableResult public static func perform<Module>(
        to routableViewModule: RoutableViewModule<Module>,
        from source: ZIKViewRouteSource?,
        routeType: ViewRouteType) -> ViewRouter<Any, Module>? {
        return perform(to: routableViewModule, from: source, configuring: { (config, _, _) in
            config.routeType = routeType
        })
    }
    
    /// Perform route with service protocol and prepare the destination with the protocol.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a service protocol.
    ///   - configure: Configure the configuration for service route.
    ///     - config: Config for view route.
    ///     - prepareDestination: Prepare destination before performing route. It's an escaping block, use weakSelf to avoid retain cycle.
    ///     - prepareModule: Prepare custom moudle config.
    ///   - removeConfigure: Configure the configuration for removing service.
    /// - Returns: The service router.
    @discardableResult public static func perform<Destination>(
        to routableService: RoutableService<Destination>,
        configuring configure: @escaping (PerformRouteConfig, (@escaping (Destination) -> Void) -> Void, ((PerformRouteConfig) -> Void) -> Void) -> Void,
        removing removeConfigure: ((RouteConfig, ((RouteConfig) -> Void) -> Void) -> Void)? = nil
        ) -> ServiceRouter<Destination, PerformRouteConfig>? {
        let r = Registry.router(to: routableService)
        r?.perform(configuring: configure)
        return r
    }
    
    /// Perform route with service module config protocol and prepare the module with the protocol.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a module config protocol.
    ///   - configure: Configure the configuration for service route.
    ///     - config: Config for view route.
    ///     - prepareDestination: Prepare destination before performing route. It's an escaping block, use weakSelf to avoid retain cycle.
    ///     - prepareModule: Prepare custom moudle config.
    ///   - removeConfigure: Configure the configuration for removing service.
    /// - Returns: The service router.
    @discardableResult public static func perform<Module>(
        to routableServiceModule: RoutableServiceModule<Module>,
        configuring configure: @escaping (PerformRouteConfig, (@escaping (Any) -> Void) -> Void, ((Module) -> Void) -> Void) -> Void,
        removing removeConfigure: ((RouteConfig, ((RouteConfig) -> Void) -> Void) -> Void)? = nil
        ) -> ServiceRouter<Any, Module>? {
        let r = Registry.router(to: routableServiceModule)
        r?.perform(configuring: configure)
        return r
    }
}

// MARK: Factory
public extension Router {
    
    /// Get view destination conforming the view protocol.
    ///
    /// - Parameters:
    ///   - routableView: A routabe entry carrying a view protocol.
    ///   - prepare: Prepare the destination with the protocol. This is an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The view destination.
    public static func makeDestination<Destination>(
        to routableView: RoutableView<Destination>,
        preparation prepare: ((Destination) -> Void)? = nil
        ) -> Destination? {
        let routerClass = Registry.router(to: routableView)
        return routerClass?.makeDestination(preparation: prepare)
    }
    
    /// Get view destination with view config protocol.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a view module config protocol.
    ///   - prepare: Prepare the module with the protocol. This is an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The view destination.
    public static func makeDestination<Module>(
        to routableViewModule: RoutableViewModule<Module>,
        preparation prepare: ((Module) -> Void)? = nil
        ) -> Any? {
        var destination: Any?
        let routerClass = Registry.router(to: routableViewModule)
        _ = routerClass?.makeDestination(configuring: { config,_,_  in
            config.routeType = ViewRouteType.getDestination
            if let moduleConfig = config as? Module {
                prepare?(moduleConfig)
            }
            config.routeCompletion = { d in
                destination = d
            }
        })
        return destination
    }
    
    /// Get view destination with view config protocol.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a view module config protocol.
    ///   - configure: Prepare the module with the protocol.
    /// - Returns: The view destination.
    public static func makeDestination<Module>(
        to routableViewModule: RoutableViewModule<Module>,
        configuring configure: @escaping (ViewRouteConfig, (@escaping (Any) -> Void) -> Void, ((Module) -> Void) -> Void) -> Void
        ) -> Any? {
        let routerClass = Registry.router(to: routableViewModule)
        return routerClass?.makeDestination(configuring: configure)
    }
    
    /// Get service destination conforming the service protocol.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a service protocol.
    ///   - prepare: Prepare the destination with the protocol. This is an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The service destination.
    public static func makeDestination<Destination>(
        to routableService: RoutableService<Destination>,
        preparation prepare: ((Destination) -> Void)? = nil
        ) -> Destination? {
        let routerClass = Registry.router(to: routableService)
        return routerClass?.makeDestination(preparation: prepare)
    }
    
    /// Get service destination with service config protocol.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a service module config protocol.
    ///   - prepare: Prepare the module with the protocol. This is an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The service destination.
    public static func makeDestination<Module>(
        to routableServiceModule: RoutableServiceModule<Module>,
        preparation prepare: ((Module) -> Void)? = nil
        ) -> Any? {
        var destination: Any?
        let routerClass = Registry.router(to: routableServiceModule)
        _ = routerClass?.perform(configuring: { config,_,_  in
            if let moduleConfig = config as? Module {
                prepare?(moduleConfig)
            }
            config.routeCompletion = { d in
                destination = d
            }
        })
        return destination
    }
    
    /// Get service destination with service config protocol.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a service module config protocol.
    ///   - configure: Prepare the module with the protocol.
    /// - Returns: The service destination.
    public static func makeDestination<Module>(
        to routableServiceModule: RoutableServiceModule<Module>,
        configuring configure: @escaping (PerformRouteConfig, (@escaping (Any) -> Void) -> Void, ((Module) -> Void) -> Void) -> Void
        ) -> Any? {
        let routerClass = Registry.router(to: routableServiceModule)
        return routerClass?.makeDestination(configuring: configure)
    }
}
