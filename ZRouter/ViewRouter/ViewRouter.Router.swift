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

/// Router with type safe convenient methods for ZIKRouter.
public extension Router {
    
    // MARK: Routable Discover
    
    /// Get view router type for registered view protocol.
    ///
    /// - Parameter routableView: A routabe entry carrying a view protocol conformed by the view registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router type for the view protocol.
    static func to<Protocol>(_ routableView: RoutableView<Protocol>) -> ViewRouterType<Protocol, ViewRouteConfig>? {
        return Registry.router(to: routableView)
    }
    
    /// Get view router type for registered view module config protocol.
    ///
    /// - Parameter routableViewModule: A routabe entry carrying a view module config protocol registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router type for the config protocol.
    static func to<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>) -> ViewRouterType<Any, Protocol>? {
        return Registry.router(to: routableViewModule)
    }
    
    // MARK: Switchable Discover
    
    /// Get view router type for switchable registered view protocol, when the destination view is switchable from some view protocols.
    ///
    /// - Parameter switchableView: A struct carrying any routable view protocol, but not a specified one.
    /// - Returns: The view router type for the view protocol.
    static func to(_ switchableView: SwitchableView) -> ViewRouterType<Any, ViewRouteConfig>? {
        return Registry.router(to: switchableView)
    }
    
    /// Get view router type for switchable registered view module protocol, when the destination view is switchable from some view module protocols.
    ///
    /// - Parameter switchableViewModule: A struct carrying any routable view module config protocol, but not a specified one.
    /// - Returns: The view router type for the view module config protocol.
    static func to(_ switchableViewModule: SwitchableViewModule) -> ViewRouterType<Any, ViewRouteConfig>? {
        return Registry.router(to: switchableViewModule)
    }
    
    // MARK: Identifier Discover
    
    /// Find view router registered with the unique identifier.
    ///
    /// - Parameter viewIdentifier: Identifier of the router.
    /// - Returns: The view router type for the identifier. Return nil if the identifier is not registered with any view router.
    static func to(viewIdentifier: String) -> ViewRouterType<Any, ViewRouteConfig>? {
        if let routerType = ZIKAnyViewRouter.toIdentifier(viewIdentifier) {
            return ViewRouterType(routerType: routerType)
        }
        return nil
    }
    
}

// MARK: Perform

public extension Router {
    
    /// Perform route with view protocol and prepare the destination with the protocol.
    ///
    /// - Parameters:
    ///   - routableView: A routable entry carrying a view protocol.
    ///   - source: Source UIViewController or UIView. See ZIKViewRouteConfiguration's source.
    ///   - configure: Configure the configuration for performing view route.
    ///     - config: Config for view route.
    ///     - prepareModule: Prepare custom module config.
    ///   - removeConfigure: Configure the configuration for removing view.
    ///     - config: Config for removing view route.
    /// - Returns: The view router.
    @discardableResult static func perform<Protocol>(
        to routableView: RoutableView<Protocol>,
        path: ViewRoutePath,
        configuring configure: (ViewRouteStrictConfig<Protocol>, ((ViewRouteConfig) -> Void) -> Void) -> Void,
        removing removeConfigure: ((ViewRemoveStrictConfig<Protocol>) -> Void)? = nil
        ) -> ViewRouter<Protocol, ViewRouteConfig>? {
        let routerType = Registry.router(to: routableView)
        return routerType?.perform(path: path, configuring: configure, removing: removeConfigure)
    }
    
    /// Perform route with view protocol and route type.
    ///
    /// - Parameters:
    ///   - routableView: A routable entry carrying a view protocol.
    ///   - source: Source UIViewController or UIView. See ZIKViewRouteConfiguration's source.
    ///   - routeType: Transition type.
    /// - Returns: The view router.
    @discardableResult static func perform<Protocol>(
        to routableView: RoutableView<Protocol>,
        path: ViewRoutePath
        ) -> ViewRouter<Protocol, ViewRouteConfig>? {
        return perform(to: routableView, path: path, configuring: { (config, _) in
            
        })
    }
    
    /// Perform route with view protocol and completion.
    ///
    /// - Parameters:
    ///   - routableView: A routable entry carrying a view protocol.
    ///   - path: The route path with source and route type.
    ///   - performerCompletion: Completion for current performing.
    /// - Returns: The view router.
    @discardableResult static func perform<Protocol>(
        to routableView: RoutableView<Protocol>,
        path: ViewRoutePath,
        completion performerCompletion: @escaping (Bool, Protocol?, ZIKRouteAction, Error?) -> Void
        ) -> ViewRouter<Protocol, ViewRouteConfig>? {
        let routerType = Registry.router(to: routableView)
        return routerType?.perform(path: path, completion: performerCompletion)
    }
    
    /// Prepare the destination with destination protocol and perform route.
    ///
    /// - Parameters:
    ///   - routableView: A routable entry carrying a view protocol.
    ///   - path: The route path with source and route type.
    ///   - preparation: Prepare the destination with destination protocol. It's an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The view router for this route.
    @discardableResult static func perform<Protocol>(
        to routableView: RoutableView<Protocol>,
        path: ViewRoutePath,
        preparation prepare: @escaping ((Protocol) -> Void)
        ) -> ViewRouter<Protocol, ViewRouteConfig>? {
        let routerType = Registry.router(to: routableView)
        return routerType?.perform(path: path, preparation: prepare)
    }
    
    /// Perform route with view protocol and success handler and error handler for current performing.
    ///
    /// - Parameters:
    ///   - routableView: A routable entry carrying a view protocol.
    ///   - path: The route path with source and route type.
    ///   - performerSuccessHandler: Success handler for current performing.
    ///   - performerErrorHandler: Error handler for current performing.
    /// - Returns: The view router.
    @discardableResult static func perform<Protocol>(
        to routableView: RoutableView<Protocol>,
        path: ViewRoutePath,
        successHandler performerSuccessHandler: ((Protocol) -> Void)? = nil,
        errorHandler performerErrorHandler: ((ZIKRouteAction, Error) -> Void)? = nil
        ) -> ViewRouter<Protocol, ViewRouteConfig>? {
        let routerType = Registry.router(to: routableView)
        return routerType?.perform(path: path, successHandler: performerSuccessHandler, errorHandler: performerErrorHandler)
    }
    
    /// Perform route with view config protocol and prepare the module with the protocol.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a view module config protocol.
    ///   - source: Source UIViewController or UIView. See ZIKViewRouteConfiguration's source.
    ///   - configure: Configure the configuration for view route.
    ///     - config: Config for view route.
    ///     - prepareModule: Prepare custom module config.
    ///   - removeConfigure: Configure the configuration for removing view.
    /// - Returns: The view router.
    @discardableResult static func perform<Protocol>(
        to routableViewModule: RoutableViewModule<Protocol>,
        path: ViewRoutePath,
        configuring configure: (ViewRouteStrictConfig<Any>, ((Protocol) -> Void) -> Void) -> Void,
        removing removeConfigure: ((ViewRemoveStrictConfig<Any>) -> Void)? = nil
        ) -> ViewRouter<Any, Protocol>? {
        let routerType = Registry.router(to: routableViewModule)
        return routerType?.perform(path: path, configuring: configure, removing: removeConfigure)
    }
    
    /// Perform route with view config protocol and route type.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a view module config protocol.
    ///   - source: Source UIViewController or UIView. See ZIKViewRouteConfiguration's source.
    ///   - routeType: Transition type.
    /// - Returns: The view router.
    @discardableResult static func perform<Protocol>(
        to routableViewModule: RoutableViewModule<Protocol>,
        path: ViewRoutePath
        ) -> ViewRouter<Any, Protocol>? {
        return perform(to: routableViewModule, path: path, configuring: { (config, _) in
            
        })
    }
    
    /// Perform route with view config protocol, route type and completion.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a view module config protocol.
    ///   - path: The route path with source and route type.
    ///   - performerCompletion: Completion for current performing.
    /// - Returns: The view router.
    @discardableResult static func perform<Protocol>(
        to routableViewModule: RoutableViewModule<Protocol>,
        path: ViewRoutePath,
        completion performerCompletion: @escaping (Bool, Any?, ZIKRouteAction, Error?) -> Void
        ) -> ViewRouter<Any, Protocol>? {
        let routerType = Registry.router(to: routableViewModule)
        return routerType?.perform(path: path, completion: performerCompletion)
    }
    
    /// Prepare the destination module with module protocol and perform route.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routable entry carrying a view module config protocol.
    ///   - path: The route path with source and route type.
    ///   - preparation: Prepare the module with protocol.
    /// - Returns: The view router for this route.
    @discardableResult static func perform<Protocol>(
        to routableViewModule: RoutableViewModule<Protocol>,
        path: ViewRoutePath,
        preparation prepare: @escaping ((Protocol) -> Void)
        ) -> ViewRouter<Any, Protocol>? {
        let routerType = Registry.router(to: routableViewModule)
        return routerType?.perform(path: path, configuring: { (_, prepareModule) in
            prepareModule(prepare)
        })
    }
    
}

// MARK: Factory
public extension Router {
    
    /// Get view destination conforming the view protocol.
    ///
    /// - Parameters:
    ///   - routableView: A routabe entry carrying a view protocol.
    ///   - prepare: Prepare the destination with the protocol. This is an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The view destination.
    static func makeDestination<Protocol>(
        to routableView: RoutableView<Protocol>,
        preparation prepare: ((Protocol) -> Void)? = nil
        ) -> Protocol? {
        let routerClass = Registry.router(to: routableView)
        return routerClass?.makeDestination(preparation: prepare)
    }
    
    /// Get view destination with view protocol.
    ///
    /// - Parameters:
    ///   - routableView: A routabe entry carrying a view protocol.
    ///   - configure: Prepare the destination and other parameters.
    /// - Returns: The view destination.
    static func makeDestination<Protocol>(
        to routableView: RoutableView<Protocol>,
        configuring configure: (ViewRouteStrictConfig<Protocol>, ((ViewRouteConfig) -> Void) -> Void) -> Void
        ) -> Protocol? {
        let routerClass = Registry.router(to: routableView)
        return routerClass?.makeDestination(configuring: configure)
    }
    
    /// Get view destination with view config protocol.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a view module config protocol.
    ///   - prepare: Prepare the module with the protocol. This is an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The view destination.
    static func makeDestination<Protocol>(
        to routableViewModule: RoutableViewModule<Protocol>,
        preparation prepare: ((Protocol) -> Void)? = nil
        ) -> Any? {
        let routerType = Registry.router(to: routableViewModule)
        return routerType?.makeDestination(configuring: { (config, prepareModule) in
            if let prepare = prepare {
                prepareModule(prepare)
            }
        })
    }
    
    /// Get view destination with view config protocol.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a view module config protocol.
    ///   - configure: Prepare the module with the protocol.
    /// - Returns: The view destination.
    static func makeDestination<Protocol>(
        to routableViewModule: RoutableViewModule<Protocol>,
        configuring configure: (ViewRouteStrictConfig<Any>, ((Protocol) -> Void) -> Void) -> Void
        ) -> Any? {
        let routerClass = Registry.router(to: routableViewModule)
        return routerClass?.makeDestination(configuring: configure)
    }
    
    // MARK: Utility
    
    /// Enumerate all view routers. You can notify custom events to view routers with it.
    ///
    /// - Parameter handler: The enumerator gives subclasses of ZIKViewRouter.
    static func enumerateAllViewRouters(_ handler: (ZIKAnyViewRouter.Type) -> Void) -> Void {
        ZIKAnyViewRouter.enumerateAllViewRouters { (routerClass) in
            if let routerType = routerClass as? ZIKAnyViewRouter.Type {
                handler(routerType)
            }
        }
    }
    
    // MARK: Deprecated
    
    @available(iOS, deprecated: 8.0, message: "Use perform(to:path:configuring:removing:) instead")
    @discardableResult static func perform<Protocol>(
        to routableView: RoutableView<Protocol>,
        from source: ZIKViewRouteSource?,
        configuring configure: (ViewRouteStrictConfig<Protocol>, ((ViewRouteConfig) -> Void) -> Void) -> Void,
        removing removeConfigure: ((ViewRemoveStrictConfig<Protocol>) -> Void)? = nil
        ) -> ViewRouter<Protocol, ViewRouteConfig>? {
        let routerType = Registry.router(to: routableView)
        return routerType?.perform(from: source, configuring: configure, removing: removeConfigure)
    }
    
    @available(iOS, deprecated: 8.0, message: "Use perform(to:path:) instead")
    @discardableResult static func perform<Protocol>(
        to routableView: RoutableView<Protocol>,
        from source: ZIKViewRouteSource?,
        routeType: ViewRouteType
        ) -> ViewRouter<Protocol, ViewRouteConfig>? {
        return perform(to: routableView, from: source, configuring: { (config, _) in
            config.routeType = routeType
        })
    }
    
    @available(iOS, deprecated: 8.0, message: "Use perform(to:path:configuring:removing:) instead")
    @discardableResult static func perform<Protocol>(
        to routableViewModule: RoutableViewModule<Protocol>,
        from source: ZIKViewRouteSource?,
        configuring configure: (ViewRouteStrictConfig<Any>, ((Protocol) -> Void) -> Void) -> Void,
        removing removeConfigure: ((ViewRemoveStrictConfig<Any>) -> Void)? = nil
        ) -> ViewRouter<Any, Protocol>? {
        let routerType = Registry.router(to: routableViewModule)
        return routerType?.perform(from: source, configuring: configure, removing: removeConfigure)
    }
    
    @available(iOS, deprecated: 8.0, message: "Use perform(to:path:) instead")
    @discardableResult static func perform<Protocol>(
        to routableViewModule: RoutableViewModule<Protocol>,
        from source: ZIKViewRouteSource?,
        routeType: ViewRouteType
        ) -> ViewRouter<Any, Protocol>? {
        return perform(to: routableViewModule, from: source, configuring: { (config, _) in
            config.routeType = routeType
        })
    }
}
