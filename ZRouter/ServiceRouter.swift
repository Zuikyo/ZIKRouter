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
    
    public var state: ZIKRouterState {
        return routed?.state ?? ZIKRouterState.notRoute
    }
    
    public var configuration: PerformRouteConfig {
        return routed?.configuration ?? routerType.defaultRouteConfiguration()
    }
    
    public var removeConfiguration: RouteConfig? {
        return routed?.removeConfiguration
    }
    
    public var error: Error? {
        return routed?.error
    }
    
    public var completeSynchronously: Bool {
        return routerType.completeSynchronously()
    }
    
    // MARK: Perform
    
    public var canPerform: Bool {
        return routed?.canPerform() ?? true
    }
    
    public typealias DestinationPreparation = (@escaping (Destination) -> Void) -> Void
    public typealias ModulePreparation = ((ModuleConfig) -> Void) -> Void
    public typealias RemovePreparation = ((RemoveRouteConfig) -> Void) -> Void
    
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
    
    public var canRemove: Bool {
        return routed?.canRemove() ?? false
    }
    
    public func removeRoute(successHandler performerSuccessHandler: (() -> Void)?, errorHandler performerErrorHandler: ((ZIKRouteAction, Error) -> Void)? = nil) {
        routed?.removeRoute(successHandler: performerSuccessHandler, errorHandler: performerErrorHandler)
    }
    
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
    
    public var canMakeDestination: Bool {
        return routerType.canMakeDestination()
    }
    
    public func makeDestination() -> Destination? {
        let routerType = self.routerType
        let destination = routerType.makeDestination()
        assert(destination == nil || ServiceRouter._castedDestination(destination!, routerType: routerType) != nil, "Router (\(routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        return destination as? Destination
    }
    
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
