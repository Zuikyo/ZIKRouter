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
    
    /// Perform route with view protocol and prepare the destination with the protocol.
    ///
    /// - Parameters:
    ///   - routableView: A routable entry carrying a view protocol.
    ///   - source: Source UIViewController or UIView. See ZIKViewRouteConfiguration's source.
    ///   - configure: Configure the configuration for view route.
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The view router.
    public static func perform<Destination>(
        to routableView: RoutableView<Destination>,
        from source: ZIKViewRouteSource?,
        configuring configure: @escaping (ViewRouteConfig, (@escaping (Destination) -> Void) -> Void, ((ViewRouteConfig) -> Void) -> Void) -> Void,
        removing removeConfigure: ((ViewRemoveConfig, ((ViewRemoveConfig) -> Void) -> Void) -> Void)? = nil
        ) -> ViewRouter<Destination, ViewRouteConfig, ViewRemoveConfig>? {
        let r = Registry.router(to: routableView)
        r?.perform(from: source,
                   configuring: { config, prepareDestination, prepareModule  in
                    configure(config, prepareDestination, prepareModule)
        }, removing: removeConfigure)
        if shouldCheckViewRouter && r?.routed?.destination != nil {
            _ = Registry.validateConformance(destination: r!.routed!.destination!, inViewRouter: (r!.routed)!)
        }
        return r
    }
    
    /// Perform route with view config protocol and prepare the module with the protocol.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a view module config protocol.
    ///   - source: Source UIViewController or UIView. See ZIKViewRouteConfiguration's source.
    ///   - configure: Configure the configuration for view route.
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The view router.
    public static func perform<Module>(
        to routableViewModule: RoutableViewModule<Module>,
        from source: ZIKViewRouteSource?,
        configuring configure: @escaping (ViewRouteConfig, (@escaping (Any) -> Void) -> Void, ((Module) -> Void) -> Void) -> Void,
        removing removeConfigure: ((ViewRemoveConfig, ((ViewRemoveConfig) -> Void) -> Void) -> Void)? = nil
        ) -> ViewRouter<Any, Module, ViewRemoveConfig>? {
        let r = Registry.router(to: routableViewModule)
        r?.perform(from: source,
                   configuring: { config, prepareDestination, prepareModule  in
                    configure(config, prepareDestination, prepareModule)
        }, removing: removeConfigure)
        if shouldCheckViewRouter && r?.routed?.destination != nil {
            _ = Registry.validateConformance(destination: r!.routed!.destination!, inViewRouter: (r!.routed)!)
        }
        return r
    }
    
    /// Perform route with service protocol and prepare the destination with the protocol.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a service protocol.
    ///   - configure: Configure the configuration for service route.
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The service router.
    public static func perform<Destination>(
        to routableService: RoutableService<Destination>,
        configuring configure: @escaping (PerformRouteConfig, (@escaping (Destination) -> Void) -> Void, ((PerformRouteConfig) -> Void) -> Void) -> Void,
        removing removeConfigure: ((RouteConfig, ((RouteConfig) -> Void) -> Void) -> Void)? = nil
        ) -> ServiceRouter<Destination, PerformRouteConfig, RouteConfig>? {
        let r = Registry.router(to: routableService)
        r?.perform(configuring: configure)
        if shouldCheckServiceRouter && r?.routed?.destination != nil {
            _ = Registry.validateConformance(destination: r!.routed!.destination!, inServiceRouter: r!.routed!)
        }
        return r
    }
    
    /// Perform route with service module config protocol and prepare the module with the protocol.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a module config protocol.
    ///   - configure: Configure the configuration for service route.
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The service router.
    public static func perform<Module>(
        to routableServiceModule: RoutableServiceModule<Module>,
        configuring configure: @escaping (PerformRouteConfig, (@escaping (Any) -> Void) -> Void, ((Module) -> Void) -> Void) -> Void,
        removing removeConfigure: ((RouteConfig, ((RouteConfig) -> Void) -> Void) -> Void)? = nil
        ) -> ServiceRouter<Any, Module, RouteConfig>? {
        let r = Registry.router(to: routableServiceModule)
        r?.perform(configuring: configure)
        if shouldCheckServiceRouter && r?.routed?.destination != nil {
            _ = Registry.validateConformance(destination: r!.routed!.destination!, inServiceRouter: r!.routed!)
        }
        return r
    }
}

// MARK: Factory
public extension Router {
    
    /// Get view destination conforming the view protocol.
    ///
    /// - Parameters:
    ///   - routableView: A routabe entry carrying a view protocol.
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The view destination.
    public static func makeDestination<Destination>(
        to routableView: RoutableView<Destination>,
        preparation prepare: ((Destination) -> Swift.Void)? = nil
        ) -> Destination? {
        let routerClass = Registry.router(to: routableView)
        assert((routerClass?.completeSynchronously)!,"router class (\(String(describing: routerClass))) can't get destination synchronously.")
        return routerClass?.makeDestination(preparation: prepare)
    }
    
    /// Get view destination with view config protocol.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a view module config protocol.
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The view destination.
    public static func makeDestination<Module>(
        to routableViewModule: RoutableViewModule<Module>,
        preparation prepare: ((Module) -> Swift.Void)? = nil
        ) -> Any? {
        var destination: Any?
        let routerClass = Registry.router(to: routableViewModule)
        assert((routerClass?.completeSynchronously)!,"router class (\(String(describing: routerClass))) can't get destination synchronously")
        _ = routerClass?.makeDestination(configuring: { config,_,_  in
            config.routeType = ViewRouteType.getDestination
            if config is Module {
                prepare?(config as! Module)
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
        assert((routerClass?.completeSynchronously)!,"router class (\(String(describing: routerClass))) can't get destination synchronously")
        return routerClass?.makeDestination(configuring: configure)
    }
    
    /// Get service destination conforming the service protocol.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a service protocol.
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The service destination.
    public static func makeDestination<Destination>(
        to routableService: RoutableService<Destination>,
        preparation prepare: ((Destination) -> Swift.Void)? = nil
        ) -> Destination? {
        let routerClass = Registry.router(to: routableService)
        assert((routerClass?.completeSynchronously)!,"router class (\(String(describing: routerClass))) can't get destination synchronously")
        return routerClass?.makeDestination(preparation: prepare)
    }
    
    /// Get service destination with service config protocol.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a service module config protocol.
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The service destination.
    public static func makeDestination<Module>(
        to routableServiceModule: RoutableServiceModule<Module>,
        preparation prepare: ((Module) -> Swift.Void)? = nil
        ) -> Any? {
        var destination: Any?
        let routerClass = Registry.router(to: routableServiceModule)
        assert((routerClass?.completeSynchronously)!,"router class (\(String(describing: routerClass))) can't get destination synchronously")
        _ = routerClass?.perform(configuring: { config,_,_  in
            if config is Module {
                prepare?(config as! Module)
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
        assert((routerClass?.completeSynchronously)!,"router class (\(String(describing: routerClass))) can't get destination synchronously")
        return routerClass?.makeDestination(configuring: configure)
    }
}
