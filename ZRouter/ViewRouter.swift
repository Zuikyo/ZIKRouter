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

/// Swift Wrapper of ZIKViewRouter class for supporting pure Swift generic type.
public class ViewRouterType<Destination, ModuleConfig> {
    
    /// The router type to wrap.
    public let routerType: ZIKAnyViewRouterType
    
    internal init(routerType: ZIKAnyViewRouterType) {
        self.routerType = routerType
    }
    
    // MARK: Perform
    
    public typealias DestinationPreparation = (@escaping (Destination) -> Void) -> Void
    public typealias ModulePreparation = ((ModuleConfig) -> Void) -> Void
    
    /// Perform route from source view to destination view, and config the remove route.
    ///
    /// - Parameters:
    ///   - path: The path with source and route type.
    ///   - configBuilder: Build the configuration for performing route.
    ///     - config: Config for view route.
    ///     - prepareDestination: Prepare destination before performing route. It's an escaping block, use weakSelf to avoid retain cycle.
    ///     - prepareModule: Prepare custom module config.
    ///   - removeConfigBuilder: Configure the configuration for removing view.
    ///     - config: Config for removing view route.
    ///     - prepareDestination: Prepare destination before removing route. It's an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The view router for this route.
    @discardableResult public func perform(
        path: ViewRoutePath,
        configuring configBuilder: (ViewRouteConfig, DestinationPreparation, ModulePreparation) -> Void,
        removing removeConfigBuilder: ((ViewRemoveConfig, DestinationPreparation) -> Void)? = nil
        ) -> ViewRouter<Destination, ModuleConfig>? {
        var removeBuilder: ((ViewRemoveConfig) -> Void)? = nil
        if let removeConfigBuilder = removeConfigBuilder {
            removeBuilder = { (config: ViewRemoveConfig) in
                let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                    config.prepareDestination = { d in
                        guard let destination = d as? Destination else {
                            assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                            return
                        }
                        prepare(destination)
                    }
                }
                removeConfigBuilder(config, prepareDestination)
            }
        }
        let routerType = self.routerType
        let router = routerType.perform(path.path, configuring: { config in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    guard let destination = d as? Destination else {
                        assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                        return
                    }
                    prepare(destination)
                }
            }
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                guard let moduleConfig = config as? ModuleConfig else {
                    assertionFailure("Bad implementation in router, configuration (\(config)) should be type (\(ModuleConfig.self))")
                    return
                }
                prepare(moduleConfig)
            }
            configBuilder(config, prepareDestination, prepareModule)
            if shouldCheckServiceRouter {
                let successHandler = config.successHandler
                config.successHandler = { d in
                    successHandler?(d)
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
    ///   - path: The path with source and route type.
    /// - Returns: The view router for this route.
    @discardableResult public func perform(path: ViewRoutePath) -> ViewRouter<Destination, ModuleConfig>? {
        return perform(path: path, configuring: { (_, _, _) in
            
        }, removing: nil)
    }
    
    /// If this route action doesn't need any arguments, perform directly with successHandler and errorHandler for current performing.
    @discardableResult public func perform(
        path: ViewRoutePath,
        successHandler performerSuccessHandler: ((Destination) -> Void)? = nil,
        errorHandler performerErrorHandler: ((ZIKRouteAction, Error) -> Void)? = nil
        ) -> ViewRouter<Destination, ModuleConfig>? {
        return perform(path: path, configuring: { (config, _, _) in
            if let performerSuccessHandler = performerSuccessHandler {
                let successHandler = config.performerSuccessHandler
                config.performerSuccessHandler = { d in
                    guard let destination  = d as? Destination else {
                        assertionFailure("Bad implementation in router, destination (\(String(describing: d))) should be type (\(Destination.self))")
                        return
                    }
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
    
    /// If this destination doesn't need any variable to initialize, just pass source and perform route with completion.
    ///
    /// - Parameters:
    ///   - path: The route path with source and route type.
    ///   - completion: Completion for current performing.
    /// - Returns: The view router for this route.
    @discardableResult public func perform(
        path: ViewRoutePath,
        completion performerCompletion: @escaping (Bool, Destination?, ZIKRouteAction, Error?) -> Void
        ) -> ViewRouter<Destination, ModuleConfig>? {
        return perform(path: path, successHandler: { (destination) in
            performerCompletion(true, destination, .performRoute, nil);
        }, errorHandler: { (action, error) in
            performerCompletion(false, nil, action, error);
        })
    }
    
    // MARK: Perform on Destination
    
    /// Perform route on destination. If you get a prepared destination by ZIKViewRouteTypeMakeDestination, you can use this method to perform route on the destination.
    ///
    /// - Parameters:
    ///   - destination: The destination to perform route, the destination class should be registered with this router class.
    ///   - path: The route path with source and route type.
    ///   - configBuilder: Builder for config when perform route.
    ///   - removeConfigBuilder: Builder for config when remove route.
    /// - Returns: The view router for this route.
    @discardableResult public func perform(
        onDestination destination: Destination,
        path: ViewRoutePath,
        configuring configBuilder: (ViewRouteConfig, DestinationPreparation, ModulePreparation) -> Void,
        removing removeConfigBuilder: ((ViewRemoveConfig, DestinationPreparation) -> Void)? = nil
        ) -> ViewRouter<Destination, ModuleConfig>? {
        var removeBuilder: ((ViewRemoveConfig) -> Void)? = nil
        if let removeConfigBuilder = removeConfigBuilder {
            removeBuilder = { (config: ViewRemoveConfig) in
                let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                    config.prepareDestination = { d in
                        guard let destination = d as? Destination else {
                            assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                            return
                        }
                        prepare(destination)
                    }
                }
                removeConfigBuilder(config, prepareDestination)
            }
        }
        guard let dest = destination as? ZIKRoutableView else {
            ZIKAnyViewRouter.notifyGlobalError(with: nil, action: .init, error: ZIKAnyViewRouter.routeError(withCode: .invalidConfiguration, localizedDescription: "Perform route on invalid destination: \(destination)"))
            return nil
        }
        let router = routerType.perform(onDestination: dest, path: path.path, configuring: { (config) in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    guard let destination = d as? Destination else {
                        assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                        return
                    }
                    prepare(destination)
                }
            }
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                guard let moduleConfig = config as? ModuleConfig else {
                    assertionFailure("Bad implementation in router, configuration (\(config)) should be type (\(ModuleConfig.self))")
                    return
                }
                prepare(moduleConfig)
            }
            configBuilder(config, prepareDestination, prepareModule)
        }, removing: removeBuilder)
        
        guard let routed = router else {
            return nil
        }
        assert(Registry.validateConformance(destination: dest, inViewRouterType: routerType))
        return ViewRouter<Destination, ModuleConfig>(router: routed)
    }
    
    /// Perform route on destination with route type. If you get a prepared destination by ZIKViewRouteTypeMakeDestination, you can use this method to perform route on the destination.
    ///
    /// - Parameters:
    ///   - destination: The destination to perform route, the destination class should be registered with this router class.
    ///   - path: The route path with source and route type.
    ///   - routeType: Route type to perform.
    /// - Returns: The view router for this route. If the destination is not registered with this router class, return nil.
    @discardableResult public func perform(
        onDestination destination: Destination,
        path: ViewRoutePath) -> ViewRouter<Destination, ModuleConfig>? {
        return perform(onDestination: destination, path: path, configuring: { (config, _, _) in
            
        })
    }
    
    // MARK: Prepare Destination
    
    /// Prepare destination from external, then you can use the router to perform route. You can also use this as a builder to prepare view created from external.
    ///
    /// - Parameters:
    ///   - destination: The destination to prepare. Destination must be registered with this router class.
    ///   - configBuilder: Builder for config when perform route.
    ///   - removeConfigBuilder: Builder for config when remove route.
    /// - Returns: The view router for this route. If the destination is not registered with this router class, return nil.
    @discardableResult public func prepare(
        destination: Destination,
        configuring configBuilder: (ViewRouteConfig, DestinationPreparation, ModulePreparation) -> Void,
        removing removeConfigBuilder: ((ViewRemoveConfig, DestinationPreparation) -> Void)? = nil
        ) -> ViewRouter<Destination, ModuleConfig>? {
        var removeBuilder: ((ViewRemoveConfig) -> Void)? = nil
        if let removeConfigBuilder = removeConfigBuilder {
            removeBuilder = { (config: ViewRemoveConfig) in
                let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                    config.prepareDestination = { d in
                        guard let destination = d as? Destination else {
                            assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                            return
                        }
                        prepare(destination)
                    }
                }
                removeConfigBuilder(config, prepareDestination)
            }
        }
        guard let dest = destination as? ZIKRoutableView else {
            ZIKAnyViewRouter.notifyGlobalError(with: nil, action: .init, error: ZIKAnyViewRouter.routeError(withCode: .invalidConfiguration, localizedDescription: "Perform route on invalid destination: \(destination)"))
            return nil
        }
        let router = routerType.prepareDestination(dest, configuring: { (config) in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    guard let destination = d as? Destination else {
                        assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                        return
                    }
                    prepare(destination)
                }
            }
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                guard let moduleConfig = config as? ModuleConfig else {
                    assertionFailure("Bad implementation in router, configuration (\(config)) should be type (\(ModuleConfig.self))")
                    return
                }
                prepare(moduleConfig)
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
            guard let destination = d as? Destination else {
                assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                return
            }
            prepare?(destination)
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
    ///     - prepareModule: Prepare custom module config.
    /// - Returns: Destination
    public func makeDestination(configuring configBuilder: (ViewRouteConfig, DestinationPreparation, ModulePreparation) -> Void) -> Destination? {
        let destination = routerType.makeDestination(configuring: { config in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    guard let destination = d as? Destination else {
                        assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                        return
                    }
                    prepare(destination)
                }
            }
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                guard let moduleConfig = config as? ModuleConfig else {
                    assertionFailure("Bad implementation in router, configuration (\(config)) should be type (\(ModuleConfig.self))")
                    return
                }
                prepare(moduleConfig)
            }
            configBuilder(config, prepareDestination, prepareModule)
        })
        assert(destination == nil || destination is Destination, "Router (\(routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        assert(destination == nil || Registry.validateConformance(destination: destination!, inViewRouterType: routerType))
        return destination as? Destination
    }
}

/// Swift Wrapper of ZIKViewRouter for supporting pure Swift generic type.
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
    
    /// If this route action doesn't need any arguments, perform directly with successHandler and errorHandler for current performing.
    public func performRoute(successHandler performerSuccessHandler: ((Destination) -> Void)? = nil, errorHandler performerErrorHandler: ((ZIKRouteAction, Error) -> Void)? = nil) {
        router.performRoute(successHandler: { (d) in
            guard let destination = d as? Destination else {
                assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                return
            }
            performerSuccessHandler?(destination)
        }, errorHandler: performerErrorHandler)
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
    
    ///Whether the router should be removed before another performing, when the router is performed already and the destination still exists.
    public var shouldRemoveBeforePerform: Bool {
        return router.shouldRemoveBeforePerform()
    }
    
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
    
    /// Remove route with completion for current removing.
    public func removeRoute(completion performerCompletion: @escaping (Bool, ZIKRouteAction, Error?) -> Void) {
        removeRoute(successHandler: {
            performerCompletion(true, .removeRoute, nil)
        }, errorHandler: { (action, error) in
            performerCompletion(false, action, error)
        })
    }
    
    public typealias DestinationPreparation = (@escaping (Destination) -> Void) -> Void
    
    /// Remove route and prepare before removing. Auto choose proper remove action in pop/dismiss/removeFromParentViewController/removeFromSuperview/custom. If canRemove return false, this will failed, use removeRouteWithSuccessHandler:errorHandler: to get error info. Main thread only.
    ///
    /// - Parameter configBuilder: Configure the configuration for removing view.
    ///     - config: Config for removing view route.
    ///     - prepareDestination: Prepare destination before removing route. It's an escaping block, use weakSelf to avoid retain cycle.
    public func removeRoute(configuring configBuilder: (ViewRemoveConfig, DestinationPreparation) -> Void) {
        router.removeRoute(configuring: { (config) in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    guard let destination = d as? Destination else {
                        assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                        return
                    }
                    prepare(destination)
                }
            }
            configBuilder(config, prepareDestination)
        })
    }
}

/// Route path for setting route type and those required parameters for each type. You can extend your custom transition type in ZIKViewRoutePath, and use custom default configuration in router, override -configurePath: and set custom parameters to configuration.
public enum ViewRoutePath {
    /// Push the destination from the source view controller.
    case push(from: UIViewController)
    /// Present the destination modally from the source view controller.
    case presentModally(from: UIViewController)
    /// Present the destination as popover from the source view controller, and configure the popover.
    case presentAsPopover(from: UIViewController, configure: ZIKViewRoutePopoverConfigure)
    /// Perform segue from the source view controller, with the segue identifier
    case performSegue(from: UIViewController, identifier: String, sender: Any?)
    /// Show the destination from the source view controller.
    case show(from: UIViewController)
    /// Show the destination as detail from the source view controller.
    case showDetail(from: UIViewController)
    /// Add the destination as child view controller to the parent source view controller.
    case addAsChildViewController(from: UIViewController)
    /// Add the destination as subview to the superview.
    case addAsSubview(from: UIView)
    /// Perform custom transition type from the source.
    case custom(from: ZIKViewRouteSource?)
    /// Just make destination.
    case makeDestination
    /// Only use this when using custom transition type extended in ZIKViewRoutePath
    case extensible(path: ZIKViewRoutePath)
    
    public var source: ZIKViewRouteSource? {
        let source: ZIKViewRouteSource?
        switch self {
        case .push(from: let s),
             .presentModally(from: let s),
             .presentAsPopover(from: let s, _),
             .performSegue(from: let s, _, _),
             .show(from: let s),
             .showDetail(from: let s),
             .addAsChildViewController(from: let s):
            source = s
        case .addAsSubview(from: let s):
            source = s
        case .custom(from: let s):
            source = s
        case .makeDestination:
            source = nil
        case .extensible(path: let p):
            source = p.source
        }
        return source
    }
    
    public var routeType: ZIKViewRouteType {
        switch self {
        case .push(from: _):
            return .push
        case .presentModally(from: _):
            return .presentModally
        case .presentAsPopover(from: _):
            return .presentAsPopover
        case .performSegue(from: _):
            return .performSegue
        case .show(from: _):
            return .show
        case .showDetail(from: _):
            return .showDetail
        case .addAsChildViewController(from: _):
            return .addAsChildViewController
        case .addAsSubview(from: _):
            return .addAsSubview
        case .custom(from: _):
            return .custom
        case .makeDestination:
            return .makeDestination
        case .extensible(let path):
            return path.routeType
        }
    }
    
    public var path: ZIKViewRoutePath {
        switch self {
        case .presentAsPopover(from: let source, configure: let configure):
            return ZIKViewRoutePath.presentAsPopover(from: source, configure: configure)
        case .performSegue(from: let source, let identifier, let sender):
            return ZIKViewRoutePath.performSegue(from: source, identifier: identifier, sender: sender)
        case .extensible(path: let path):
            return path
        default:
            return ZIKViewRoutePath(routeType: routeType, source: source)
        }
    }
    
    public init?(path: ZIKViewRoutePath) {
        switch (path.routeType, path.source) {
        case (.push, let source as UIViewController):
            self = .push(from: source)
        case (.presentModally, let source as UIViewController):
            self = .presentModally(from: source)
        case (.presentAsPopover, let source as UIViewController):
            if let configure = path.configurePopover {
                self = .presentAsPopover(from: source, configure: configure)
            } else {
                return nil
            }
        case (.performSegue, let source as UIViewController):
            if let identifier = path.segueIdentifier {
                self = .performSegue(from: source, identifier: identifier, sender: path.segueSender)
            } else {
                return nil
            }
        case (.show, let source as UIViewController):
            self = .show(from: source)
        case (.showDetail, let source as UIViewController):
            self = .showDetail(from: source)
        case (.addAsChildViewController, let source as UIViewController):
            self = .addAsChildViewController(from: source)
        case (.addAsSubview, let source as UIView):
            self = .addAsSubview(from: source)
        case (.custom, let source):
            self = .custom(from: source)
        case (.makeDestination, _):
            self = .makeDestination
        default:
            return nil
        }
    }
}

// MARK: Deprecated

public extension ViewRouterType {
    @available(iOS, deprecated: 8.0, message: "Use perform(path:configuring:removing:) instead")
    @discardableResult public func perform(
        from source: ZIKViewRouteSource?,
        configuring configBuilder: (ViewRouteConfig, DestinationPreparation, ModulePreparation) -> Void,
        removing removeConfigBuilder: ((ViewRemoveConfig, DestinationPreparation) -> Void)? = nil
        ) -> ViewRouter<Destination, ModuleConfig>?{
        var removeBuilder: ((ViewRemoveConfig) -> Void)? = nil
        if let removeConfigBuilder = removeConfigBuilder {
            removeBuilder = { (config: ViewRemoveConfig) in
                let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                    config.prepareDestination = { d in
                        guard let destination = d as? Destination else {
                            assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                            return
                        }
                        prepare(destination)
                    }
                }
                removeConfigBuilder(config, prepareDestination)
            }
        }
        let routerType = self.routerType
        let router = routerType.perform(from: source, configuring: { config in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    guard let destination = d as? Destination else {
                        assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                        return
                    }
                    prepare(destination)
                }
            }
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                guard let moduleConfig = config as? ModuleConfig else {
                    assertionFailure("Bad implementation in router, configuration (\(config)) should be type (\(ModuleConfig.self))")
                    return
                }
                prepare(moduleConfig)
            }
            configBuilder(config, prepareDestination, prepareModule)
            if shouldCheckServiceRouter {
                let successHandler = config.successHandler
                config.successHandler = { d in
                    successHandler?(d)
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
    
    @available(iOS, deprecated: 8.0, message: "Use perform(path:) instead")
    @discardableResult public func perform(
        from source: ZIKViewRouteSource?,
        routeType: ViewRouteType
        ) -> ViewRouter<Destination, ModuleConfig>? {
        return perform(from: source, configuring: { (config, _, _) in
            config.routeType = routeType
        })
    }
    
    @available(iOS, deprecated: 8.0, message: "Use perform(onDestination:path:configuring:removing:) instead")
    @discardableResult public func perform(
        onDestination destination: Destination,
        from source: ZIKViewRouteSource?,
        configuring configBuilder: (ViewRouteConfig, DestinationPreparation, ModulePreparation) -> Void,
        removing removeConfigBuilder: ((ViewRemoveConfig, DestinationPreparation) -> Void)? = nil
        ) -> ViewRouter<Destination, ModuleConfig>? {
        var removeBuilder: ((ViewRemoveConfig) -> Void)? = nil
        if let removeConfigBuilder = removeConfigBuilder {
            removeBuilder = { (config: ViewRemoveConfig) in
                let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                    config.prepareDestination = { d in
                        guard let destination = d as? Destination else {
                            assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                            return
                        }
                        prepare(destination)
                    }
                }
                removeConfigBuilder(config, prepareDestination)
            }
        }
        guard let dest = destination as? ZIKRoutableView else {
            ZIKAnyViewRouter.notifyGlobalError(with: nil, action: .init, error: ZIKAnyViewRouter.routeError(withCode: .invalidConfiguration, localizedDescription: "Perform route on invalid destination: \(destination)"))
            return nil
        }
        let router = routerType.perform(onDestination: dest, from: source, configuring: { (config) in
            let prepareDestination = { (prepare: @escaping (Destination) -> Void) in
                config.prepareDestination = { d in
                    guard let destination = d as? Destination else {
                        assertionFailure("Bad implementation in router, destination (\(d)) should be type (\(Destination.self))")
                        return
                    }
                    prepare(destination)
                }
            }
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                guard let moduleConfig = config as? ModuleConfig else {
                    assertionFailure("Bad implementation in router, configuration (\(config)) should be type (\(ModuleConfig.self))")
                    return
                }
                prepare(moduleConfig)
            }
            configBuilder(config, prepareDestination, prepareModule)
        }, removing: removeBuilder)
        
        guard let routed = router else {
            return nil
        }
        assert(Registry.validateConformance(destination: dest, inViewRouterType: routerType))
        return ViewRouter<Destination, ModuleConfig>(router: routed)
    }
    
    @available(iOS, deprecated: 8.0, message: "Use perform(onDestination:path:) instead")
    @discardableResult public func perform(
        onDestination destination: Destination,
        from source: ZIKViewRouteSource?,
        routeType: ViewRouteType
        ) -> ViewRouter<Destination, ModuleConfig>? {
        return perform(onDestination: destination, from: source, configuring: { (config, _, _) in
            config.routeType = routeType
        })
    }
}
