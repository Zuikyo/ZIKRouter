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
public class ViewRouter<Destination, ModuleConfig> {
    
    /// The router type to wrap.
    public let routerType: ZIKAnyViewRouter.Type
    
    /// The routed ZIKViewRouter.
    public private(set) var routed: ZIKAnyViewRouter?
    
    internal init(routerType: ZIKAnyViewRouter.Type) {
        self.routerType = routerType
    }
    
    /// State of route. Will be auto changed when view state is changed.
    public var state: ZIKRouterState {
        return routed?.state ?? ZIKRouterState.notRoute
    }
    
    /// Configuration for performRoute; Return copy of configuration, so modify this won't change the real configuration inside router.
    public var configuration: ViewRouteConfig {
        return routed?.configuration ?? routerType.defaultRouteConfiguration()
    }
    
    /// Configuration for removeRoute; return copy of configuration, so modify this won't change the real configuration inside router.
    public var removeConfiguration: ViewRemoveConfig? {
        return routed?.removeConfiguration
    }
    
    /// Latest error when route action failed.
    public var error: Error? {
        return routed?.error
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
        return routed?.canPerform() ?? true
    }
    
    public typealias DestinationPreparation = (@escaping (Destination) -> Void) -> Void
    public typealias ModulePreparation = ((ModuleConfig) -> Void) -> Void
    
    /// Perform route from source view to destination view, and config the remove route.
    ///
    /// - Parameters:
    ///   - source: Source UIViewController or UIView. See ViewRouteConfig's source.
    ///   - configBuilder: Build the configuration for performing route.
    ///     - config: Config for view route.
    ///     - prepareDestination: Prepare destination before performing route.
    ///     - prepareModule: Prepare custom moudle config.
    ///   - removeConfigBuilder: Configure the configuration for removing view.
    ///     - config: Config for removing view route.
    ///     - prepareDestination: Prepare destination before removing route.
    public func perform(from source: ZIKViewRouteSource?, configuring configBuilder: (ViewRouteConfig, DestinationPreparation, ModulePreparation) -> Void, removing removeConfigBuilder: ((ViewRemoveConfig, DestinationPreparation) -> Void)? = nil) {
        var removeBuilder: ((ViewRemoveConfig) -> Void)? = nil
        if let configBuilder = removeConfigBuilder {
            removeBuilder = { (config: ViewRemoveConfig) in
                let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                    config.prepareDestination = { d in
                        if let destination = d as? Destination {
                            prepare(destination)
                        }
                    }
                }
                configBuilder(config, prepareDestination)
            }
        }
        let routerType = self.routerType
        routed = routerType.perform(from: source, configuring: { config in
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
    }
    
    /// If this destination doesn't need any variable to initialize, just pass source and perform route.
    ///
    /// - Parameters:
    ///   - source: Source UIViewController or UIView. See ViewRouteConfig's source.
    ///   - routeType: The style of route.
    public func perform(from source: ZIKViewRouteSource?, routeType: ViewRouteType) {
        perform(from: source, configuring: { (config, _, _) in
            config.routeType = routeType
        })
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
        return routed?.canRemove() ?? false
    }
    
    /// Remove a routed destination. Auto choose proper remove action in pop/dismiss/removeFromParentViewController/removeFromSuperview/custom. If canRemove return false, this will failed, use removeRouteWithSuccessHandler:errorHandler: to get error info. Main thread only.
    public func removeRoute(successHandler performerSuccessHandler: (() -> Void)? = nil, errorHandler performerErrorHandler: ((ZIKRouteAction, Error) -> Void)? = nil) {
        routed?.removeRoute(successHandler: performerSuccessHandler, errorHandler: performerErrorHandler)
    }
    
    /// Remove route and prepare before removing. Auto choose proper remove action in pop/dismiss/removeFromParentViewController/removeFromSuperview/custom. If canRemove return false, this will failed, use removeRouteWithSuccessHandler:errorHandler: to get error info. Main thread only.
    ///
    /// - Parameter configBuilder: Configure the configuration for removing view.
    ///     - config: Config for removing view route.
    ///     - prepareDestination: Prepare destination before removing route.
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
        routed?.removeRoute(configuring: removeBuilder)
    }
    
    // MARK: Make Destination
    
    /// Whether the destination is instantiated synchronously.
    public var makeDestinationSynchronously: Bool {
        return routerType.makeDestinationSynchronously()
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
    
    /// Synchronously get destination, and prepare the destination with destination protocol.
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
    ///     - prepareDestination: Prepare destination before performing route.
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
