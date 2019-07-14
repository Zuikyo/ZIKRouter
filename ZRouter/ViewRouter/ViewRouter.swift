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
    
    /// Default configuration to perform route.
    public var defaultRouteConfiguration: ModuleConfig {
        return routerType.defaultRouteConfiguration() as! ModuleConfig
    }
    
    /// Default configuration to remove route.
    public var defaultRemoveConfiguration: ViewRemoveConfig {
        return routerType.defaultRemoveConfiguration()
    }
    
    // MARK: Perform
    
    public typealias ModulePreparation = ((ModuleConfig) -> Void) -> Void
    
    /// Perform route from source view to destination view, and config the remove route.
    ///
    /// - Parameters:
    ///   - path: The path with source and route type.
    ///   - configBuilder: Build the configuration for performing route.
    ///     - config: Config for view route.
    ///     - prepareModule: Prepare custom module config.
    ///   - removeConfigBuilder: Configure the configuration for removing view.
    ///     - config: Config for removing view route.
    /// - Returns: The view router for this route.
    @discardableResult public func perform(
        path: ViewRoutePath,
        configuring configBuilder: (ViewRouteStrictConfig<Destination>, ModulePreparation) -> Void,
        removing removeConfigBuilder: ((ViewRemoveStrictConfig<Destination>) -> Void)? = nil
        ) -> ViewRouter<Destination, ModuleConfig>? {
        var removeBuilder: ((ZIKRemoveRouteStrictConfiguration<AnyObject>) -> Void)? = nil
        if let removeConfigBuilder = removeConfigBuilder {
            removeBuilder = { (strictConfig: ZIKRemoveRouteStrictConfiguration<AnyObject>) in
                removeConfigBuilder(ViewRemoveStrictConfig(configuration: strictConfig))
            }
        }
        let routerType = self.routerType
        let router = routerType.perform(path.path, strictConfiguring: { (strictConfig, config) in
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                guard let moduleConfig = config as? ModuleConfig else {
                    assertionFailure("Bad implementation in router, configuration (\(config)) should be type (\(ModuleConfig.self))")
                    return
                }
                prepare(moduleConfig)
            }
            configBuilder(ViewRouteStrictConfig(configuration: strictConfig), prepareModule)
            #if DEBUG
            let successHandler = config.successHandler
            config.successHandler = { d in
                successHandler?(d)
                assert(d is Destination, "Router (\(routerType)) returns wrong destination type (\(d)), destination should be \(Destination.self)")
                assert(Registry.validateConformance(destination: d, inViewRouterType: routerType))
            }
            #endif
        }, strictRemoving: removeBuilder)
        
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
        return perform(path: path, configuring: { (_, _) in
            
        }, removing: nil)
    }
    
    /// If this route action doesn't need any arguments, perform directly with successHandler and errorHandler for current performing.
    @discardableResult public func perform(
        path: ViewRoutePath,
        successHandler performerSuccessHandler: ((Destination) -> Void)? = nil,
        errorHandler performerErrorHandler: ((ZIKRouteAction, Error) -> Void)? = nil
        ) -> ViewRouter<Destination, ModuleConfig>? {
        return perform(path: path, configuring: { (config, _) in
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
    
    /// Prepare the destination with destination protocol and perform route.
    ///
    /// - Parameters:
    ///   - path: The route path with source and route type.
    ///   - preparation: Prepare the destination with destination protocol. It's an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The view router for this route.
    @discardableResult public func perform(
        path: ViewRoutePath,
        preparation prepare: @escaping ((Destination) -> Void)
        ) -> ViewRouter<Destination, ModuleConfig>? {
        return perform(path: path, configuring: { (config, _) in
            config.prepareDestination = prepare
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
        configuring configBuilder: (ViewRouteStrictConfig<Destination>, ModulePreparation) -> Void,
        removing removeConfigBuilder: ((ViewRemoveStrictConfig<Destination>) -> Void)? = nil
        ) -> ViewRouter<Destination, ModuleConfig>? {
        var removeBuilder: ((ZIKRemoveRouteStrictConfiguration<AnyObject>) -> Void)? = nil
        if let removeConfigBuilder = removeConfigBuilder {
            removeBuilder = { (strictConfig: ZIKRemoveRouteStrictConfiguration<AnyObject>) in
                removeConfigBuilder(ViewRemoveStrictConfig(configuration: strictConfig))
            }
        }
        guard let dest = destination as? ZIKRoutableView else {
            ZIKAnyViewRouter.notifyGlobalError(with: nil, action: ZIKRouteAction.`init`, error: ZIKAnyViewRouter.routeError(withCode: .invalidConfiguration, localizedDescription: "Perform route on invalid destination: \(destination)"))
            return nil
        }
        let router = routerType.perform(onDestination: dest, path: path.path, strictConfiguring: { (strictConfig, config) in
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                guard let moduleConfig = config as? ModuleConfig else {
                    assertionFailure("Bad implementation in router, configuration (\(config)) should be type (\(ModuleConfig.self))")
                    return
                }
                prepare(moduleConfig)
            }
            configBuilder(ViewRouteStrictConfig(configuration: strictConfig), prepareModule)
        }, strictRemoving: removeBuilder)
        
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
        return perform(onDestination: destination, path: path, configuring: { (config, _) in
            
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
        configuring configBuilder: (ViewRouteStrictConfig<Destination>, ModulePreparation) -> Void,
        removing removeConfigBuilder: ((ViewRemoveStrictConfig<Destination>) -> Void)? = nil
        ) -> ViewRouter<Destination, ModuleConfig>? {
        var removeBuilder: ((ZIKRemoveRouteStrictConfiguration<AnyObject>) -> Void)? = nil
        if let removeConfigBuilder = removeConfigBuilder {
            removeBuilder = { (strictConfig: ZIKRemoveRouteStrictConfiguration<AnyObject>) in
                removeConfigBuilder(ViewRemoveStrictConfig(configuration: strictConfig))
            }
        }
        guard let dest = destination as? ZIKRoutableView else {
            ZIKAnyViewRouter.notifyGlobalError(with: nil, action: ZIKRouteAction.`init`, error: ZIKAnyViewRouter.routeError(withCode: .invalidConfiguration, localizedDescription: "Perform route on invalid destination: \(destination)"))
            return nil
        }
        let router = routerType.prepareDestination(dest, strictConfiguring: { (strictConfig, config) in
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                guard let moduleConfig = config as? ModuleConfig else {
                    assertionFailure("Bad implementation in router, configuration (\(config)) should be type (\(ModuleConfig.self))")
                    return
                }
                prepare(moduleConfig)
            }
            configBuilder(ViewRouteStrictConfig(configuration: strictConfig), prepareModule)
        }, strictRemoving: removeBuilder)
        
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
        if let destination = destination {
            return destination as? Destination
        }
        return nil
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
        if let destination = destination {
            return destination as? Destination
        }
        return nil
    }
    
    /// Synchronously get destination, and prepare the destination.
    ///
    /// - Parameter configBuilder: Build the configuration for performing route.
    ///     - config: Config for view route.
    ///     - prepareModule: Prepare custom module config.
    /// - Returns: Destination
    public func makeDestination(configuring configBuilder: (ViewRouteStrictConfig<Destination>, ModulePreparation) -> Void) -> Destination? {
        let destination = routerType.makeDestination(strictConfiguring: { (strictConfig, config) in
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                guard let moduleConfig = config as? ModuleConfig else {
                    assertionFailure("Bad implementation in router, configuration (\(config)) should be type (\(ModuleConfig.self))")
                    return
                }
                prepare(moduleConfig)
            }
            configBuilder(ViewRouteStrictConfig(configuration: strictConfig), prepareModule)
        })
        assert(destination == nil || destination is Destination, "Router (\(routerType)) returns wrong destination type (\(String(describing: destination))), destination should be \(Destination.self)")
        assert(destination == nil || Registry.validateConformance(destination: destination!, inViewRouterType: routerType))
        if let destination = destination {
            return destination as? Destination
        }
        return nil
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
    
    /// Configuration for performRoute.
    public var configuration: ViewRouteConfig {
        return router.configuration
    }
    
    /// Configuration for module protocol.
    public var config: ModuleConfig {
        return router.configuration as! ModuleConfig
    }
    
    /// Configuration for removeRoute.
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
    
    /// Whether the router should be removed before another performing, when the router is performed already and the destination still exists.
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
    /// 4. If route type is adaptative type, it will choose different presentation for different situation (ZIKViewRouteTypePerformSegue, ZIKViewRouteTypeShow, ZIKViewRouteTypeShowDetail). Then if its real route type is not Push/PresentModally/PresentAsPopover/AddAsChildViewController, destination can't be removed.
    ///
    /// 5. Router was auto created when a destination is displayed and not from storyboard, so router don't know destination's state before route, and can't analyze its real route type to do corresponding remove action.
    ///
    /// 6. Destination's route type is complicated and is considered as custom route type. Such as destination is added to an UITabBarController, then added to an UINavigationController, and finally presented modally. We don't know the remove action should do dismiss or pop or remove from its UITabBarController.
    ///
    /// - Note: Router should be removed be the performer, but not inside the destination. Only the performer knows how the destination was displayed (situation 6).
    ///
    /// - Returns: return true if can do removeRoute.
    public var canRemove: Bool {
        return router.canRemove()
    }
    
    /// Remove a routed destination. Auto choose proper remove action in pop/dismiss/removeFromParentViewController/removeFromSuperview/custom. If canRemove return false, this will fail, use removeRouteWithSuccessHandler:errorHandler: to get error info. Main thread only.
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
    
    /// Remove route and prepare before removing. Auto choose proper remove action in pop/dismiss/removeFromParentViewController/removeFromSuperview/custom. If canRemove return false, this will fail, use removeRouteWithSuccessHandler:errorHandler: to get error info. Main thread only.
    ///
    /// - Parameter configBuilder: Configure the configuration for removing view.
    ///     - config: Config for removing view route.
    public func removeRoute(configuring configBuilder: (ViewRemoveStrictConfig<Destination>) -> Void) {
        router.removeRoute(strictConfiguring: { (strictConfig) in
            configBuilder(ViewRemoveStrictConfig(configuration: strictConfig))
        })
    }
}

/// Route path for setting route type and those required parameters for each type. You can extend your custom transition type in ZIKViewRoutePath, and use custom default configuration in router, override -configurePath: and set custom parameters to configuration.
public enum ViewRoutePath {
#if os(iOS) || os(watchOS) || os(tvOS)
    /// Push the destination from the source view controller.
    case push(from: ViewController)
#endif
    /// Present the destination modally from the source view controller.
    case presentModally(from: ViewController)
    /// Present the destination as popover from the source view controller, and configure the popover.
    case presentAsPopover(from: ViewController, configure: ZIKViewRoutePopoverConfigure)
#if os(OSX)
    /// Present the destination as sheet from the source view controller.
    case presentAsSheet(from: ViewController)
    /// Present the destination with animator from the source view controller.
    case present(from: ViewController, animator: NSViewControllerPresentationAnimator)
#endif
    /// Perform segue from the source view controller, with the segue identifier
    case performSegue(from: ViewController, identifier: String, sender: Any?)
#if os(iOS) || os(watchOS) || os(tvOS)
    /// Show the destination from the source view controller.
    case show(from: ViewController)
    /// Show the destination as detail from the source view controller.
    case showDetail(from: ViewController)
#elseif os(OSX)
    /// Show the destination with `NSWindowController.showWindow(_ sender: Any?)`.
    case show
#endif
    /// Add the destination as child view controller to the parent source view controller. Adding destination's view to source's view in addingChildViewHandler, and invoke the completion block when finished.
    ///
    /// - addingChildViewHandler: Add destination's view to source's view.
    ///     - destination: The destination view controller. If you wrap destination with -containerWrapper, the `destination` in this block is the wrapped ViewController.
    ///     - completion: Invoke the completion block when adding is finished.
    ///
    /// - Note: Use weak self in addingChildViewHandler to avoid retain cycle.
    case addAsChildViewController(from: ViewController, addingChildViewHandler: (_ destination: ViewController, _ completion: @escaping () -> Void) -> Void)
    /// Add the destination as subview to the superview.
    case addAsSubview(from: View)
    /// Perform custom transition type from the source.
    case custom(from: ZIKViewRouteSource?)
    /// Use default setting of ZIKViewRouteConfiguration if you don't know which type to use.
    case defaultPath(from: ViewController)
    /// Just make destination.
    case makeDestination
    /// Only use this when using custom transition type extended in ZIKViewRoutePath
    case extensible(path: ZIKViewRoutePath)
    
    public var source: ZIKViewRouteSource? {
        let source: ZIKViewRouteSource?
        switch self {
#if os(iOS) || os(watchOS) || os(tvOS)
        case .push(from: let s),
             .show(from: let s),
             .showDetail(from: let s):
            source = s
#endif
#if os(OSX)
        case .presentAsSheet(from: let s),
             .present(from: let s, animator: _):
            source = s
        case .show:
            source = nil
#endif
        case .presentModally(from: let s),
             .presentAsPopover(from: let s, _),
             .performSegue(from: let s, _, _),
             .addAsChildViewController(from: let s, _),
             .defaultPath(from: let s):
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
#if os(iOS) || os(watchOS) || os(tvOS)
        case .push(from: _):
            return .push
#endif
        case .presentModally(from: _):
            return .presentModally
        case .presentAsPopover(from: _):
            return .presentAsPopover
#if os(OSX)
        case .presentAsSheet(from: _):
            return .presentAsSheet
        case .present(from: _, animator: _):
            return .presentWithAnimator
#endif
        case .performSegue(from: _):
            return .performSegue
        case .show:
            return .show
#if os(iOS) || os(watchOS) || os(tvOS)
        case .showDetail(from: _):
            return .showDetail
#endif
        case .addAsChildViewController(from: _):
            return .addAsChildViewController
        case .addAsSubview(from: _):
            return .addAsSubview
        case .custom(from: _):
            return .custom
        case .defaultPath(from: _):
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
#if os(OSX)
        case .present(from: let source, animator: let animator):
            return ZIKViewRoutePath.present(from: source, animator: animator)
#endif
        case .performSegue(from: let source, let identifier, let sender):
            return ZIKViewRoutePath.performSegue(from: source, identifier: identifier, sender: sender)
        case .addAsChildViewController(from: let source, addingChildViewHandler: let handler):
            return ZIKViewRoutePath.addAsChildViewController(from: source, addingChildViewHandler: handler)
        case .extensible(path: let path):
            return path
        case .defaultPath(from: let source):
            let path = ZIKViewRoutePath(routeType: routeType, source: source)
            path.useDefault = true
            return path
        default:
            return ZIKViewRoutePath(routeType: routeType, source: source)
        }
    }
    
    public init?(path: ZIKViewRoutePath) {
        switch (path.routeType, path.source) {
#if os(iOS) || os(watchOS) || os(tvOS)
        case (.push, let source as ViewController):
            self = .push(from: source)
#endif
        case (.presentModally, let source as ViewController):
            self = .presentModally(from: source)
        case (.presentAsPopover, let source as ViewController):
            if let configure = path.configurePopover {
                self = .presentAsPopover(from: source, configure: configure)
            } else {
                return nil
            }
#if os(OSX)
        case (.presentAsSheet, let source as ViewController):
            self = .presentAsSheet(from: source)
        case (.presentWithAnimator, let source as ViewController):
            if let animator = path.animator {
                self = .present(from: source, animator: animator)
            } else {
                return nil
            }
#endif
        case (.performSegue, let source as ViewController):
            if let identifier = path.segueIdentifier {
                self = .performSegue(from: source, identifier: identifier, sender: path.segueSender)
            } else {
                return nil
            }
#if os(iOS) || os(watchOS) || os(tvOS)
        case (.show, let source as ViewController):
            self = .show(from: source)
        case (.showDetail, let source as ViewController):
            self = .showDetail(from: source)
#elseif os(OSX)
        case (.show, _):
            self = .show
#endif
        case (.addAsChildViewController, let source as ViewController):
            if let addingChildViewHandler = path.addingChildViewHandler {
                self = .addAsChildViewController(from: source, addingChildViewHandler: addingChildViewHandler)
            } else {
                return nil
            }
        case (.addAsSubview, let source as View):
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
    @discardableResult func perform(
        from source: ZIKViewRouteSource?,
        configuring configBuilder: (ViewRouteStrictConfig<Destination>, ModulePreparation) -> Void,
        removing removeConfigBuilder: ((ViewRemoveStrictConfig<Destination>) -> Void)? = nil
        ) -> ViewRouter<Destination, ModuleConfig>?{
        var removeBuilder: ((ZIKRemoveRouteStrictConfiguration<AnyObject>) -> Void)? = nil
        if let removeConfigBuilder = removeConfigBuilder {
            removeBuilder = { (strictConfig: ZIKRemoveRouteStrictConfiguration<AnyObject>) in
                removeConfigBuilder(ViewRemoveStrictConfig(configuration: strictConfig))
            }
        }
        let routerType = self.routerType
        let router = routerType.perform(from: source, strictConfiguring: { (strictConfig, config) in
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                guard let moduleConfig = config as? ModuleConfig else {
                    assertionFailure("Bad implementation in router, configuration (\(config)) should be type (\(ModuleConfig.self))")
                    return
                }
                prepare(moduleConfig)
            }
            configBuilder(ViewRouteStrictConfig(configuration: strictConfig), prepareModule)
            #if DEBUG
            let successHandler = config.successHandler
            config.successHandler = { d in
                successHandler?(d)
                assert(d is Destination, "Router (\(routerType)) returns wrong destination type (\(d)), destination should be \(Destination.self)")
                assert(Registry.validateConformance(destination: d, inViewRouterType: routerType))
            }
            #endif
        }, strictRemoving: removeBuilder)
        if let router = router {
            return ViewRouter<Destination, ModuleConfig>(router: router)
        } else {
            return nil
        }
    }
    
    @available(iOS, deprecated: 8.0, message: "Use perform(path:) instead")
    @discardableResult func perform(
        from source: ZIKViewRouteSource?,
        routeType: ViewRouteType
        ) -> ViewRouter<Destination, ModuleConfig>? {
        return perform(from: source, configuring: { (config, _) in
            config.routeType = routeType
        })
    }
    
    @available(iOS, deprecated: 8.0, message: "Use perform(onDestination:path:configuring:removing:) instead")
    @discardableResult func perform(
        onDestination destination: Destination,
        from source: ZIKViewRouteSource?,
        configuring configBuilder: (ViewRouteStrictConfig<Destination>, ModulePreparation) -> Void,
        removing removeConfigBuilder: ((ViewRemoveStrictConfig<Destination>) -> Void)? = nil
        ) -> ViewRouter<Destination, ModuleConfig>? {
        var removeBuilder: ((ZIKViewRemoveStrictConfiguration<AnyObject>) -> Void)? = nil
        if let removeConfigBuilder = removeConfigBuilder {
            removeBuilder = { (strictConfig: ZIKViewRemoveStrictConfiguration<AnyObject>) in
                removeConfigBuilder(ViewRemoveStrictConfig(configuration: strictConfig))
            }
        }
        guard let dest = destination as? ZIKRoutableView else {
            ZIKAnyViewRouter.notifyGlobalError(with: nil, action: ZIKRouteAction.`init`, error: ZIKAnyViewRouter.routeError(withCode: .invalidConfiguration, localizedDescription: "Perform route on invalid destination: \(destination)"))
            return nil
        }
        let router = routerType.perform(onDestination: dest, from: source, strictConfiguring: { (strictConfig, config) in
            let prepareModule = { (prepare: (ModuleConfig) -> Void) in
                guard let moduleConfig = config as? ModuleConfig else {
                    assertionFailure("Bad implementation in router, configuration (\(config)) should be type (\(ModuleConfig.self))")
                    return
                }
                prepare(moduleConfig)
            }
            configBuilder(ViewRouteStrictConfig(configuration: strictConfig), prepareModule)
        }, strictRemoving: removeBuilder)
        
        guard let routed = router else {
            return nil
        }
        assert(Registry.validateConformance(destination: dest, inViewRouterType: routerType))
        return ViewRouter<Destination, ModuleConfig>(router: routed)
    }
    
    @available(iOS, deprecated: 8.0, message: "Use perform(onDestination:path:) instead")
    @discardableResult func perform(
        onDestination destination: Destination,
        from source: ZIKViewRouteSource?,
        routeType: ViewRouteType
        ) -> ViewRouter<Destination, ModuleConfig>? {
        return perform(onDestination: destination, from: source, configuring: { (config, _) in
            config.routeType = routeType
        })
    }
}

// MARK: Makeable Config

/// Convenient configuration for using custom configuration without configuration subclass.
open class ViewMakeableConfiguration<Destination, Constructor>: ZIKSwiftViewMakeableConfiguration {
    
    /// Make destination with block.
    ///
    /// Set this in makeDestinationWith or constructDestination block. It's for passing parameters easily, so we don't need configuration subclass to hold parameters.
    ///
    /// When using configuration with `register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>, forMakingView viewClass: AnyClass, making factory: @escaping () -> Protocol)`, makeDestination is auto used for making destination.
    ///
    /// When using a router subclass with makeable configuration, the router subclass is responsible for check and use makeDestination in `-destinationWithConfiguration:`.
    public var makeDestination: (() -> Destination?)? {
        didSet {
            if self.makeDestination == nil {
                self.__makeDestination = nil
                return
            }
            self.__makeDestination = { [unowned self] () -> Any? in
                if let destination = self.makeDestination?() {
                    return destination
                }
                return nil
            }
        }
    }
    
    /**
     Factory method passing required parameters and make destination. You should set makedDestination in makeDestinationWith.
     Genetic Constructor is a factory type like: ViewMakeableConfiguration<LoginViewInput, (String) -> LoginViewInput?>
     
     If a module need a few required parameters when creating destination, you can declare makeDestinationWith in module config protocol:
     
     ```
     protocol LoginViewModuleInput {
        // Pass required parameter and return destination with LoginViewInput type.
        var makeDestinationWith: (_ account: String) -> LoginViewInput? { get }
     }
     extension RoutableViewModule where Protocol == LoginViewModuleInput {
        init() { self.init(declaredProtocol: Protocol.self) }
     }
     
     // Let ViewMakeableConfiguration conform to LoginViewModuleInput
     extension ViewMakeableConfiguration: LoginViewModuleInput where Destination == LoginViewInput, Constructor == (String) -> LoginViewInput? {
     }
     ```
     Register in some registerRoutableDestination:
     ```
     ZIKAnyViewRouter.register(RoutableViewModule<LoginViewModuleInput>(), forMakingView: LoginViewController.self) { () -> LoginViewModuleInput in
        let config = ViewMakeableConfiguration<LoginViewInput, (String) -> Void>({_,_ in })
        config.__prepareDestination = { destination in
            // Prepare the destination
        }
        // User is responsible for calling makeDestinationWith and giving parameters
        config.makeDestinationWith = { [unowned config] (account) in
            // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
            // MakeDestination will be used for creating destination instance
            config.makeDestination = { () -> LoginViewInput?
                let destination = LoginViewController(account: account)
                return destination
            }
            if let destination = config.makeDestination?() {
                config.makedDestination = destination
                return destination
            }
            return nil
        }
        return config
     }
     ```
     You can use this module with LoginViewModuleInput:
     ```
     Router.makeDestination(to: RoutableViewModule<LoginViewModuleInput>()) { (config) in
        let destination: LoginViewInput = config.makeDestinationWith("account")
     }
     ```
     Or just:
     ```
     let destination: LoginViewInput = Router.to(RoutableViewModule<LoginViewModuleInput>())?.defaultRouteConfiguration.makeDestinationWith("account")
     ```
     */
    public var makeDestinationWith: Constructor
    
    /**
     Asynchronous factory method passing required parameters for initializing destination module, and get destination in `didMakeDestination`. You should set makeDestination to capture parameters directly, so you don't need configuration subclass to hold parameters.
     Genetic Constructor is a function type: ViewMakeableConfiguration<LoginViewInput, (String) -> Void>
     
     If a module need a few required parameters when creating destination, you can declare constructDestination in module config protocol:
     
     ```
     protocol LoginViewModuleInput {
        // Pass required parameter for initializing destination.
        var constructDestination: (_ account: String) -> Void { get }
        // Designate destination is LoginViewInput.
        var didMakeDestination:((LoginViewInput) -> Void)? { get set }
     }
     extension RoutableViewModule where Protocol == LoginViewModuleInput {
        init() { self.init(declaredProtocol: Protocol.self) }
     }
     
     // Let ViewMakeableConfiguration conform to LoginViewModuleInput
     extension ViewMakeableConfiguration: LoginViewModuleInput where Destination == LoginViewInput, Constructor == (String) -> Void {
     }
     ```
     Register in some registerRoutableDestination:
     ```
     ZIKAnyViewRouter.register(RoutableViewModule<LoginViewModuleInput>(), forMakingView: LoginViewController.self) { () -> LoginViewModuleInput in
        let config = ViewMakeableConfiguration<LoginViewInput, (String) -> Void>({_,_ in })
        config.__prepareDestination = { destination in
            // Prepare the destination
        }
        // User is responsible for calling constructDestination and giving parameters
        config.constructDestination = { [unowned config] (account) in
            // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
            // MakeDestination will be used for creating destination instance
            config.makeDestination = {
                let destination = LoginViewController(account: account)
                return destination
            }
        }
        return config
     }
     ```
     You can use this module with LoginViewModuleInput:
     ```
     Router.makeDestination(to: RoutableViewModule<LoginViewModuleInput>()) { (config) in
        var config = config
        config.constructDestination("account")
        config.didMakeDestination = { destination in
            // Did get LoginViewInput
        }
     }
     ```
     */
    public var constructDestination: Constructor
    
    /// Give the destination with specfic type to the caller. This is auto called and reset to nil after `didFinishPrepareDestination:configuration:`.
    public var didMakeDestination: ((Destination) -> Void)? {
        didSet {
            if self.didMakeDestination == nil {
                self.__didMakeDestination = nil
                return
            }
            self.__didMakeDestination = { [unowned self] (d: Any) -> Void in
                if let destination = d as? Destination {
                    if let didMakeDestination = self.didMakeDestination {                        
                        self.didMakeDestination = nil
                        didMakeDestination(destination)
                    }
                } else {
                    assertionFailure("Invalid destination. Destination is not type of (\(Destination.self)): \(d)")
                }
            }
        }
    }
    
    /// Prepare the destination from the router internal before `prepareDestination(_:configuration:)`.
    ///
    /// When it's removed and routed again, this method may be called more than once. You should check whether the destination is already prepared to avoid unnecessary preparation.
    public var __prepareDestination: ((Destination) -> Void)? {
        didSet {
            if self.__prepareDestination == nil {
                self._prepareDestination = nil
                return
            }
            self._prepareDestination = { [unowned self] destination in
                if let destination = destination as? Destination {
                    self.__prepareDestination?(destination)
                }
            }
        }
    }
    
    /**
     Container to hold custom `makeDestinationWith` and `constructDestination` block. If the destination has multi custom initializers, you can add new constructor and store them in the container.
     
     ```
     protocol LoginViewModuleInput {
        var makeDestinationWith: (_ account: String) -> LoginViewInput? { get }
        var makeDestinationForNewUserWith: (_ account: String) -> LoginViewInput? { get }
     }
     
     // Let ViewMakeableConfiguration conform to LoginViewModuleInput
     extension ViewMakeableConfiguration: LoginViewModuleInput where Destination == LoginViewInput, Constructor == (String) -> LoginViewInput? {
        var makeDestinationForNewUserWith: (String) -> LoginViewInput? {
            get {
                if let block = self.constructorContainer["makeDestinationForNewUserWith"] as? (String) -> LoginViewInput? {
                    return block
                }
                return { _ in return nil }
            }
            set {
                self.constructorContainer["makeDestinationForNewUserWith"] = newValue
            }
        }
     }
     ```
     */
    public lazy var constructorContainer: [String : Any] = [:]
    
    public init(_ constructor: Constructor) {
        makeDestinationWith = constructor
        constructDestination = constructor
        super.init()
    }
}

/**
 Convenient configuration for using custom configuration without configuration subclass. Support makeDestinationWith and constructDestination at the same configuration.
 
 If a module need a few required parameters when creating destination, you can declare in module config protocol:
 
 ```
 protocol LoginViewModuleInput {
    // Pass required parameter and return destination with LoginViewInput type.
    var makeDestinationWith: (_ account: String) -> LoginViewInput? { get }
    // Pass required parameter for initializing destination.
    var constructDestination: (_ account: String) -> Void { get }
    // Designate destination is LoginViewInput.
    var didMakeDestination:((LoginViewInput) -> Void)? { get set }
 }
 extension RoutableViewModule where Protocol == LoginViewModuleInput {
    init() { self.init(declaredProtocol: Protocol.self) }
 }
 
 // Let AnyViewMakeableConfiguration conform to LoginViewModuleInput
 extension AnyViewMakeableConfiguration: LoginViewModuleInput where Destination == LoginViewInput, Maker == (String) -> LoginViewInput?, Constructor == (String) -> Void {
 }
 ```
 Register in some registerRoutableDestination:
 ```
 ZIKAnyViewRouter.register(RoutableViewModule<LoginViewModuleInput>(), forMakingView: LoginViewController.self) { () -> LoginViewModuleInput in
    let config = AnyViewMakeableConfiguration<LoginViewInput, (String) -> LoginViewInput?, (String) -> Void>({_,_ in })
    config.__prepareDestination = { destination in
        // Prepare the destination
    }
 
    // User is responsible for calling makeDestinationWith and giving parameters
    config.makeDestinationWith = { [unowned config] (account) in
        // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
        // MakeDestination will be used for creating destination instance
        config.makeDestination = { () -> LoginViewInput?
            let destination = LoginViewController(account: account)
            return destination
        }
        if let destination = config.makeDestination?() {
            config.makedDestination = destination
            return destination
        }
        return nil
    }
 
    // User is responsible for calling constructDestination and giving parameters
    config.constructDestination = { [unowned config] (account) in
        // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
        // MakeDestination will be used for creating destination instance
        config.makeDestination = {
            let destination = LoginViewController(account: account)
            return destination
        }
    }
    return config
 }
 ```
 You can use this module with LoginViewModuleInput:
 ```
 Router.makeDestination(to: RoutableViewModule<LoginViewModuleInput>()) { (config) in
    config.constructDestination("account")
    config.didMakeDestination = { destination in
        // Did get LoginViewInput
    }
 }
 ```
 Or:
 ```
 let destination: LoginViewInput = Router.to(RoutableViewModule<LoginViewModuleInput>()).defaultRouteConfiguration.makeDestinationWith("account")
 ```
 */
open class AnyViewMakeableConfiguration<Destination, Maker, Constructor>: ZIKSwiftViewMakeableConfiguration {
    
    /// Make destination with block.
    ///
    /// Set this in makeDestiantionWith or constructDestination block. It's for passing parameters easily, so we don't need configuration subclass to hold parameters.
    ///
    /// When using configuration with `register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>, forMakingView viewClass: AnyClass, making factory: @escaping () -> Protocol)`, makeDestination is auto used for making destination.
    ///
    /// When using a router subclass with makeable configuration, the router subclass is responsible for check and use makeDestination in `-destinationWithConfiguration:`.
    public var makeDestination: (() -> Destination?)? {
        didSet {
            if self.makeDestination == nil {
                self.__makeDestination = nil
                return
            }
            self.__makeDestination = { [unowned self] () -> Any? in
                if let destination = self.makeDestination?() {
                    return destination
                }
                return nil
            }
        }
    }
    
    /// Factory method passing required parameters and make destination. You should set makedDestination in makeDestinationWith.
    public var makeDestinationWith: Maker
    
    /// Asynchronous factory method passsing required parameters for initializing destination module, and get destination in `didMakeDestination`. You should set makeDestination to capture parameters directly, so you don't need configuration subclass to hold parameters.
    public var constructDestination: Constructor
    
    /// Give the destination with specfic type to the caller. This is auto called and reset to nil after `didFinishPrepareDestination:configuration:`.
    public var didMakeDestination: ((Destination) -> Void)? {
        didSet {
            if self.didMakeDestination == nil {
                self.__didMakeDestination = nil
                return
            }
            self.__didMakeDestination = { [unowned self] (d: Any) -> Void in
                if let destination = d as? Destination {
                    if let didMakeDestination = self.didMakeDestination {
                        self.didMakeDestination = nil
                        didMakeDestination(destination)
                    }
                } else {
                    assertionFailure("Invalid destination. Destination is not type of (\(Destination.self)): \(d)")
                }
            }
        }
    }
    
    /// Prepare the destination from the router internal before `prepareDestination(_:configuration:)`.
    ///
    /// When it's removed and routed again, this method may be called more than once. You should check whether the destination is already prepared to avoid unnecessary preparation.
    public var __prepareDestination: ((Destination) -> Void)? {
        didSet {
            if self.__prepareDestination == nil {
                self._prepareDestination = nil
                return
            }
            self._prepareDestination = { [unowned self] destination in
                if let destination = destination as? Destination {
                    self.__prepareDestination?(destination)
                }
            }
        }
    }
    
    /**
     Container to hold custom `makeDestinationWith` and `constructDestination` block. If the destination has multi custom initializers, you can add new constructor and store them in the container.
     
     ```
     protocol LoginViewModuleInput {
        var makeDestinationWith: (_ account: String) -> LoginViewInput? { get }
        var makeDestinationForNewUserWith: (_ account: String) -> LoginViewInput? { get }
     }
     
     // Let ViewMakeableConfiguration conform to LoginViewModuleInput
     extension ViewMakeableConfiguration: LoginViewModuleInput where Destination == LoginViewInput, Constructor == (String) -> LoginViewInput? {
        var makeDestinationForNewUserWith: (String) -> LoginViewInput? {
            get {
                if let block = self.constructorContainer["makeDestinationForNewUserWith"] as? (String) -> LoginViewInput? {
                    return block
                }
                return { _ in return nil }
            }
            set {
                self.constructorContainer["makeDestinationForNewUserWith"] = newValue
            }
        }
     }
     ```
     */
    public lazy var constructorContainer: [String : Any] = [:]
    
    public init(maker: Maker, constructor: Constructor) {
        makeDestinationWith = maker
        constructDestination = constructor
        super.init()
    }
}

// MARK: Strict Config

/// Proxy of ZIKViewRouteConfiguration to handle configuration in a type safe way.
public class ViewRouteStrictConfig<Destination>: PerformRouteStrictConfig<Destination> {
    internal override init(configuration: ZIKPerformRouteStrictConfiguration<AnyObject>) {
        assert(configuration is ZIKViewRouteStrictConfiguration<AnyObject>)
        super.init(configuration: configuration)
    }
    public var config: ZIKViewRouteStrictConfiguration<AnyObject> {
        get { return configuration as! ZIKViewRouteStrictConfiguration<AnyObject> }
    }
    
    /// Source ViewController or View for route.
    ///
    /// For ZIKViewRouteTypePush, ZIKViewRouteTypePresentModally, ZIKViewRouteTypePresentAsPopover, ZIKViewRouteTypePerformSegue,ZIKViewRouteTypeShow,ZIKViewRouteTypeShowDetail,ZIKViewRouteTypeAddAsChildViewController, source must be a ViewController.
    ///
    /// For ZIKViewRouteTypeAddAsSubview, source must be an UIView.
    ///
    /// For ZIKViewRouteTypeMakeDestination, source is not needed.
    public var source: ZIKViewRouteSource? {
        get { return config.source }
        set { config.source = newValue }
    }
    
    /// The style of route, default is ZIKViewRouteTypePresentModally. Subclass router may return other default value.
    public var routeType: ZIKViewRouteType {
        get { return config.routeType }
        set { config.routeType = newValue }
    }
    
    /// For push/present, default is true
    public var animated: Bool {
        get { return config.animated }
        set { config.animated = newValue }
    }
    
    /// Wrap destination in an UINavigationController, UITabBarController or UISplitViewController, and perform route on the container. Only available for ZIKViewRouteTypePush, ZIKViewRouteTypePresentModally, ZIKViewRouteTypePresentAsPopover, ZIKViewRouteTypeShow, ZIKViewRouteTypeShowDetail, ZIKViewRouteTypeAddAsChildViewController.
    ///
    /// an UINavigationController or UISplitViewController can't be pushed into another UINavigationController, so:
    ///
    /// For ZIKViewRouteTypePush, container can't be an UINavigationController or UISplitViewController
    ///
    /// For ZIKViewRouteTypeShow, if source is in an UINavigationController, container can't be an UINavigationController or UISplitViewController
    ///
    /// For ZIKViewRouteTypeShowDetail, if source is in a collapsed UISplitViewController, and master is an UINavigationController, container can't be an UINavigationController or UISplitViewController
    ///
    /// For ZIKViewRouteTypeAddAsChildViewController, will add container as source's child, so you have to add container's view to source's view in addingChildViewHandler, not the destination's view
    ///
    /// - Note: Use weak self in containerWrapper to avoid retain cycle.
    public var containerWrapper: ZIKViewRouteContainerWrapper? {
        get { return config.containerWrapper }
        set { config.containerWrapper = newValue }
    }
    
    /// Sender for -showViewController:sender: and -showDetailViewController:sender:
    public var sender: AnyObject? {
        get { return config.sender }
        set { config.sender = newValue }
    }
    
    /// Config popover for ZIKViewRouteTypePresentAsPopover
    public var configurePopover: ZIKViewRoutePopoverConfiger? {
        get { return config.configurePopover }
    }
    
    /// Config segue for ZIKViewRouteTypePerformSegue
    public var configureSegue: ZIKViewRouteSegueConfiger? {
        get { return config.configureSegue }
    }
    
    /// When use routeType addAsChildViewController, , add the destination as child view controller to the parent source view controller. Adding destination's view to source's view in addingChildViewHandler, and invoke the completion block when finished.
    ///
    /// - destination: The destination view controller. If you wrap destination with -containerWrapper, the `destination` in this block is the wrapped ViewController.
    /// - completion: Invoke the completion block when adding is finished.
    ///
    /// - Note: Use weak self in addingChildViewHandler to avoid retain cycle.
    public var addingChildViewHandler: ((ViewController, @escaping () -> Void) -> Void)? {
        get { return config.addingChildViewHandler }
        set { config.addingChildViewHandler = newValue }
    }
    public var popoverConfiguration: ZIKViewRoutePopoverConfiguration? {
        get { return config.popoverConfiguration }
    }
    public var segueConfiguration: ZIKViewRouteSegueConfiguration? {
        get { return config.segueConfiguration }
    }
    
    /// When set to true and the router still exists, if the same destination instance is routed again from external, prepareDestination, successHandler, errorHandler, completionHandler will be called.
    public var handleExternalRoute: Bool {
        get { return config.handleExternalRoute }
        set { config.handleExternalRoute = newValue }
    }
}

/// Proxy of ZIKViewRemoveConfiguration to handle configuration in a type safe way.
public class ViewRemoveStrictConfig<Destination>: RemoveRouteStrictConfig<Destination> {
    internal override init(configuration: ZIKRemoveRouteStrictConfiguration<AnyObject>) {
        assert(configuration is ZIKViewRemoveStrictConfiguration<AnyObject>)
        super.init(configuration: configuration)
    }
    public var config: ZIKViewRemoveStrictConfiguration<AnyObject> {
        get { return configuration as! ZIKViewRemoveStrictConfiguration<AnyObject> }
    }
    
    /// For pop/dismiss, default is true
    public var animated: Bool {
        get { return config.animated }
        set { config.animated = newValue }
    }
    
    /// When use routeType ZIKViewRouteTypeAddAsChildViewController and remove, remove the destination's view from its superview in removingChildViewHandler, and invoke the completion block when finished.
    ///
    /// - destination: The destination view controller. If you wrap destination with -containerWrapper, the `destination` in this block is the wrapped ViewController.
    /// - completion: Invoke the completion block when removing is finished.
    ///
    /// - Note: Use weak self in removingChildViewHandler to avoid retain cycle.
    public var removingChildViewHandler: ((ViewController, @escaping () -> Void) -> Void)? {
        get { return config.removingChildViewHandler }
        set { config.removingChildViewHandler = newValue }
    }
    
    /// When set to true and the router still exists, if the same destination instance is removed from external, successHandler, errorHandler will be called.
    public var handleExternalRoute: Bool {
        get { return config.handleExternalRoute }
        set { config.handleExternalRoute = newValue }
    }
}
