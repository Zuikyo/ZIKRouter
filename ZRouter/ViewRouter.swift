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

/// Swift Wrapper for ZIKViewRouter class.
public class ViewRouterType<Destination, ModuleConfig> {
    
    /// The router type to wrap.
    public let routerType: ZIKAnyViewRouter.Type
    
    internal init(routerType: ZIKAnyViewRouter.Type) {
        self.routerType = routerType
    }
    
    // MARK: Perform
    
    public typealias DestinationPreparation = (@escaping (Destination) -> Void) -> Void
    public typealias ModulePreparation = ((ModuleConfig) -> Void) -> Void
    
    /// Perform route from source view to destination view, and config the remove route.
    ///
    /// - Parameters:
    ///   - source: Source UIViewController or UIView. See ViewRouteConfig's source.
    ///   - configBuilder: Build the configuration for performing route.
    ///     - config: Config for view route.
    ///     - prepareDestination: Prepare destination before performing route. It's an escaping block, use weakSelf to avoid retain cycle.
    ///     - prepareModule: Prepare custom moudle config.
    ///   - removeConfigBuilder: Configure the configuration for removing view.
    ///     - config: Config for removing view route.
    ///     - prepareDestination: Prepare destination before removing route. It's an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The view router for this route.
    @discardableResult public func perform(from source: ZIKViewRouteSource?, configuring configBuilder: (ViewRouteConfig, DestinationPreparation, ModulePreparation) -> Void, removing removeConfigBuilder: ((ViewRemoveConfig, DestinationPreparation) -> Void)? = nil) -> ViewRouter<Destination, ModuleConfig>? {
        var removeBuilder: ((ViewRemoveConfig) -> Void)? = nil
        if let removeConfigBuilder = removeConfigBuilder {
            removeBuilder = { (config: ViewRemoveConfig) in
                let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                    config.prepareDestination = { d in
                        if let destination = d as? Destination {
                            prepare(destination)
                        }
                    }
                }
                removeConfigBuilder(config, prepareDestination)
            }
        }
        let routerType = self.routerType
        let router = routerType.perform(from: source, configuring: { config in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    if let destination = d as? Destination {
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
                    assert(d is Destination, "Router (\(routerType)) returns wrong destination type (\(String(describing: d))), destination should be \(Destination.self)")
                    assert(Registry.validateConformance(destination: d, inViewRouterType: routerType))
                }
            }
        }, removing: removeBuilder)
        if let router = router {
            return ViewRouter<Destination, ModuleConfig>(router: router)
        } else {
            return nil
        }
    }
    
    /// If this destination doesn't need any variable to initialize, just pass source and perform route.
    ///
    /// - Parameters:
    ///   - source: Source UIViewController or UIView. See ViewRouteConfig's source.
    ///   - routeType: The style of route.
    /// - Returns: The view router for this route.
    @discardableResult public func perform(from source: ZIKViewRouteSource?, routeType: ViewRouteType) -> ViewRouter<Destination, ModuleConfig>? {
        return perform(from: source, configuring: { (config, _, _) in
            config.routeType = routeType
        })
    }
    
    // MARK: Perform on Destination
    
    /// Perform route on destination. If you get a prepared destination by ZIKViewRouteTypeGetDestination, you can use this method to perform route on the destination.
    ///
    /// - Parameters:
    ///   - destination: The destination to perform route.
    ///   - source: The source view.
    ///   - configBuilder: Builder for config when perform route.
    ///   - removeConfigBuilder: Builder for config when remove route.
    /// - Returns: The view router for this route.
    @discardableResult public func perform(onDestination destination: Destination, from source: ZIKViewRouteSource?, configuring configBuilder: (ViewRouteConfig, DestinationPreparation, ModulePreparation) -> Void, removing removeConfigBuilder: ((ViewRemoveConfig, DestinationPreparation) -> Void)? = nil) -> ViewRouter<Destination, ModuleConfig>? {
        var removeBuilder: ((ViewRemoveConfig) -> Void)? = nil
        if let removeConfigBuilder = removeConfigBuilder {
            removeBuilder = { (config: ViewRemoveConfig) in
                let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                    config.prepareDestination = { d in
                        if let destination = d as? Destination {
                            prepare(destination)
                        }
                    }
                }
                removeConfigBuilder(config, prepareDestination)
            }
        }
        guard let dest = destination as? ZIKRoutableView else {
            ZIKAnyViewRouter._callbackGlobalErrorHandler(with: nil, action: .init, error: ZIKAnyViewRouter.error(withCode: ZIKViewRouteError.invalidConfiguration.rawValue, localizedDescription: "Perform route on invalid destination: \(destination)"))
            return nil
        }
        let router = routerType.perform(onDestination: dest, from: source, configuring: { (config) in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    if let destination = d as? Destination {
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
        }, removing: removeBuilder)
        
        guard let routed = router else {
            return nil
        }
        assert(Registry.validateConformance(destination: dest, inViewRouterType: routerType))
        return ViewRouter<Destination, ModuleConfig>(router: routed)
    }
    
    /// Perform route on destination with route type. If you get a prepared destination by ZIKViewRouteTypeGetDestination, you can use this method to perform route on the destination.
    ///
    /// - Parameters:
    ///   - destination: The destination to perform route.
    ///   - source: The source view.
    ///   - routeType: Route type to perform.
    /// - Returns: The view router for this route. If the destination is not registered with this router class, return nil and get assert failure.
    @discardableResult public func perform(onDestination destination: Destination, from source: ZIKViewRouteSource?, routeType: ViewRouteType) -> ViewRouter<Destination, ModuleConfig>? {
        return perform(onDestination: destination, from: source, configuring: { (config, _, _) in
            config.routeType = routeType
        })
    }
    
    // MARK: Prepare Destination
    
    /// Prepare destination from external, then you can use the router to perform route. You can also use this as a builder to prepare view created from external.
    ///
    /// - Parameters:
    ///   - destination: The destination to prepare. Destination must be registered with this router class.
    ///   - configBuilder: Builder for config when perform route.
    ///   - removeConfigBuilder: Builder for config when remove route.
    /// - Returns: The view router for this route. If the destination is not registered with this router class, return nil and get assert failure.
    @discardableResult public func prepare(destination: Destination, configuring configBuilder: @escaping (ViewRouteConfig, DestinationPreparation, ModulePreparation) -> Void, removing removeConfigBuilder: ((ViewRemoveConfig, DestinationPreparation) -> Void)? = nil) -> ViewRouter<Destination, ModuleConfig>? {
        var removeBuilder: ((ViewRemoveConfig) -> Void)? = nil
        if let removeConfigBuilder = removeConfigBuilder {
            removeBuilder = { (config: ViewRemoveConfig) in
                let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                    config.prepareDestination = { d in
                        if let destination = d as? Destination {
                            prepare(destination)
                        }
                    }
                }
                removeConfigBuilder(config, prepareDestination)
            }
        }
        guard let dest = destination as? ZIKRoutableView else {
            ZIKAnyViewRouter._callbackGlobalErrorHandler(with: nil, action: .init, error: ZIKAnyViewRouter.error(withCode: ZIKViewRouteError.invalidConfiguration.rawValue, localizedDescription: "Perform route on invalid destination: \(destination)"))
            return nil
        }
        let router = routerType.prepareDestination(dest, configuring: { (config) in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    if let destination = d as? Destination {
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
        }, removing: removeBuilder)
        
        guard let routed = router else {
            return nil
        }
        assert(Registry.validateConformance(destination: dest, inViewRouterType: routerType))
        return ViewRouter<Destination, ModuleConfig>(router: routed)
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
        let destination = routerType.makeDestination()
        assert(destination == nil || destination is Destination, "Router (\(routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        assert(destination == nil || Registry.validateConformance(destination: destination!, inViewRouterType: routerType))
        return destination as? Destination
    }
    
    /// Synchronously get destination, and prepare the destination with destination protocol. Preparation is an escaping block, use weakSelf to avoid retain cycle.
    public func makeDestination(preparation prepare: ((Destination) -> Void)? = nil) -> Destination? {
        let destination = routerType.makeDestination(preparation: { d in
            if let destination = d as? Destination {
                prepare?(destination)
            }
        })
        assert(destination == nil || destination is Destination, "Router (\(routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        assert(destination == nil || Registry.validateConformance(destination: destination!, inViewRouterType: routerType))
        return destination as? Destination
    }
    
    /// Synchronously get destination, and prepare the destination.
    ///
    /// - Parameter configBuilder: Build the configuration for performing route.
    ///     - config: Config for view route.
    ///     - prepareDestination: Prepare destination before performing route. It's an escaping block, use weakSelf to avoid retain cycle.
    ///     - prepareModule: Prepare custom moudle config.
    /// - Returns: Destination
    public func makeDestination(configuring configBuilder: @escaping (ViewRouteConfig, DestinationPreparation, ModulePreparation) -> Void) -> Destination? {
        let destination = routerType.makeDestination(configuring: { config in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    if let destination = d as? Destination {
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
        assert(destination == nil || destination is Destination, "Router (\(routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        assert(destination == nil || Registry.validateConformance(destination: destination!, inViewRouterType: routerType))
        return destination as? Destination
    }
    
    public func description(of state: ZIKRouterState) -> String {
        return routerType.description(of: state)
    }
}

/// Swift Wrapper for ZIKViewRouter.
public class ViewRouter<Destination, ModuleConfig> {
    
    /// The real routed ZIKViewRouter.
    public private(set) var router: ZIKAnyViewRouter
    
    internal init(router: ZIKAnyViewRouter) {
        self.router = router
    }
    
    /// State of route. Will be auto changed when view state is changed.
    public var state: ZIKRouterState {
        return router.state
    }
    
    /// Configuration for performRoute; Return copy of configuration, so modify this won't change the real configuration inside router.
    public var configuration: ViewRouteConfig {
        return router.configuration
    }
    
    /// Configuration for removeRoute; return copy of configuration, so modify this won't change the real configuration inside router.
    public var removeConfiguration: ViewRemoveConfig? {
        return router.removeConfiguration
    }
    
    /// Latest error when route action failed.
    public var error: Error? {
        return router.error
    }
    
    // MARK: Perform
    
    /// Whether the router can perform a view route now
    /// - Discusstion:
    /// Situations when return false:
    ///
    /// 1. State is routing, routed or removing
    ///
    /// 2. Source was dealloced
    ///
    /// 3. Source can't perform the route type: source is not in any navigation stack for push type, or source has presented a view controller for present type
    ///
    /// - Returns: true if source can perform route now, otherwise false
    public var canPerform: Bool {
        return router.canPerform()
    }
    
    ///Perform with success handler and error handler.
    public func performRoute(successHandler: (() -> Void)? = nil, errorHandler: ((ZIKRouteAction, Error) -> Void)? = nil) {
        router.performRoute(successHandler: successHandler, errorHandler: errorHandler)
    }
    
    // MARK: Remove
    
    /// Whether can remove a performed view route. Always use it in main thread, bacause state may be changed in main thread after you check the state in child thread.
    /// -Discussion:
    /// Situations when return false:
    ///
    /// 1. Router is not performed yet.
    ///
    /// 2. Destination was already poped/dismissed/removed/dealloced.
    ///
    /// 3. Use ZIKViewRouteTypeCustom and the router didn't provide removeRoute, or canRemoveCustomRoute return false.
    ///
    /// 4. If route type is adaptative type, it will choose different presentation for different situation (ZIKViewRouteTypePerformSegue, ZIKViewRouteTypeShow, ZIKViewRouteTypeShowDetail). Then if it's real route type is not Push/PresentModally/PresentAsPopover/AddAsChildViewController, destination can't be removed.
    ///
    /// 5. Router was auto created when a destination is displayed and not from storyboard, so router don't know destination's state before route, and can't analyze it's real route type to do corresponding remove action.
    ///
    /// 6. Destination's route type is complicated and is considered as custom route type. Such as destination is added to a UITabBarController, then added to a UINavigationController, and finally presented modally. We don't know the remove action should do dismiss or pop or remove from it's UITabBarController.
    ///
    /// - Note: Router should be removed be the performer, but not inside the destination. Only the performer knows how the destination was displayed (situation 6).
    ///
    /// - Returns: return true if can do removeRoute.
    public var canRemove: Bool {
        return router.canRemove()
    }
    
    /// Remove a routed destination. Auto choose proper remove action in pop/dismiss/removeFromParentViewController/removeFromSuperview/custom. If canRemove return false, this will failed, use removeRouteWithSuccessHandler:errorHandler: to get error info. Main thread only.
    public func removeRoute(successHandler performerSuccessHandler: (() -> Void)? = nil, errorHandler performerErrorHandler: ((ZIKRouteAction, Error) -> Void)? = nil) {
        router.removeRoute(successHandler: performerSuccessHandler, errorHandler: performerErrorHandler)
    }
    
    public typealias DestinationPreparation = (@escaping (Destination) -> Void) -> Void
    
    /// Remove route and prepare before removing. Auto choose proper remove action in pop/dismiss/removeFromParentViewController/removeFromSuperview/custom. If canRemove return false, this will failed, use removeRouteWithSuccessHandler:errorHandler: to get error info. Main thread only.
    ///
    /// - Parameter configBuilder: Configure the configuration for removing view.
    ///     - config: Config for removing view route.
    ///     - prepareDestination: Prepare destination before removing route. It's an escaping block, use weakSelf to avoid retain cycle.
    public func removeRoute(configuring configBuilder: @escaping (ViewRemoveConfig, DestinationPreparation) -> Void) {
        let removeBuilder = { (config: ViewRemoveConfig) in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    if let destination = d as? Destination {
                        prepare(destination)
                    }
                }
            }
            configBuilder(config, prepareDestination)
        }
        router.removeRoute(configuring: removeBuilder)
    }
}
