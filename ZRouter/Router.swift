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
    ///   - configure: Configure the configuration for view route.
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The view router.
    public static func perform<Destination>(
        for routableView: RoutableView<Destination>,
        routeConfig configure: (ViewRouteConfig) -> Swift.Void,
        preparation prepare: ((Destination) -> Swift.Void)? = nil
        ) -> DefaultViewRouter? {
        return Registry.router(for: routableView)?.perform(configure: { config in
            configure(config)
            config.prepareForRoute = { d in
                if let destination = d as? Destination {
                    prepare?(destination)
                }
            }
        })
    }
    
    /// Perform route with view config protocol and prepare the module with the protocol.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a view module config protocol.
    ///   - configure: Configure the configuration for view route.
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The view router.
    public static func perform<Module>(
        for routableViewModule: RoutableViewModule<Module>,
        routeConfig configure: (ViewRouteConfig) -> Swift.Void,
        preparation prepare: ((Module) -> Swift.Void)? = nil
        ) -> DefaultViewRouter? {
        return Registry.router(for: routableViewModule)?.perform(configure: { config in
            configure(config)
            if let configuration = config as? Module {
                prepare?(configuration)
            }
        })
    }
    
    /// Perform route with service protocol and prepare the destination with the protocol.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a service protocol.
    ///   - configure: Configure the configuration for service route.
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The service router.
    public static func perform<Destination>(
        for routableService: RoutableService<Destination>,
        routeConfig configure: (ServiceRouteConfig) -> Swift.Void,
        preparation prepare: ((Destination) -> Swift.Void)? = nil
        ) -> DefaultServiceRouter? {
        return Registry.router(for: routableService)?.perform(configure: { config in
            configure(config)
            config.prepareForRoute = { d in
                if let destination = d as? Destination {
                    prepare?(destination)
                }
            }
        })
    }
    
    /// Perform route with service module config protocol and prepare the module with the protocol.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a module config protocol.
    ///   - configure: Configure the configuration for service route.
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The service router.
    public static func perform<Module>(
        for routableServiceModule: RoutableServiceModule<Module>,
        routeConfig configure: (ServiceRouteConfig) -> Swift.Void,
        preparation prepare: ((Module) -> Swift.Void)? = nil
        ) -> DefaultServiceRouter? {
        return Registry.router(for: routableServiceModule)?.perform(configure: { config in
            configure(config)
            if let configuration = config as? Module {
                prepare?(configuration)
            }
        })
    }
}

// MARK: Make Destination
extension Router {
    
    /// Get view destination conforming the view protocol.
    ///
    /// - Parameters:
    ///   - routableView: A routabe entry carrying a view protocol.
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The view destination.
    public static func makeDestination<Destination>(
        for routableView: RoutableView<Destination>,
        preparation prepare: ((Destination) -> Swift.Void)? = nil
        ) -> Destination? {
        var destination: Destination?
        let routerClass = Registry.router(for: routableView)
        assert((routerClass?.completeSynchronously())!,"router class (\(String(describing: routerClass))) can't get destination synchronously.")
        routerClass?.perform(configure: { config in
            config.routeType = ViewRouteType.getDestination
            config.prepareForRoute = { d in
                if let destination = d as? Destination {
                    prepare?(destination)
                }
            }
            config.routeCompletion = { d in
                assert(d is Destination,"Bad implementation in router(\(String(describing: routerClass))), destination(\(type(of: d))) is not \(Destination.self) type.")
                destination = d as? Destination
            }
        })
        return destination
    }
    
    /// Get view destination with view config protocol.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a view module config protocol.
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The view destination.
    public static func makeDestination<Module>(
        for routableViewModule: RoutableViewModule<Module>,
        preparation prepare: ((Module) -> Swift.Void)? = nil
        ) -> Any? {
        var destination: Any?
        let routerClass = Registry.router(for: routableViewModule)
        assert((routerClass?.completeSynchronously())!,"router class (\(String(describing: routerClass))) can't get destination synchronously")
        routerClass?.perform(configure: { config in
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
    
    /// Get service destination conforming the service protocol.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a service protocol.
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The service destination.
    public static func makeDestination<Destination>(
        for routableService: RoutableService<Destination>,
        preparation prepare: ((Destination) -> Swift.Void)? = nil
        ) -> Destination? {
        var destination: Destination?
        let routerClass = Registry.router(for: routableService)
        assert((routerClass?.completeSynchronously())!,"router class (\(String(describing: routerClass))) can't get destination synchronously")
        routerClass?.perform(configure: { config in
            config.prepareForRoute = { d in
                if let destination = d as? Destination {
                    prepare?(destination)
                }
            }
            config.routeCompletion = { d in
                assert(d is Destination,"Bad implementation in router(\(String(describing: routerClass))), destination(\(type(of: d))) is not \(Destination.self) type.")
                destination = d as? Destination
            }
        })
        return destination
    }
    
    /// Get service destination with service config protocol.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a service module config protocol.
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The service destination.
    public static func makeDestination<Config>(
        for routableServiceModule: RoutableServiceModule<Config>,
        preparation prepare: ((Config) -> Swift.Void)? = nil
        ) -> Any? {
        var destination: Any?
        let routerClass = Registry.router(for: routableServiceModule)
        assert((routerClass?.completeSynchronously())!,"router class (\(String(describing: routerClass))) can't get destination synchronously")
        routerClass?.perform(configure: { config in
            if config is Config {
                prepare?(config as! Config)
            }
            config.routeCompletion = { d in
                destination = d
            }
        })
        return destination
    }
}
