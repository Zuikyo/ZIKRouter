//
//  ServiceRouter.swift
//  ZRouter
//
//  Created by zuik on 2017/11/23.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import ZIKRouter.Internal

/// Swift Wrapper for ZIKServiceRouter.
public class ServiceRouter<Destination, ModuleConfig> {
    
    /// The router type to wrap.
    public let routerType: ZIKAnyServiceRouter.Type
    
    /// The routed ZIKServiceRouter.
    public private(set) var routed: ZIKAnyServiceRouter?
    
    internal init(routerType: ZIKAnyServiceRouter.Type) {
        self.routerType = routerType
    }
    
    /// State of route.
    public var state: ZIKRouterState {
        return routed?.state ?? ZIKRouterState.notRoute
    }
    
    /// Configuration for performRoute; Return copy of configuration, so modify this won't change the real configuration inside router.
    public var configuration: PerformRouteConfig {
        return routed?.configuration ?? routerType.defaultRouteConfiguration()
    }
    
    /// Configuration for removeRoute; return copy of configuration, so modify this won't change the real configuration inside router.
    public var removeConfiguration: RouteConfig? {
        return routed?.removeConfiguration
    }
    
    /// Latest error when route action failed.
    public var error: Error? {
        return routed?.error
    }
    
    // MARK: Perform
    
    /// Whether the router can perform route now.
    public var canPerform: Bool {
        return routed?.canPerform() ?? true
    }
    
    public typealias DestinationPreparation = (@escaping (Destination) -> Void) -> Void
    public typealias ModulePreparation = ((ModuleConfig) -> Void) -> Void
    public typealias RemovePreparation = ((RemoveRouteConfig) -> Void) -> Void
    
    /// Set dependencies required by destination and perform route, and you can remove the route with remove configuration later.
    ///
    /// - Parameters:
    ///   - configBuilder: Build the configuration for performing route.
    ///     - config: Config for performing route.
    ///     - prepareDestination: Prepare destination before performing route. It's an escaping block, use weakSelf to avoid retain cycle.
    ///     - prepareModule: Prepare custom moudle config.
    ///   - removeConfigBuilder: Configure the configuration for removing route.
    ///     - config: Config for removing route.
    ///     - prepareDestination: Prepare destination before removing route. It's an escaping block, use weakSelf to avoid retain cycle.
    public func perform(configuring configBuilder: (PerformRouteConfig, DestinationPreparation, ModulePreparation) -> Void, removing removeConfigBuilder: ((RemoveRouteConfig, DestinationPreparation, RemovePreparation) -> Void)? = nil) {
        var removeBuilder: ((RemoveRouteConfig) -> Void)? = nil
        if let configBuilder = removeConfigBuilder {
            removeBuilder = { (config: RemoveRouteConfig) in
                let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                    config.prepareDestination = { d in
                        if let destination = d as? Destination {
                            prepare(destination)
                        }
                    }
                }
                let prepareModule = { (prepare: (RemoveRouteConfig) -> Void) in
                    prepare(config)
                }
                configBuilder(config, prepareDestination, prepareModule)
            }
        }
        let routerType = self.routerType
        routed = routerType.perform(configuring: { config in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    if let destination = ServiceRouter._castedDestination(d, routerType: routerType) {
                        prepare(destination)
                    }
                }
            }
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                if let moduleConfig = config as? ModuleConfig {
                    prepare(moduleConfig)
                }
            }
            configBuilder(config, prepareDestination, prepareModule)
            if shouldCheckServiceRouter {
                let completion = config.routeCompletion
                config.routeCompletion = { d in
                    completion?(d)
                    assert(ServiceRouter._castedDestination(d, routerType: routerType) != nil, "Router (\(String(describing: routerType))) returns wrong destination type (\(String(describing: d))), destination should be \(Destination.self)")
                }
            }
        }, removing: removeBuilder)
        
    }
    
    // MARK: Remove
    
    /// Whether the router can remove route now. Default is false.
    public var canRemove: Bool {
        return routed?.canRemove() ?? false
    }
    
    /// Remove with success handler and error handler. If canRemove return false, this will failed.
    public func removeRoute(successHandler performerSuccessHandler: (() -> Void)?, errorHandler performerErrorHandler: ((ZIKRouteAction, Error) -> Void)? = nil) {
        routed?.removeRoute(successHandler: performerSuccessHandler, errorHandler: performerErrorHandler)
    }
    
    /// Remove route and prepare before removing.
    ///
    /// - Parameter configBuilder: Configure the configuration for removing route.
    ///     - config: Config for removing route.
    ///     - prepareDestination: Prepare destination before removing route. It's an escaping block, use weakSelf to avoid retain cycle.
    public func removeRoute(configuring configBuilder: @escaping (RemoveRouteConfig, DestinationPreparation, RemovePreparation) -> Void) {
        let removeBuilder = { (config: RemoveRouteConfig) in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    if let destination = d as? Destination {
                        prepare(destination)
                    }
                }
            }
            let prepareModule = { (prepare: (RemoveRouteConfig) -> Void) in
                prepare(config)
            }
            configBuilder(config, prepareDestination, prepareModule)
        }
        routed?.removeRoute(configuring: removeBuilder)
    }
    
    // MARK: Make Destination
    
    /// Whether the destination is instantiated synchronously.
    public var canMakeDestinationSynchronously: Bool {
        return routerType.canMakeDestinationSynchronously()
    }
    
    /// The router may can't make destination synchronously, or it's not for providing a destination but only for performing some actions.
    public var canMakeDestination: Bool {
        return routerType.canMakeDestination()
    }
    
    /// Synchronously get destination.
    public func makeDestination() -> Destination? {
        let routerType = self.routerType
        let destination = routerType.makeDestination()
        assert(destination == nil || ServiceRouter._castedDestination(destination!, routerType: routerType) != nil, "Router (\(routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        return destination as? Destination
    }
    
    /// Synchronously get destination, and prepare the destination with destination protocol. Preparation is an escaping block, use weakSelf to avoid retain cycle.
    public func makeDestination(preparation prepare: ((Destination) -> Void)? = nil) -> Destination? {
        let routerType = self.routerType
        let destination = routerType.makeDestination(preparation: { d in
            if let destination = ServiceRouter._castedDestination(d, routerType: routerType) {
                prepare?(destination)
            }
        })
        assert(destination == nil || ServiceRouter._castedDestination(destination!, routerType: routerType) != nil, "Router (\(routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        return destination as? Destination
    }
    
    /// Synchronously get destination, and prepare the destination.
    ///
    /// - Parameter configBuilder: Build the configuration for performing route.
    ///     - config: Config for performing route.
    ///     - prepareDestination: Prepare destination before performing route. It's an escaping block, use weakSelf to avoid retain cycle.
    ///     - prepareModule: Prepare custom moudle config.
    /// - Returns: Destination
    public func makeDestination(configuring configBuilder: @escaping (PerformRouteConfig, DestinationPreparation, ModulePreparation) -> Void) -> Destination? {
        let routerType = self.routerType
        let destination = routerType.makeDestination(configuring: { config in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    if let destination = ServiceRouter._castedDestination(d, routerType: routerType) {
                        prepare(destination)
                    }
                }
            }
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                if let moduleConfig = config as? ModuleConfig {
                    prepare(moduleConfig)
                }
            }
            configBuilder(config, prepareDestination, prepareModule)
        })
        assert(destination == nil || ServiceRouter._castedDestination(destination!, routerType: routerType) != nil, "Router (\(routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        return destination as? Destination
    }
    
    private static func _castedDestination(_ destination: Any, routerType: ZIKAnyServiceRouter.Type) -> Destination? {
        if let d = destination as? Destination {
            if shouldCheckServiceRouter {
                assert(Registry.validateConformance(destination: d, inServiceRouterType: routerType))
            }
            return d
        } else if let d = (destination as AnyObject) as? Destination {
            if shouldCheckServiceRouter {
                assert(Registry.validateConformance(destination: d, inServiceRouterType: routerType))
            }
            return d
        } else {
            assertionFailure("Router (\(routerType)) returns wrong destination type (\(destination)), destination should be \(Destination.self)")
        }
        return nil
    }
    
    public func description(of state: ZIKRouterState) -> String {
        return routerType.description(of: state)
    }
}
