//
//  ViewRouter.swift
//  ZRouter
//
//  Created by zuik on 2017/11/22.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import ZIKRouter.Internal

/// Swift Wrapper for ZIKViewRouter.
public class ViewRouter<Destination, ModuleConfig, RemoveConfig> {
    
    /// The router type to wrap.
    public let routerType: ZIKAnyViewRouter.Type
    
    /// The routed ZIKViewRouter.
    public private(set) var routed: ZIKAnyViewRouter?
    
    internal init(routerType: ZIKAnyViewRouter.Type) {
        self.routerType = routerType
    }
    
    public var state: ZIKRouterState {
        return routed?.state ?? ZIKRouterState.notRoute
    }
    
    public var configuration: ViewRouteConfig {
        return routed?.configuration ?? routerType.defaultRouteConfiguration()
    }
    
    public var removeConfiguration: ViewRemoveConfig? {
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
    
    public func perform(from source: ZIKViewRouteSource?, configuring configBuilder: (ViewRouteConfig, DestinationPreparation, ModulePreparation) -> Void, removing removeConfigBuilder: ((ViewRemoveConfig, RemovePreparation) -> Void)? = nil) {
        var removeBuilder: ((ViewRemoveConfig) -> Void)? = nil
        if removeConfigBuilder != nil {
            removeBuilder = { (config: ViewRemoveConfig) in
                let prepareModule = { (prepare: (RemoveConfig) -> Void) in
                    if config is RemoveConfig {
                        prepare(config as! RemoveConfig)
                    }
                }
                removeConfigBuilder!(config, prepareModule)
            }
        }
        
        routed = routerType.perform(from: source, configuring: { config in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    if d is Destination {
                        prepare(d as! Destination)
                    } else {
                        assertionFailure("Router (\(self.routerType)) returns wrong destination type, destination should be \(Destination.self)")
                    }
                }
            }
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                if config is ModuleConfig {
                    prepare(config as! ModuleConfig)
                }
            }
            configBuilder(config, prepareDestination, prepareModule)
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
        assert(destination == nil || destination is Destination, "Router (\(self.routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        return destination as? Destination
    }
    
    public func makeDestination(preparation prepare: ((Destination) -> Void)? = nil) -> Destination? {
        let destination = routerType.makeDestination(preparation: { d in
            if d is Destination {
                prepare?(d as! Destination)
            }
        })
        assert(destination == nil || destination is Destination, "Router (\(self.routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        return destination as? Destination
    }
    
    public func makeDestination(configuring configBuilder: @escaping (ViewRouteConfig, DestinationPreparation, ModulePreparation) -> Void) -> Destination? {
        let destination = routerType.makeDestination(configuring: { config in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    if d is Destination {
                        prepare(d as! Destination)
                    }
                }
            }
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                if config is ModuleConfig {
                    prepare(config as! ModuleConfig)
                }
            }
            configBuilder(config, prepareDestination, prepareModule)
        })
        assert(destination == nil || destination is Destination, "Router (\(self.routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        return destination as? Destination
    }
    
    
    public func description(of state: ZIKRouterState) -> String {
        return routerType.description(of: state)
    }
}
