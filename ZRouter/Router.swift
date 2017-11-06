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
internal class Router {
    
    /// Perform route with view protocol and prepare the destination with the protocol.
    ///
    /// - Parameters:
    ///   - viewProtocol: The view protocol registered with a view router.
    ///   - configure: Configure the configuration for view route.
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The view router.
    internal static func perform<Destination>(
        forViewProtocol viewProtocol:Destination.Type,
        routeConfig configure: (ViewRouteConfig) -> Swift.Void,
        preparation prepare: ((Destination) -> Swift.Void)? = nil
        ) -> DefaultViewRouter? {
        return Registry.router(forView: viewProtocol)?.perform(configure: { config in
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
    ///   - configProtocol: The config protocol registered with a view router.
    ///   - configure: Configure the configuration for view route.
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The view router.
    internal static func perform<Config>(
        forViewModule configProtocol:Config.Type,
        routeConfig configure: (ViewRouteConfig) -> Swift.Void,
        preparation prepare: ((Config) -> Swift.Void)? = nil
        ) -> DefaultViewRouter? {
        return Registry.router(forViewModule: configProtocol)?.perform(configure: { config in
            configure(config)
            if let configuration = config as? Config {
                prepare?(configuration)
            }
        })
    }
    
    /// Perform route with service protocol and prepare the destination with the protocol.
    ///
    /// - Parameters:
    ///   - serviceProtocol: The service protocol registered with a service router.
    ///   - configure: Configure the configuration for service route.
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The service router.
    internal static func perform<Destination>(
        forServiceProtocol serviceProtocol:Destination.Type,
        routeConfig configure: (ServiceRouteConfig) -> Swift.Void,
        preparation prepare: ((Destination) -> Swift.Void)? = nil
        ) -> DefaultServiceRouter? {
        return Registry.router(forService: serviceProtocol)?.perform(configure: { config in
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
    ///   - configProtocol: The module config protocol registered with a service router.
    ///   - configure: Configure the configuration for service route.
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The service router.
    internal static func perform<Module>(
        forServiceModule configProtocol:Module.Type,
        routeConfig configure: (ServiceRouteConfig) -> Swift.Void,
        preparation prepare: ((Module) -> Swift.Void)? = nil
        ) -> DefaultServiceRouter? {
        return Registry.router(forServiceModule: configProtocol)?.perform(configure: { config in
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
    ///   - viewProtocol: The view protocol registered with a view router.
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The view destination.
    internal static func makeDestination<Destination>(
        forViewProtocol viewProtocol:Destination.Type,
        preparation prepare: ((Destination) -> Swift.Void)? = nil
        ) -> Destination? {
        var destination: Destination?
        let routerClass = Registry.router(forView: viewProtocol)
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
    ///   - configProtocol: The config protocol registered with a view router.
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The view destination.
    internal static func makeDestination<Module>(
        forViewModule configProtocol:Module.Type,
        preparation prepare: ((Module) -> Swift.Void)? = nil
        ) -> Any? {
        var destination: Any?
        let routerClass = Registry.router(forViewModule: configProtocol)
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
    ///   - serviceProtocol: The service protocol registered with a service router.
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The service destination.
    internal static func makeDestination<Destination>(
        forServiceProtocol serviceProtocol:Destination.Type,
        preparation prepare: ((Destination) -> Swift.Void)? = nil
        ) -> Destination? {
        var destination: Destination?
        let routerClass = Registry.router(forService: serviceProtocol)
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
    ///   - configProtocol: The config protocol registered with a service router.
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The service destination.
    internal static func makeDestination<Config>(
        forServiceModule configProtocol:Config.Type,
        preparation prepare: ((Config) -> Swift.Void)? = nil
        ) -> Any? {
        var destination: Any?
        let routerClass = Registry.router(forServiceModule: configProtocol)
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
