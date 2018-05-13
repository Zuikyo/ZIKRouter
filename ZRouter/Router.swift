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

///Router with type safe convenient methods for ZIKRouter.
public class Router {
    
    // MARK: Routable Discover
    
    /// Get view router type for registered view protocol.
    ///
    /// - Parameter routableView: A routabe entry carrying a view protocol conformed by the view registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router type for the view protocol.
    public static func to<Destination>(_ routableView: RoutableView<Destination>) -> ViewRouterType<Destination, ViewRouteConfig>? {
        return Registry.router(to: routableView)
    }
    
    /// Get view router type for registered view module config protocol.
    ///
    /// - Parameter routableViewModule: A routabe entry carrying a view module config protocol registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router type for the config protocol.
    public static func to<Module>(_ routableViewModule: RoutableViewModule<Module>) -> ViewRouterType<Any, Module>? {
        return Registry.router(to: routableViewModule)
    }
    
    /// Get service router type for registered service protocol.
    ///
    /// - Parameter routableService: A routabe entry carrying a service protocol conformed by the service registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The service router type for the service protocol.
    public static func to<Destination>(_ routableService: RoutableService<Destination>) -> ServiceRouterType<Destination, PerformRouteConfig>? {
        return Registry.router(to: routableService)
    }
    
    /// Get service router type for registered servie module config protocol.
    ///
    /// - Parameter routableServiceModule: A routabe entry carrying a cconfg protocol registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The service router type for the config protocol.
    public static func to<Module>(_ routableServiceModule: RoutableServiceModule<Module>) -> ServiceRouterType<Any, Module>? {
        return Registry.router(to: routableServiceModule)
    }
    
    // MARK: Switchable Discover
    
    /// Get view router type for switchable registered view protocol, when the destination view is switchable from some view protocols.
    ///
    /// - Parameter switchableView: A struct carrying any routable view protocol, but not a specified one.
    /// - Returns: The view router type for the view protocol.
    public static func to(_ switchableView: SwitchableView) -> ViewRouterType<Any, ViewRouteConfig>? {
        return Registry.router(to: switchableView)
    }
    
    /// Get view router type for switchable registered view module protocol, when the destination view is switchable from some view module protocols.
    ///
    /// - Parameter switchableViewModule: A struct carrying any routable view module config protocol, but not a specified one.
    /// - Returns: The view router type for the view module config protocol.
    public static func to(_ switchableViewModule: SwitchableViewModule) -> ViewRouterType<Any, ViewRouteConfig>? {
        return Registry.router(to: switchableViewModule)
    }
    
    /// Get service router type for switchable registered service protocol, when the destination service is switchable from some service protocols.
    ///
    /// - Parameter switchableService: A struct carrying any routable service protocol, but not a specified one.
    /// - Returns: The service router type for the service protocol.
    public static func to(_ switchableService: SwitchableService) -> ServiceRouterType<Any, PerformRouteConfig>? {
        return Registry.router(to: switchableService)
    }
    
    /// Get service router type for switchable registered service module config protocol, when the destination service is switchable from some service module protocols.
    ///
    /// - Parameter switchableServiceModule: A struct carrying any routable service module config protocol, but not a specified one.
    /// - Returns: The service router type for the service module config protocol.
    public static func to(_ switchableServiceModule: SwitchableServiceModule) -> ServiceRouterType<Any, PerformRouteConfig>? {
        return Registry.router(to: switchableServiceModule)
    }
    
    // MARK: Identifier Discover
    
    /// Find view router registered with the unique identifier.
    ///
    /// - Parameter viewIdentifier: Identifier of the router.
    /// - Returns: The view router type for the identifier. Return nil if the identifier is not registered with any view router.
    public static func to(viewIdentifier: String) -> ViewRouterType<Any, ViewRouteConfig>? {
        if let routerType = ZIKAnyViewRouter.toIdentifier(viewIdentifier) {
            return ViewRouterType(routerType: routerType)
        }
        return nil
    }
    
    /// Find service router registered with the unique identifier.
    ///
    /// - Parameter serviceIdentifier: Identifier of the router.
    /// - Returns: The service router type for the identifier. Return nil if the identifier is not registered with any service router.
    public static func to(serviceIdentifier: String) -> ServiceRouterType<Any, PerformRouteConfig>? {
        if let routerType = ZIKAnyServiceRouter.toIdentifier(serviceIdentifier) {
            return ServiceRouterType(routerType: routerType)
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
    ///     - prepareDestination: Prepare destination before performing route. It's an escaping block, use weakSelf to avoid retain cycle.
    ///     - prepareModule: Prepare custom module config.
    ///   - removeConfigure: Configure the configuration for removing view.
    ///     - config: Config for removing view route.
    ///     - prepareDestination: Prepare destination before removing route. It's an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The view router.
    @discardableResult public static func perform<Destination>(
        to routableView: RoutableView<Destination>,
        path: ViewRoutePath,
        configuring configure: (ViewRouteConfig, (@escaping (Destination) -> Void) -> Void, ((ViewRouteConfig) -> Void) -> Void) -> Void,
        removing removeConfigure: ((ViewRemoveConfig, (@escaping (Destination) -> Void) -> Void) -> Void)? = nil
        ) -> ViewRouter<Destination, ViewRouteConfig>? {
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
    @discardableResult public static func perform<Destination>(
        to routableView: RoutableView<Destination>,
        path: ViewRoutePath
        ) -> ViewRouter<Destination, ViewRouteConfig>? {
        return perform(to: routableView, path: path, configuring: { (config, _, _) in
            
        })
    }
    
    /// Perform route with view protocol and completion.
    ///
    /// - Parameters:
    ///   - routableView: A routable entry carrying a view protocol.
    ///   - path: The route path with source and route type.
    ///   - performerCompletion: Completion for current performing.
    /// - Returns: The view router.
    @discardableResult public static func perform<Destination>(
        to routableView: RoutableView<Destination>,
        path: ViewRoutePath,
        completion performerCompletion: @escaping (Bool, Destination?, ZIKRouteAction, Error?) -> Void
        ) -> ViewRouter<Destination, ViewRouteConfig>? {
        let routerType = Registry.router(to: routableView)
        return routerType?.perform(path: path, completion: performerCompletion)
    }
    
    /// Perform route with view protocol and success handler and error handler for current performing.
    ///
    /// - Parameters:
    ///   - routableView: A routable entry carrying a view protocol.
    ///   - path: The route path with source and route type.
    ///   - performerSuccessHandler: Success handler for current performing.
    ///   - performerErrorHandler: Error handler for current performing.
    /// - Returns: The view router.
    @discardableResult public static func perform<Destination>(
        to routableView: RoutableView<Destination>,
        path: ViewRoutePath,
        successHandler performerSuccessHandler: ((Destination) -> Void)? = nil,
        errorHandler performerErrorHandler: ((ZIKRouteAction, Error) -> Void)? = nil
        ) -> ViewRouter<Destination, ViewRouteConfig>? {
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
    ///     - prepareDestination: Prepare destination before performing route. It's an escaping block, use weakSelf to avoid retain cycle.
    ///     - prepareModule: Prepare custom module config.
    ///   - removeConfigure: Configure the configuration for removing view.
    /// - Returns: The view router.
    @discardableResult public static func perform<Module>(
        to routableViewModule: RoutableViewModule<Module>,
        path: ViewRoutePath,
        configuring configure: (ViewRouteConfig, (@escaping (Any) -> Void) -> Void, ((Module) -> Void) -> Void) -> Void,
        removing removeConfigure: ((ViewRemoveConfig, (@escaping (Any) -> Void) -> Void) -> Void)? = nil
        ) -> ViewRouter<Any, Module>? {
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
    @discardableResult public static func perform<Module>(
        to routableViewModule: RoutableViewModule<Module>,
        path: ViewRoutePath
        ) -> ViewRouter<Any, Module>? {
        return perform(to: routableViewModule, path: path, configuring: { (config, _, _) in
            
        })
    }
    
    /// Perform route with view config protocol, route type and completion.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a view module config protocol.
    ///   - path: The route path with source and route type.
    ///   - performerCompletion: Completion for current performing.
    /// - Returns: The view router.
    @discardableResult public static func perform<Module>(
        to routableViewModule: RoutableViewModule<Module>,
        path: ViewRoutePath,
        completion performerCompletion: @escaping (Bool, Any?, ZIKRouteAction, Error?) -> Void
        ) -> ViewRouter<Any, Module>? {
        let routerType = Registry.router(to: routableViewModule)
        return routerType?.perform(path: path, completion: performerCompletion)
    }
    
    /// Perform route with service protocol and prepare the destination with the protocol.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a service protocol.
    ///   - configure: Configure the configuration for service route.
    ///     - config: Config for view route.
    ///     - prepareDestination: Prepare destination before performing route. It's an escaping block, use weakSelf to avoid retain cycle.
    ///     - prepareModule: Prepare custom module config.
    ///   - removeConfigure: Configure the configuration for removing service.
    /// - Returns: The service router.
    @discardableResult public static func perform<Destination>(
        to routableService: RoutableService<Destination>,
        configuring configure: (PerformRouteConfig, (@escaping (Destination) -> Void) -> Void, ((PerformRouteConfig) -> Void) -> Void) -> Void,
        removing removeConfigure: ((RemoveRouteConfig, (@escaping (Any) -> Void) -> Void) -> Void)? = nil
        ) -> ServiceRouter<Destination, PerformRouteConfig>? {
        let routerType = Registry.router(to: routableService)
        return routerType?.perform(configuring: configure, removing: removeConfigure)
    }
    
    /// Perform route with service protocol and completion.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a service protocol.
    ///   - performerCompletion: Completion for current performing.
    /// - Returns: The service router.
    @discardableResult public static func perform<Destination>(
        to routableService: RoutableService<Destination>,
        completion performerCompletion: @escaping (Bool, Any?, ZIKRouteAction, Error?) -> Void
        ) -> ServiceRouter<Destination, PerformRouteConfig>? {
        let routerType = Registry.router(to: routableService)
        return routerType?.perform(completion: performerCompletion)
    }
    
    /// Perform route with service protocol and success handler and error handler for current performing.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a service protocol.
    ///   - performerSuccessHandler: Success handler for current performing.
    ///   - performerErrorHandler: Error handler for current performing.
    /// - Returns: The service router.
    @discardableResult public static func perform<Destination>(
        to routableService: RoutableService<Destination>,
        successHandler performerSuccessHandler: ((Destination) -> Void)? = nil,
        errorHandler performerErrorHandler: ((ZIKRouteAction, Error) -> Void)? = nil
        ) -> ServiceRouter<Destination, PerformRouteConfig>? {
        let routerType = Registry.router(to: routableService)
        return routerType?.perform(successHandler: performerSuccessHandler, errorHandler: performerErrorHandler)
    }
    
    /// Perform route with service module config protocol and prepare the module with the protocol.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a module config protocol.
    ///   - configure: Configure the configuration for service route.
    ///     - config: Config for view route.
    ///     - prepareDestination: Prepare destination before performing route. It's an escaping block, use weakSelf to avoid retain cycle.
    ///     - prepareModule: Prepare custom module config.
    ///   - removeConfigure: Configure the configuration for removing service.
    /// - Returns: The service router.
    @discardableResult public static func perform<Module>(
        to routableServiceModule: RoutableServiceModule<Module>,
        configuring configure: (PerformRouteConfig, (@escaping (Any) -> Void) -> Void, ((Module) -> Void) -> Void) -> Void,
        removing removeConfigure: ((RemoveRouteConfig, (@escaping (Any) -> Void) -> Void) -> Void)? = nil
        ) -> ServiceRouter<Any, Module>? {
        let routerType = Registry.router(to: routableServiceModule)
        let router = routerType?.perform(configuring: configure, removing: removeConfigure)
        return router
    }
    
    /// Perform route with service protocol and completion.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a module config protocol.
    ///   - performerCompletion: Completion for current performing.
    /// - Returns: The service router.
    @discardableResult public static func perform<Module>(
        to routableServiceModule: RoutableServiceModule<Module>,
        completion performerCompletion: @escaping (Bool, Any?, ZIKRouteAction, Error?) -> Void
        ) -> ServiceRouter<Any, Module>? {
        let routerType = Registry.router(to: routableServiceModule)
        return routerType?.perform(completion: performerCompletion)
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
    public static func makeDestination<Destination>(
        to routableView: RoutableView<Destination>,
        preparation prepare: ((Destination) -> Void)? = nil
        ) -> Destination? {
        let routerClass = Registry.router(to: routableView)
        return routerClass?.makeDestination(preparation: prepare)
    }
    
    /// Get view destination with view protocol.
    ///
    /// - Parameters:
    ///   - routableView: A routabe entry carrying a view protocol.
    ///   - configure: Prepare the destination and other parameters.
    /// - Returns: The view destination.
    public static func makeDestination<Destination>(
        to routableView: RoutableView<Destination>,
        configuring configure: (ViewRouteConfig, (@escaping (Destination) -> Void) -> Void, ((ViewRouteConfig) -> Void) -> Void) -> Void
        ) -> Destination? {
        let routerClass = Registry.router(to: routableView)
        return routerClass?.makeDestination(configuring: configure)
    }
    
    /// Get view destination with view config protocol.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a view module config protocol.
    ///   - prepare: Prepare the module with the protocol. This is an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The view destination.
    public static func makeDestination<Module>(
        to routableViewModule: RoutableViewModule<Module>,
        preparation prepare: ((Module) -> Void)? = nil
        ) -> Any? {
        var destination: Any?
        let routerClass = Registry.router(to: routableViewModule)
        _ = routerClass?.makeDestination(configuring: { config,_,_  in
            config.routeType = ViewRouteType.makeDestination
            if let moduleConfig = config as? Module {
                prepare?(moduleConfig)
            } else {
                assertionFailure("Bad implementation in router, configuration (\(config)) should be type (\(Module.self))")
            }
            config.successHandler = { d in
                destination = d
            }
        })
        return destination
    }
    
    /// Get view destination with view config protocol.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a view module config protocol.
    ///   - configure: Prepare the module with the protocol.
    /// - Returns: The view destination.
    public static func makeDestination<Module>(
        to routableViewModule: RoutableViewModule<Module>,
        configuring configure: (ViewRouteConfig, (@escaping (Any) -> Void) -> Void, ((Module) -> Void) -> Void) -> Void
        ) -> Any? {
        let routerClass = Registry.router(to: routableViewModule)
        return routerClass?.makeDestination(configuring: configure)
    }
    
    /// Get service destination conforming the service protocol.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a service protocol.
    ///   - prepare: Prepare the destination with the protocol. This is an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The service destination.
    public static func makeDestination<Destination>(
        to routableService: RoutableService<Destination>,
        preparation prepare: ((Destination) -> Void)? = nil
        ) -> Destination? {
        let routerClass = Registry.router(to: routableService)
        return routerClass?.makeDestination(preparation: prepare)
    }
    
    /// Get service destination with service config protocol.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a service protocol.
    ///   - configure: Prepare the destination and other parameters.
    /// - Returns: The service destination.
    public static func makeDestination<Destination>(
        to routableService: RoutableService<Destination>,
        configuring configure: (PerformRouteConfig, (@escaping (Destination) -> Void) -> Void, ((PerformRouteConfig) -> Void) -> Void) -> Void
        ) -> Destination? {
        let routerClass = Registry.router(to: routableService)
        return routerClass?.makeDestination(configuring: configure)
    }
    
    /// Get service destination with service config protocol.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a service module config protocol.
    ///   - prepare: Prepare the module with the protocol. This is an escaping block, use weakSelf to avoid retain cycle.
    /// - Returns: The service destination.
    public static func makeDestination<Module>(
        to routableServiceModule: RoutableServiceModule<Module>,
        preparation prepare: ((Module) -> Void)? = nil
        ) -> Any? {
        var destination: Any?
        let routerClass = Registry.router(to: routableServiceModule)
        _ = routerClass?.perform(configuring: { config,_,_  in
            if let moduleConfig = config as? Module {
                prepare?(moduleConfig)
            } else {
                assertionFailure("Bad implementation in router, configuration (\(config)) should be type (\(Module.self))")
            }
            config.successHandler = { d in
                destination = d
            }
        })
        return destination
    }
    
    /// Get service destination with service config protocol.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a service module config protocol.
    ///   - configure: Prepare the module with the protocol.
    /// - Returns: The service destination.
    public static func makeDestination<Module>(
        to routableServiceModule: RoutableServiceModule<Module>,
        configuring configure: (PerformRouteConfig, (@escaping (Any) -> Void) -> Void, ((Module) -> Void) -> Void) -> Void
        ) -> Any? {
        let routerClass = Registry.router(to: routableServiceModule)
        return routerClass?.makeDestination(configuring: configure)
    }
    
    // MARK: Deprecated
    
    @available(iOS, deprecated: 8.0, message: "Use perform(to:path:configuring:removing:) instead")
    @discardableResult public static func perform<Destination>(
        to routableView: RoutableView<Destination>,
        from source: ZIKViewRouteSource?,
        configuring configure: (ViewRouteConfig, (@escaping (Destination) -> Void) -> Void, ((ViewRouteConfig) -> Void) -> Void) -> Void,
        removing removeConfigure: ((ViewRemoveConfig, (@escaping (Destination) -> Void) -> Void) -> Void)? = nil
        ) -> ViewRouter<Destination, ViewRouteConfig>? {
        let routerType = Registry.router(to: routableView)
        return routerType?.perform(from: source, configuring: configure, removing: removeConfigure)
    }
    
    @available(iOS, deprecated: 8.0, message: "Use perform(to:path:) instead")
    @discardableResult public static func perform<Destination>(
        to routableView: RoutableView<Destination>,
        from source: ZIKViewRouteSource?,
        routeType: ViewRouteType
        ) -> ViewRouter<Destination, ViewRouteConfig>? {
        return perform(to: routableView, from: source, configuring: { (config, _, _) in
            config.routeType = routeType
        })
    }
    
    @available(iOS, deprecated: 8.0, message: "Use perform(to:path:configuring:removing:) instead")
    @discardableResult public static func perform<Module>(
        to routableViewModule: RoutableViewModule<Module>,
        from source: ZIKViewRouteSource?,
        configuring configure: (ViewRouteConfig, (@escaping (Any) -> Void) -> Void, ((Module) -> Void) -> Void) -> Void,
        removing removeConfigure: ((ViewRemoveConfig, (@escaping (Any) -> Void) -> Void) -> Void)? = nil
        ) -> ViewRouter<Any, Module>? {
        let routerType = Registry.router(to: routableViewModule)
        return routerType?.perform(from: source, configuring: configure, removing: removeConfigure)
    }
    
    @available(iOS, deprecated: 8.0, message: "Use perform(to:path:) instead")
    @discardableResult public static func perform<Module>(
        to routableViewModule: RoutableViewModule<Module>,
        from source: ZIKViewRouteSource?,
        routeType: ViewRouteType
        ) -> ViewRouter<Any, Module>? {
        return perform(to: routableViewModule, from: source, configuring: { (config, _, _) in
            config.routeType = routeType
        })
    }
}
