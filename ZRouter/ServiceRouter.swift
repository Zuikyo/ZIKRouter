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
public class ServiceRouter<Destination, ModuleConfig, RemoveConfig> {
    
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
    public typealias RemovePreparation = ((RemoveConfig) -> Void) -> Void
    
    public func perform(configuring configBuilder: (PerformRouteConfig, DestinationPreparation, ModulePreparation) -> Void, removing removeConfigBuilder: ((RouteConfig, RemovePreparation) -> Void)? = nil) {
        var removeBuilder: ((RouteConfig) -> Void)? = nil
        if let configBuilder = removeConfigBuilder {
            removeBuilder = { (config: RouteConfig) in
                let prepareModule = { (prepare: (RemoveConfig) -> Void) in
                    if let removeConfig = config as? RemoveConfig {
                        prepare(removeConfig)
                    }
                }
                configBuilder(config, prepareModule)
            }
        }
        
        routed = routerType.perform(configuring: { config in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    if let destination = self._castedDestination(d) {
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
                    assert(self._castedDestination(d) != nil, "Router (\(self.routerType)) returns wrong destination type (\(String(describing: d))), destination should be \(Destination.self)")
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
    
    // MARK: Make Destination
    
    public var canMakeDestination: Bool {
        return routerType.canMakeDestination()
    }
    
    public func makeDestination() -> Destination? {
        let destination = routerType.makeDestination()
        assert(destination == nil || self._castedDestination(destination!) != nil, "Router (\(self.routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        return destination as? Destination
    }
    
    public func makeDestination(preparation prepare: ((Destination) -> Void)? = nil) -> Destination? {
        let destination = routerType.makeDestination(preparation: { d in
            if let destination = self._castedDestination(d) {
                prepare?(destination)
            }
        })
        assert(destination == nil || self._castedDestination(destination!) != nil, "Router (\(self.routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        return destination as? Destination
    }
    
    public func makeDestination(configuring configBuilder: @escaping (PerformRouteConfig, DestinationPreparation, ModulePreparation) -> Void) -> Destination? {
        let destination = routerType.makeDestination(configuring: { config in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    if let destination = self._castedDestination(d) {
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
        assert(destination == nil || self._castedDestination(destination!) != nil, "Router (\(self.routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        return destination as? Destination
    }
    
    private func _castedDestination(_ destination: Any) -> Destination? {
        if let d = destination as? Destination {
            if shouldCheckServiceRouter {
                _ = Registry.validateConformance(destination: d, inServiceRouterType: routerType)
            }
            return d
        } else if let d = (destination as AnyObject) as? Destination {
            if shouldCheckServiceRouter {
                _ = Registry.validateConformance(destination: d, inServiceRouterType: routerType)
            }
            return d
        } else {
            assertionFailure("Router (\(self.routerType)) returns wrong destination type (\(destination)), destination should be \(Destination.self)")
        }
        return nil
    }
    
    public func description(of state: ZIKRouterState) -> String {
        return routerType.description(of: state)
    }
}
