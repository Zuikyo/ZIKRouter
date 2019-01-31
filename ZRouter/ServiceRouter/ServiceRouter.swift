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

/// Swift Wrapper of ZIKServiceRouter class for supporting pure Swift generic type.
public class ServiceRouterType<Destination, ModuleConfig> {
    
    /// The router type to wrap.
    public let routerType: ZIKAnyServiceRouterType
    
    internal init(routerType: ZIKAnyServiceRouterType) {
        self.routerType = routerType
    }
    
    // MARK: Perform
    
    public typealias ModulePreparation = ((ModuleConfig) -> Void) -> Void
    
    /// Set dependencies required by destination and perform route, and you can remove the route with remove configuration later.
    ///
    /// - Parameters:
    ///   - configBuilder: Build the configuration for performing route.
    ///     - config: Config for performing route.
    ///     - prepareModule: Prepare custom module config.
    ///   - removeConfigBuilder: Configure the configuration for removing route.
    ///     - config: Config for removing route.
    /// - Returns: The service router for this route.
    public func perform(
        configuring configBuilder: (PerformRouteStrictConfig<Destination>, ModulePreparation) -> Void,
        removing removeConfigBuilder: ((RemoveRouteStrictConfig<Destination>) -> Void)? = nil
        ) -> ServiceRouter<Destination, ModuleConfig>? {
        var removeBuilder: ((ZIKRemoveRouteStrictConfiguration<AnyObject>) -> Void)? = nil
        if let removeConfigBuilder = removeConfigBuilder {
            removeBuilder = { (config: ZIKRemoveRouteStrictConfiguration<AnyObject>) in
                removeConfigBuilder(RemoveRouteStrictConfig(configuration: config))
            }
        }
        let routerType = self.routerType
        let router = routerType.perform(strictConfiguring: { (strictConfig, config) in
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                guard let moduleConfig = config as? ModuleConfig else {
                    assertionFailure("Bad implementation in router, configuration (\(config)) should be type (\(ModuleConfig.self))")
                    return
                }
                prepare(moduleConfig)
            }
            configBuilder(PerformRouteStrictConfig(configuration: strictConfig), prepareModule)
            #if DEBUG
            let successHandler = config.successHandler
            config.successHandler = { d in
                successHandler?(d)
                assert(ServiceRouterType._castedDestination(d, routerType: routerType) != nil, "Router (\(String(describing: routerType))) returns wrong destination type (\(d)), destination should be \(Destination.self)")
            }
            #endif
        }, strictRemoving: removeBuilder)
        if let router = router {
            return ServiceRouter<Destination, ModuleConfig>(router: router)
        } else {
            return nil
        }
    }
    
    /// If this route action doesn't need any arguments, perform directly with successHandler and errorHandler for current performing.
    @discardableResult public func perform(successHandler performerSuccessHandler: ((Destination) -> Void)? = nil, errorHandler performerErrorHandler: ((ZIKRouteAction, Error) -> Void)? = nil) -> ServiceRouter<Destination, ModuleConfig>? {
        return perform(configuring: { (config, _) in
            if let performerSuccessHandler = performerSuccessHandler {
                let successHandler = config.performerSuccessHandler
                config.performerSuccessHandler = { destination in
                    successHandler?(destination)
                    performerSuccessHandler(destination)
                }
            }
            if let performerErrorHandler = performerErrorHandler {
                let errorHandler = config.performerErrorHandler
                config.performerErrorHandler = { (action, error) in
                    errorHandler?(action, error)
                    performerErrorHandler(action, error)
                }
            }
        })
    }
    
    /// If this destination doesn't need any variable to initialize, just pass source and perform route with completion for current performing.
    @discardableResult public func perform(completion performerCompletion: @escaping (Bool, Destination?, ZIKRouteAction, Error?) -> Void) -> ServiceRouter<Destination, ModuleConfig>? {
        return perform(successHandler: { (destination) in
            performerCompletion(true, destination, .performRoute, nil);
        }, errorHandler: { (action, error) in
            performerCompletion(false, nil, action, error);
        })
    }
    
    /// Prepare the destination with destination protocol and perform route.
    ///
    /// - Parameters:
    ///   - preparation: Prepare the destination with destination protocol. It's an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The service router for this route.
    @discardableResult public func perform(preparation prepare: @escaping ((Destination) -> Void)) -> ServiceRouter<Destination, ModuleConfig>? {
        return perform(configuring: { (config, _) in
            config.prepareDestination = prepare
        })
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
        assert(destination == nil || ServiceRouterType._castedDestination(destination!, routerType: routerType) != nil, "Router (\(routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        return destination as? Destination
    }
    
    /// Synchronously get destination, and prepare the destination with destination protocol. Preparation is an escaping block, use weakSelf to avoid retain cycle.
    public func makeDestination(preparation prepare: ((Destination) -> Void)? = nil) -> Destination? {
        let routerType = self.routerType
        let destination = routerType.makeDestination(preparation: { d in
            if let destination = ServiceRouterType._castedDestination(d, routerType: routerType) {
                prepare?(destination)
            }
        })
        assert(destination == nil || ServiceRouterType._castedDestination(destination!, routerType: routerType) != nil, "Router (\(routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        return destination as? Destination
    }
    
    /// Synchronously get destination, and prepare the destination.
    ///
    /// - Parameter configBuilder: Build the configuration for performing route.
    ///     - config: Config for performing route.
    ///     - prepareModule: Prepare custom module config.
    /// - Returns: Destination
    public func makeDestination(configuring configBuilder: (PerformRouteStrictConfig<Destination>, ModulePreparation) -> Void) -> Destination? {
        let routerType = self.routerType
        let destination = routerType.makeDestination(strictConfiguring: { (strictConfig, config) in
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                guard let moduleConfig = config as? ModuleConfig else {
                    assertionFailure("Bad implementation in router, configuration (\(config)) should be type (\(ModuleConfig.self))")
                    return
                }
                prepare(moduleConfig)
            }
            configBuilder(PerformRouteStrictConfig(configuration: strictConfig), prepareModule)
        })
        assert(destination == nil || ServiceRouterType._castedDestination(destination!, routerType: routerType) != nil, "Router (\(routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        return destination as? Destination
    }
    
    private static func _castedDestination(_ destination: Any, routerType: ZIKAnyServiceRouterType) -> Destination? {
        if let d = destination as? Destination {
            #if DEBUG
            assert(Registry.validateConformance(destination: d, inServiceRouterType: routerType))
            #endif
            return d
        } else if let d = (destination as AnyObject) as? Destination {
            #if DEBUG
            assert(Registry.validateConformance(destination: d, inServiceRouterType: routerType))
            #endif
            return d
        } else {
            assertionFailure("Router (\(routerType)) returns wrong destination type (\(destination)), destination should be \(Destination.self)")
        }
        return nil
    }
}

/// Swift Wrapper of ZIKServiceRouter for supporting pure Swift generic type.
public class ServiceRouter<Destination, ModuleConfig> {
    /// The routed ZIKServiceRouter.
    public let router: ZIKAnyServiceRouter
    
    internal init(router: ZIKAnyServiceRouter) {
        self.router = router
    }
    
    /// State of route.
    public var state: ZIKRouterState {
        return router.state
    }
    
    /// Configuration for performRoute; Return copy of configuration, so modify this won't change the real configuration inside router.
    public var configuration: PerformRouteConfig {
        return router.configuration
    }
    
    /// Configuration for removeRoute; Return copy of configuration, so modify this won't change the real configuration inside router.
    public var removeConfiguration: RouteConfig? {
        return router.removeConfiguration
    }
    
    /// Latest error when route action failed.
    public var error: Error? {
        return router.error
    }
    
    // MARK: Perform
    
    /// Whether the router can perform route now.
    public var canPerform: Bool {
        return router.canPerform()
    }
    
    /// If this route action doesn't need any arguments, perform directly with successHandler and errorHandler for current performing.
    public func performRoute(successHandler: ((Destination) -> Void)? = nil, errorHandler: ((ZIKRouteAction, Error) -> Void)? = nil) {
        router.performRoute(successHandler: { (d) in
            if let destination = d as? Destination {
                successHandler?(destination)
            }
        }, errorHandler: errorHandler)
    }
    
    /// If this route action doesn't need any arguments, perform directly with completion for current performing.
    public func performRoute(completion performerCompletion: @escaping (Bool, Destination?, ZIKRouteAction, Error?) -> Void) {
        performRoute(successHandler: { (destination) in
            performerCompletion(true, destination, .performRoute, nil)
        }, errorHandler: { (action, error) in
            performerCompletion(false, nil, action, error)
        })
    }
    
    // MARK: Remove
    
    /// Whether the router should be removed before another performing, when the router is performed already and the destination still exists.
    public var shouldRemoveBeforePerform: Bool {
        return router.shouldRemoveBeforePerform()
    }
    
    /// Whether the router can remove route now. Default is false.
    public var canRemove: Bool {
        return router.canRemove()
    }
    
    /// Remove with success handler and error handler. If canRemove return false, this will fail.
    public func removeRoute(successHandler performerSuccessHandler: (() -> Void)? = nil, errorHandler performerErrorHandler: ((ZIKRouteAction, Error) -> Void)? = nil) {
        router.removeRoute(successHandler: performerSuccessHandler, errorHandler: performerErrorHandler)
    }
    
    /// Remove route with completion for current removing.
    public func removeRoute(completion performerCompletion: @escaping (Bool, ZIKRouteAction, Error?) -> Void) {
        removeRoute(successHandler: {
            performerCompletion(true, .removeRoute, nil)
        }, errorHandler: { (action, error) in
            performerCompletion(false, action, error)
        })
    }
    
    /// Remove route and prepare before removing.
    ///
    /// - Parameter configBuilder: Configure the configuration for removing route.
    ///     - config: Config for removing route.
    public func removeRoute(configuring configBuilder: @escaping (RemoveRouteStrictConfig<Destination>) -> Void) {
        let removeBuilder = { (config: ZIKRemoveRouteStrictConfiguration<AnyObject>) in
            configBuilder(RemoveRouteStrictConfig(configuration: config))
        }
        router.removeRoute(strictConfiguring: removeBuilder)
    }
}

// MARK: Strict Config

/// Proxy of ZIKRouteConfiguration to handle configuration in a type safe way.
public class RouteStrictConfig<Config: ZIKRouteStrictConfiguration<AnyObject>> {
    public fileprivate(set) var configuration: Config
    internal init(configuration: Config) {
        self.configuration = configuration
    }
    /// Error handler for router's provider. Each time the router was performed or removed, error handler will be called when the operation fails. It's an escaping block.
    ///
    /// - Note: Use weak self in errorHandler to avoid retain cycle.
    public var errorHandler: ((ZIKRouteAction, Error) -> Void)? {
        get { return configuration.errorHandler }
        set { configuration.errorHandler = newValue }
    }
    /// Error handler for current performing, will reset to nil after performed.
    public var performerErrorHandler: ((ZIKRouteAction, Error) -> Void)? {
        get { return configuration.performerErrorHandler }
        set { configuration.performerErrorHandler = newValue }
    }
    /// Monitor state. It's an escaping block.
    ///
    /// - Note: Use weak self in stateNotifier to avoid retain cycle.
    public var stateNotifier: ((ZIKRouterState, ZIKRouterState) -> Void)? {
        get { return configuration.stateNotifier }
        set { configuration.stateNotifier = newValue }
    }
}

/// Proxy of ZIKPerformRouteConfiguration to handle configuration in a type safe way.
public class PerformRouteStrictConfig<Destination>: RouteStrictConfig<ZIKPerformRouteStrictConfiguration<AnyObject>> {
    internal override init(configuration: ZIKPerformRouteStrictConfiguration<AnyObject>) {
        super.init(configuration: configuration)
    }
    /// Prepare for performRoute, and config other dependency for destination here. Subclass can offer more specific info. It's an escaping block.
    ///
    /// - Note: Use weak self in prepareDestination to avoid retain cycle.
    public var prepareDestination: ((Destination) -> Void)? {
        get {
            if let prepare = configuration.prepareDestination {
                return { destiantion in
                    prepare(destiantion as AnyObject)
                }
            }
            return nil
        }
        set {
            if let prepare = newValue {
                configuration.prepareDestination = { d in
                    guard let destination = d as? Destination else {
                        assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                        return
                    }
                    prepare(destination)
                }
            } else {
                configuration.prepareDestination = nil
            }
        }
    }
    
    /// Success handler for router's provider. Each time the router was performed, success handler will be called when the operation succeed. It's an escaping block.
    ///
    /// - Note: Use weak self in successHandler to avoid retain cycle.
    public var successHandler: ((Destination) -> Void)? {
        get {
            if let handler = configuration.successHandler {
                return { destiantion in
                    handler(destiantion as AnyObject)
                }
            }
            return nil
        }
        set {
            if let handler = newValue {
                configuration.successHandler = { d in
                    guard let destination = d as? Destination else {
                        assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                        return
                    }
                    handler(destination)
                }
            } else {
                configuration.successHandler = nil
            }
        }
    }
    
    /// Success handler for current performing, will reset to nil after performed.
    public var performerSuccessHandler: ((Destination) -> Void)? {
        get {
            if let handler = configuration.performerSuccessHandler {
                return { destiantion in
                    handler(destiantion as AnyObject)
                }
            }
            return nil
        }
        set {
            if let handler = newValue {
                configuration.performerSuccessHandler = { d in
                    guard let destination = d as? Destination else {
                        assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                        return
                    }
                    handler(destination)
                }
            } else {
                configuration.performerSuccessHandler = nil
            }
        }
    }
    
    /// Completion handler for performRoute. It's an escaping block.
    ///
    /// - Note: Use weak self in completionHandler to avoid retain cycle.
    public var completionHandler: ((Bool, Destination?, ZIKRouteAction, Error?) -> Void)? {
        get {
            if let handler = configuration.completionHandler {
                return { (success, destiantion: Destination?, action, error) in
                    handler(success, destiantion as AnyObject, action, error)
                }
            }
            return nil
        }
        set {
            if let handler = newValue {
                configuration.completionHandler = { (success, d, action, error) in
                    if d == nil {
                        handler(success, nil, action, error)
                    } else if let destination = d as? Destination {
                        handler(success, destination, action, error)
                    } else {
                        assertionFailure("Bad implementation in router, destination (\(d!)) should be type (\(Destination.self))")
                    }
                }
            } else {
                configuration.completionHandler = nil
            }
        }
    }
    
    /// User info when handle route action from URL Scheme.
    public var userInfo: [String : Any] {
        get { return configuration.userInfo }
    }
    
    /// Add user info.
    ///
    /// - Note: You should only use user info when handle route action from URL Scheme, because it's not recommanded to passing parameters in dictionary. The compiler can't check parameters' type.
    public func addUserInfo(forKey key: String, object: Any) {
        configuration.addUserInfo(forKey: key, object: object)
    }
    
    /// Add user info.
    ///
    /// - Note: You should only use user info when handle route action from URL Scheme, because it's not recommanded to passing parameters in dictionary. The compiler can't check parameters' type.
    public func addUserInfo(_ userInfo: [String : Any]) {
        configuration.addUserInfo(userInfo)
    }
}

/// Proxy of ZIKRemoveRouteConfiguration to handle configuration in a type safe way.
public class RemoveRouteStrictConfig<Destination>: RouteStrictConfig<ZIKRemoveRouteStrictConfiguration<AnyObject>> {
    internal override init(configuration: ZIKRemoveRouteStrictConfiguration<AnyObject>) {
        super.init(configuration: configuration)
    }
    
    /// Prepare for removeRoute. Subclass can offer more specific info. It's an escaping block.
    ///
    /// - Note: Use weak self in prepareDestination to avoid retain cycle.
    public var prepareDestination: ((Destination) -> Void)? {
        get {
            if let prepare = configuration.prepareDestination {
                return { destiantion in
                    prepare(destiantion as AnyObject)
                }
            }
            return nil
        }
        set {
            if let prepare = newValue {
                configuration.prepareDestination = { d in
                    guard let destination = d as? Destination else {
                        assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                        return
                    }
                    prepare(destination)
                }
            } else {
                configuration.prepareDestination = nil
            }
        }
    }
    
    /// Success handler for router's provider. Each time the router was removed, success handler will be called when the operation succeed. It's an escaping block.
    ///
    /// - Note: Use weak self in successHandler to avoid retain cycle.
    public var successHandler: (() -> Void)? {
        get { return configuration.successHandler }
        set { configuration.successHandler = newValue }
    }
    
    /// Success handler for current removing, will reset to nil after removed.
    public var performerSuccessHandler: (() -> Void)? {
        get { return configuration.performerSuccessHandler }
        set { configuration.performerSuccessHandler = newValue }
    }
    
    /// Completion handler for removeRoute. It's an escaping block.
    ///
    /// - Note: Use weak self in completionHandler to avoid retain cycle.
    public var completionHandler: ZIKRemoveRouteCompletion? {
        get { return configuration.completionHandler }
        set { configuration.completionHandler = newValue }
    }
}
