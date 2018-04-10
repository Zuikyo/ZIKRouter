
//
//  Router.swift
//  ZRouter
//
//  Created by zuik on 2017/10/16.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import ZIKRouter.Internal
import ZIKRouter.Private

internal let shouldCheckViewRouter = ZIKAnyViewRouter.shouldCheckImplementation()
internal let shouldCheckServiceRouter = ZIKAnyServiceRouter.shouldCheckImplementation()

///Key of registered protocol.
internal struct _RouteKey: Hashable {
    fileprivate let type: Any.Type?
    private let key: String
    fileprivate init(type: Any.Type) {
        self.type = type
        key = String(describing:type)
    }
    fileprivate init(type: AnyClass) {
        self.type = type
        key = String(describing:type)
    }
    fileprivate init(route: Any) {
        self.type = nil
        key = String(describing:route)
    }
    fileprivate init(key: String) {
        type = nil
        self.key = key
    }
    fileprivate init?(routerType: ZIKAnyViewRouterType) {
        assert(routerType.routerClass != nil || routerType.route != nil)
        if let routerClass = routerType.routerClass {
            self.init(type: routerClass)
        } else if let route = routerType.route {
            self.init(route: route)
        } else {
            return nil
        }
    }
    fileprivate init?(routerType: ZIKAnyServiceRouterType) {
        assert(routerType.routerClass != nil || routerType.route != nil)
        if let routerClass = routerType.routerClass {
            self.init(type: routerClass)
        } else if let route = routerType.route {
            self.init(route: route)
        } else {
            return nil
        }
    }
    var hashValue: Int {
        return key.hashValue
    }
    static func ==(lhs: _RouteKey, rhs: _RouteKey) -> Bool {
        return lhs.key == rhs.key
    }
}

///Registry for registering pure Swift protocol and discovering ZIKRouter subclass.
internal class Registry {
    /// value: subclass of ZIKViewRouter or ZIKViewRoute
    fileprivate static var viewProtocolContainer = [_RouteKey: Any]()
    /// value: subclass of ZIKViewRouter or ZIKViewRoute
    fileprivate static var viewConfigContainer = [_RouteKey: Any]()
    /// value: subclass of ZIKServiceRouter or ZIKServiceRoute
    fileprivate static var serviceProtocolContainer = [_RouteKey: Any]()
    /// value: subclass of ZIKServiceRouter or ZIKServiceRoute
    fileprivate static var serviceConfigContainer = [_RouteKey: Any]()
    fileprivate static var _check_viewProtocolContainer = [_RouteKey: Set<_RouteKey>]()
    fileprivate static var _check_serviceProtocolContainer = [_RouteKey: Set<_RouteKey>]()
    
    // MARK: Register
    
    /// Register pure Swift protocol or objc protocol for view with a ZIKViewRouter subclass. Router will check whether the registered view protocol is conformed by the registered view.
    ///
    /// - Parameters:
    ///   - routableView: A routabe entry carrying a protocol conformed by the view of the router. Can be pure Swift protocol or objc protocol.
    ///   - router: The subclass of ZIKViewRouter.
    internal static func register<Protocol>(_ routableView: RoutableView<Protocol>, forRouter router: AnyClass) {
        guard let router = router as? ZIKAnyViewRouter.Type else {
            assertionFailure("This router must be subclass of ZIKViewRouter")
            return
        }
        let destinationProtocol = Protocol.self
        assert(ZIKAnyViewRouter._isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKAnyViewRouter.self), "This router must be subclass of ZIKViewRouter")
        if ZIKRouter_isObjcProtocol(destinationProtocol) {
            router._swift_registerViewProtocol(destinationProtocol)
            return
        }
        assert(viewProtocolContainer[_RouteKey(type:destinationProtocol)] == nil, "view protocol (\(destinationProtocol)) was already registered with router (\(String(describing: viewProtocolContainer[_RouteKey(type:destinationProtocol)]))).")
        if shouldCheckViewRouter {
            _add(viewProtocol: destinationProtocol, toRouter: router)
        }
        viewProtocolContainer[_RouteKey(type:destinationProtocol)] = router
    }
    
    /// Register pure Swift protocol or objc protocol for your custom configuration with a ZIKViewRouter subclass. Router will check whether the registered config protocol is conformed by the defaultRouteConfiguration of the router.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a protocol conformed by the custom configuration of the router. Can be pure Swift protocol or objc protocol.
    ///   - router: The subclass of ZIKViewRouter.
    internal static func register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>, forRouter router: AnyClass) {
        guard let router = router as? ZIKAnyViewRouter.Type else {
            assertionFailure("This router must be subclass of ZIKViewRouter")
            return
        }
        let configProtocol = Protocol.self
        assert(ZIKAnyViewRouter._isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKAnyViewRouter.self), "This router must be subclass of ZIKViewRouter")
        if ZIKRouter_isObjcProtocol(configProtocol) {
            router._swift_registerConfigProtocol(configProtocol)
            return
        }
        assert(router.defaultRouteConfiguration() is Protocol, "The router (\(router))'s default configuration must conform to the config protocol (\(configProtocol)) to register.")
        assert(viewConfigContainer[_RouteKey(type:configProtocol)] == nil, "view config protocol (\(configProtocol)) was already registered with router (\(String(describing: viewConfigContainer[_RouteKey(type:configProtocol)]))).")
        viewConfigContainer[_RouteKey(type:configProtocol)] = router
    }
    
    /// Register pure Swift protocol or objc protocol for your service with a ZIKServiceRouter subclass. Router will check whether the registered service protocol is conformed by the registered service.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a protocol conformed by the custom configuration of the router. Can be pure Swift protocol or objc protocol.
    ///   - router: The subclass of ZIKServiceRouter.
    internal static func register<Protocol>(_ routableService: RoutableService<Protocol>, forRouter router: AnyClass) {
        guard let router = router as? ZIKAnyServiceRouter.Type else {
            assertionFailure("This router must be subclass of ZIKServiceRouter")
            return
        }
        let destinationProtocol = Protocol.self
        assert(ZIKAnyServiceRouter._isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKAnyServiceRouter.self), "This router must be subclass of ZIKServiceRouter")
        if ZIKRouter_isObjcProtocol(destinationProtocol) {
            router._swift_registerServiceProtocol(destinationProtocol)
            return
        }
        assert(serviceProtocolContainer[_RouteKey(type:destinationProtocol)] == nil, "service protocol (\(destinationProtocol)) was already registered with router (\(String(describing: serviceProtocolContainer[_RouteKey(type:destinationProtocol)]))).")
        if shouldCheckServiceRouter {
            _add(serviceProtocol: destinationProtocol, toRouter: router)
        }
        serviceProtocolContainer[_RouteKey(type:destinationProtocol)] = router
    }
    
    /// Register pure Swift protocol or objc protocol for your custom configuration with a ZIKServiceRouter subclass.  Router will check whether the registered config protocol is conformed by the defaultRouteConfiguration of the router.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a module config protocol conformed by the custom configuration of the router. Can be pure Swift protocol or objc protocol.
    ///   - router: The subclass of ZIKServiceRouter.
    internal static func register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>, forRouter router: AnyClass) {
        guard let router = router as? ZIKAnyServiceRouter.Type else {
            assertionFailure("This router must be subclass of ZIKServiceRouter")
            return
        }
        let configProtocol = Protocol.self
        assert(ZIKAnyServiceRouter._isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKAnyServiceRouter.self), "This router must be subclass of ZIKServiceRouter")
        if ZIKRouter_isObjcProtocol(configProtocol) {
            router._swift_registerConfigProtocol(configProtocol)
            return
        }
        assert(router.defaultRouteConfiguration() is Protocol, "The router (\(router))'s default configuration must conform to the config protocol (\(configProtocol)) to register.")
        assert(serviceConfigContainer[_RouteKey(type:configProtocol)] == nil, "service config protocol (\(configProtocol)) was already registered with router (\(String(describing: serviceConfigContainer[_RouteKey(type:configProtocol)]))).")
        serviceConfigContainer[_RouteKey(type:configProtocol)] = router
    }
    
    /// Register pure Swift protocol or objc protocol for view with a ZIKViewRoute. Router will check whether the registered view protocol is conformed by the registered view.
    ///
    /// - Parameters:
    ///   - routableView: A routabe entry carrying a protocol conformed by the view of the router. Can be pure Swift protocol or objc protocol.
    ///   - route: A ZIKViewRoute.
    internal static func register<Protocol>(_ routableView: RoutableView<Protocol>, forRoute route: Any) {
        guard let route = route as? ZIKAnyViewRoute else {
            assertionFailure("This route must be ZIKAnyViewRoute")
            return
        }
        let destinationProtocol = Protocol.self
        assert(ZIKAnyViewRouter._isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        if let destinationProtocol = ZIKRouter_objcProtocol(destinationProtocol) {
            _ = route.registerDestinationProtocol(destinationProtocol)
            return
        }
        assert(viewProtocolContainer[_RouteKey(type:destinationProtocol)] == nil, "view protocol (\(destinationProtocol)) was already registered with router (\(String(describing: viewProtocolContainer[_RouteKey(type:destinationProtocol)]))).")
        if shouldCheckViewRouter {
            _add(viewProtocol: destinationProtocol, toRoute: route)
        }
        viewProtocolContainer[_RouteKey(type:destinationProtocol)] = route
    }
    
    /// Register pure Swift protocol or objc protocol for your custom configuration with a ZIKViewRoute. Router will check whether the registered config protocol is conformed by the defaultRouteConfiguration of the router.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a protocol conformed by the custom configuration of the router. Can be pure Swift protocol or objc protocol.
    ///   - route: A ZIKViewRoute.
    internal static func register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>, forRoute route: Any) {
        guard let route = route as? ZIKAnyViewRoute else {
            assertionFailure("This route must be ZIKAnyViewRoute")
            return
        }
        let configProtocol = Protocol.self
        assert(ZIKAnyViewRouter._isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        if let configProtocol = ZIKRouter_objcProtocol(configProtocol) {
            _ = route.registerModuleProtocol(configProtocol)
            return
        }
        assert(ZIKAnyViewRouterType.tryMakeType(forRoute: route)!.perform(#selector(ZIKRouter<AnyObject, ZIKPerformRouteConfiguration, ZIKRemoveRouteConfiguration>.defaultRouteConfiguration)) is Protocol, "The router (\(route))'s default configuration must conform to the config protocol (\(configProtocol)) to register.")
        assert(viewConfigContainer[_RouteKey(type:configProtocol)] == nil, "view config protocol (\(configProtocol)) was already registered with router (\(String(describing: viewConfigContainer[_RouteKey(type:configProtocol)]))).")
        viewConfigContainer[_RouteKey(type:configProtocol)] = route
    }
    
    /// Register pure Swift protocol or objc protocol for your service with a ZIKServiceRoute. Router will check whether the registered service protocol is conformed by the registered service.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a protocol conformed by the custom configuration of the router. Can be pure Swift protocol or objc protocol.
    ///   - route: A ZIKServiceRoute.
    internal static func register<Protocol>(_ routableService: RoutableService<Protocol>, forRoute route: Any) {
        guard let route = route as? ZIKAnyServiceRoute else {
            assertionFailure("This route must be ZIKAnyServiceRoute")
            return
        }
        let destinationProtocol = Protocol.self
        assert(ZIKAnyServiceRouter._isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        if let destinationProtocol = ZIKRouter_objcProtocol(destinationProtocol) {
            _ = route.registerDestinationProtocol(destinationProtocol)
            return
        }
        assert(serviceProtocolContainer[_RouteKey(type:destinationProtocol)] == nil, "service protocol (\(destinationProtocol)) was already registered with router (\(String(describing: serviceProtocolContainer[_RouteKey(type:destinationProtocol)]))).")
        if shouldCheckServiceRouter {
            _add(serviceProtocol: destinationProtocol, toRoute: route)
        }
        serviceProtocolContainer[_RouteKey(type:destinationProtocol)] = route
    }
    
    /// Register pure Swift protocol or objc protocol for your custom configuration with a ZIKServiceRoute. Router will check whether the registered config protocol is conformed by the defaultRouteConfiguration of the router.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a module config protocol conformed by the custom configuration of the router. Can be pure Swift protocol or objc protocol.
    ///   - route: A ZIKServiceRoute.
    internal static func register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>, forRoute route: Any) {
        guard let route = route as? ZIKAnyServiceRoute else {
            assertionFailure("This route must be ZIKAnyServiceRoute")
            return
        }
        let configProtocol = Protocol.self
        assert(ZIKAnyServiceRouter._isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        if let configProtocol = ZIKRouter_objcProtocol(configProtocol) {
            _ = route.registerModuleProtocol(configProtocol)
            return
        }
        assert(ZIKAnyServiceRouterType.tryMakeType(forRoute: route)!.perform(#selector(ZIKRouter<AnyObject, ZIKPerformRouteConfiguration, ZIKRemoveRouteConfiguration>.defaultRouteConfiguration)) is Protocol, "The router (\(route))'s default configuration must conform to the config protocol (\(configProtocol)) to register.")
        assert(serviceConfigContainer[_RouteKey(type:configProtocol)] == nil, "service config protocol (\(configProtocol)) was already registered with router (\(String(describing: serviceConfigContainer[_RouteKey(type:configProtocol)]))).")
        serviceConfigContainer[_RouteKey(type:configProtocol)] = route
    }
    
    // MARK: Check
    
    private static func _add(viewProtocol: Any.Type, toRouter router: ZIKAnyViewRouter.Type) {
        var protocols = _check_viewProtocolContainer[_RouteKey(type: router.self)]
        if protocols == nil {
            protocols = Set()
            protocols?.insert(_RouteKey(type:viewProtocol))
        } else {
            protocols?.insert(_RouteKey(type:viewProtocol))
        }
        _check_viewProtocolContainer[_RouteKey(type: router.self)] = protocols
    }
    
    
    private static func _add(serviceProtocol: Any.Type, toRouter router: ZIKAnyServiceRouter.Type) {
        var protocols = _check_serviceProtocolContainer[_RouteKey(type: router.self)]
        if protocols == nil {
            protocols = Set()
            protocols?.insert(_RouteKey(type:serviceProtocol))
        } else {
            protocols?.insert(_RouteKey(type:serviceProtocol))
        }
        _check_serviceProtocolContainer[_RouteKey(type: router.self)] = protocols
    }
    
    private static func _add(viewProtocol: Any.Type, toRoute route: ZIKAnyViewRoute) {
        var protocols = _check_viewProtocolContainer[_RouteKey(route: route)]
        if protocols == nil {
            protocols = Set()
            protocols?.insert(_RouteKey(type:viewProtocol))
        } else {
            protocols?.insert(_RouteKey(type:viewProtocol))
        }
        _check_viewProtocolContainer[_RouteKey(route: route)] = protocols
    }
    
    
    private static func _add(serviceProtocol: Any.Type, toRoute route: ZIKAnyServiceRoute) {
        var protocols = _check_serviceProtocolContainer[_RouteKey(route: route)]
        if protocols == nil {
            protocols = Set()
            protocols?.insert(_RouteKey(type:serviceProtocol))
        } else {
            protocols?.insert(_RouteKey(type:serviceProtocol))
        }
        _check_serviceProtocolContainer[_RouteKey(route: route)] = protocols
    }
}

// MARK: Routable Discover
internal extension Registry {
    
    /// Get view router type for registered view protocol.
    ///
    /// - Parameter routableView: A routabe entry carrying a view protocol conformed by the view registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router type for the view protocol.
    internal static func router<Destination>(to routableView: RoutableView<Destination>) -> ViewRouterType<Destination, ViewRouteConfig>? {
        let routerType = _router(toView: Destination.self)
        if let routerType = routerType {
            return ViewRouterType(routerType: routerType)
        }
        return nil
    }
    
    /// Get view router type for registered view module config protocol.
    ///
    /// - Parameter routableViewModule: A routabe entry carrying a view module config protocol registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router type for the config protocol.
    internal static func router<Module>(to routableViewModule: RoutableViewModule<Module>) -> ViewRouterType<Any, Module>? {
        let routerType = _router(toViewModule: Module.self)
        if let routerType = routerType {
            return ViewRouterType(routerType: routerType)
        }
        return nil
    }
    
    /// Get service router type for registered service protocol.
    ///
    /// - Parameter routableService: A routabe entry carrying a service protocol conformed by the service registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The service router type for the service protocol.
    internal static func router<Destination>(to routableService: RoutableService<Destination>) -> ServiceRouterType<Destination, PerformRouteConfig>? {
        let routerType = _router(toService: Destination.self)
        if let routerType = routerType {
            return ServiceRouterType(routerType: routerType)
        }
        return nil
    }
    
    /// Get service router type for registered servie module config protocol.
    ///
    /// - Parameter routableServiceModule: A routabe entry carrying a cconfg protocol registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The service router type for the config protocol.
    internal static func router<Module>(to routableServiceModule: RoutableServiceModule<Module>) -> ServiceRouterType<Any, Module>? {
        let routerType = _router(toServiceModule: Module.self)
        if let routerType = routerType {
            return ServiceRouterType(routerType: routerType)
        }
        return nil
    }
}

// MARK: Switchable Discover

internal extension Registry {
    
    /// Get view router type for switchable registered view protocol, when the destination view is switchable from some view protocols.
    ///
    /// - Parameter switchableView: A struct carrying any routable view protocol, but not a specified one.
    /// - Returns: The view router type for the view protocol.
    internal static func router(to switchableView: SwitchableView) -> ViewRouterType<Any, ViewRouteConfig>? {
        let routerType = _router(toView: switchableView.routableProtocol)
        if let routerType = routerType {
            return ViewRouterType(routerType: routerType)
        }
        return nil
    }
    
    /// Get view router type for switchable registered view module protocol, when the destination view is switchable from some view module protocols.
    ///
    /// - Parameter switchableViewModule: A struct carrying any routable view module config protocol, but not a specified one.
    /// - Returns: The view router type for the view module config protocol.
    internal static func router(to switchableViewModule: SwitchableViewModule) -> ViewRouterType<Any, ViewRouteConfig>? {
        let routerType = _router(toViewModule: switchableViewModule.routableProtocol)
        if let routerType = routerType {
            return ViewRouterType(routerType: routerType)
        }
        return nil
    }
    
    /// Get service router type for switchable registered service protocol, when the destination service is switchable from some service protocols.
    ///
    /// - Parameter switchableService: A struct carrying any routable service protocol, but not a specified one.
    /// - Returns: The service router type for the service protocol.
    internal static func router(to switchableService: SwitchableService) -> ServiceRouterType<Any, PerformRouteConfig>? {
        let routerType = _router(toService: switchableService.routableProtocol)
        if let routerType = routerType {
            return ServiceRouterType(routerType: routerType)
        }
        return nil
    }
    
    /// Get service router type for switchable registered service module config protocol, when the destination service is switchable from some service module protocols.
    ///
    /// - Parameter switchableServiceModule: A struct carrying any routable service module config protocol, but not a specified one.
    /// - Returns: The service router type for the service module config protocol.
    internal static func router(to switchableServiceModule: SwitchableServiceModule) -> ServiceRouterType<Any, PerformRouteConfig>? {
        let routerType = _router(toServiceModule: switchableServiceModule.routableProtocol)
        if let routerType = routerType {
            return ServiceRouterType(routerType: routerType)
        }
        return nil
    }
}

// MARK: Dynamic Discover

internal extension Registry {
    
    /// Get view router type for registered view protocol name.
    /// - Warning: Only use this when the business logic requires highly dynamic route, e.g. handling open URL from outside and show dynamic view.
    ///
    /// - Parameter viewProtocolName: The name string of the view protocol.
    /// - Returns: The view router type for the view protocol.
    internal static func router(toDynamicView viewProtocolName: String) -> ViewRouterType<Any, ViewRouteConfig>? {
        if let route = viewProtocolContainer[_RouteKey(key:viewProtocolName)], let routerType = ZIKAnyViewRouterType.tryMakeType(forRoute: route) {
            return ViewRouterType<Any, ViewRouteConfig>(routerType: routerType)
        }
        if let viewProtocol = NSProtocolFromString(viewProtocolName), let routerType = _swift_ZIKViewRouterToView(viewProtocol) {
            return ViewRouterType<Any, ViewRouteConfig>(routerType: routerType)
        }
        if NSProtocolFromString(viewProtocolName) == nil {
            ZIKAnyViewRouter
                ._callbackGlobalErrorHandler(
                    with: nil,
                    action: .toView,
                    error: ZIKAnyViewRouter.error(withCode:ZIKViewRouteError.invalidProtocol.rawValue,
                                                  localizedDescription:"Swift view protocol name (\(viewProtocolName)) is invalid, maybe it was not registered with any view router, or not a protocol type name."))
            assertionFailure("Swift view protocol name (\(viewProtocolName)) is invalid, maybe it was not registered with any view router, or not a protocol type name.")
        }
        return nil
    }
    
    /// Get view router type for registered view module protocol name.
    /// - Warning: Only use this when the business logic requires highly dynamic route, e.g. handling open URL from outside and show dynamic view.
    ///
    /// - Parameter configProtocolName: The name string of the view module config protocol.
    /// - Returns: The view router type for the view module config protocol.
    internal static func router(toDynamicViewModule configProtocolName: String) -> ViewRouterType<Any, ViewRouteConfig>? {
        if let route = viewConfigContainer[_RouteKey(key:configProtocolName)], let routerType = ZIKAnyViewRouterType.tryMakeType(forRoute: route) {
            return ViewRouterType<Any, ViewRouteConfig>(routerType: routerType)
        }
        if let configProtocol = NSProtocolFromString(configProtocolName), let routerType = _swift_ZIKViewRouterToModule(configProtocol) {
            return ViewRouterType<Any, ViewRouteConfig>(routerType: routerType)
        }
        if NSProtocolFromString(configProtocolName) == nil {
            ZIKAnyViewRouter
                ._callbackGlobalErrorHandler(
                    with: nil,
                    action: .toViewModule,
                    error: ZIKAnyViewRouter.error(withCode:ZIKViewRouteError.invalidProtocol.rawValue,
                                                  localizedDescription:"Swift view module protocol name (\(configProtocolName)) is invalid, maybe it was not registered with any view router, or not a protocol type name."))
            assertionFailure("Swift view module protocol name (\(configProtocolName)) is invalid, maybe it was not registered with any view router, or not a protocol type name.")
        }
        return nil
    }
    
    /// Get service router type for registered service protocol name.
    /// - Warning: Only use this when the business logic requires highly dynamic route.
    ///
    /// - Parameter serviceProtocolName: The name string of the service protocol.
    /// - Returns: The service router type for the service protocol.
    internal static func router(toDynamicService serviceProtocolName: String) -> ServiceRouterType<Any, PerformRouteConfig>? {
        if let route = serviceProtocolContainer[_RouteKey(key:serviceProtocolName)], let routerType = ZIKAnyServiceRouterType.tryMakeType(forRoute: route) {
            return ServiceRouterType<Any, PerformRouteConfig>(routerType: routerType)
        }
        if let serviceProtocol = NSProtocolFromString(serviceProtocolName), let routerType = _swift_ZIKServiceRouterToService(serviceProtocol) {
            return ServiceRouterType<Any, PerformRouteConfig>(routerType: routerType)
        }
        if NSProtocolFromString(serviceProtocolName) == nil {
            ZIKAnyServiceRouter
                ._callbackGlobalErrorHandler(
                    with: nil,
                    action: .toService,
                    error: ZIKAnyServiceRouter.error(withCode:ZIKServiceRouteError.invalidProtocol.rawValue,
                                                    localizedDescription:"Swift service protocol name (\(serviceProtocolName)) is invalid, maybe it was not registered with any service router, or not a protocol name."))
            assertionFailure("Swift service protocol name (\(serviceProtocolName)) is invalid, maybe it was not registered with any service router, or not a protocol name.")
        }
        return nil
    }
    
    /// Get service router type for registered service module protocol name.
    /// - Warning: Only use this when the business logic requires highly dynamic route.
    ///
    /// - Parameter configProtocolName: The name string of the service module config protocol.
    /// - Returns: The service router type for the service module config protocol.
    internal static func router(toDynamicServiceModule configProtocolName: String) -> ServiceRouterType<Any, PerformRouteConfig>? {
        if let route = serviceConfigContainer[_RouteKey(key:configProtocolName)], let routerType = ZIKAnyServiceRouterType.tryMakeType(forRoute: route) {
            return ServiceRouterType<Any, PerformRouteConfig>(routerType: routerType)
        }
        if let configProtocol = NSProtocolFromString(configProtocolName), let routerType = _swift_ZIKServiceRouterToModule(configProtocol) {
            return ServiceRouterType<Any, PerformRouteConfig>(routerType: routerType)
        }
        if NSProtocolFromString(configProtocolName) == nil {
            ZIKAnyServiceRouter
                ._callbackGlobalErrorHandler(
                    with: nil,
                    action: .toServiceModule,
                    error: ZIKAnyServiceRouter.error(withCode:ZIKServiceRouteError.invalidProtocol.rawValue,
                                                     localizedDescription:"Swift service module protocol name (\(configProtocolName)) is invalid, maybe it was not registered with any service router, or not a protocol name."))
            assertionFailure("Swift service module protocol name (\(configProtocolName)) is invalid, maybe it was not registered with any service router, or not a protocol name.")
        }
        return nil
    }
}

// MARK: Type Discover

fileprivate extension Registry {
    
    /// Get view router class for registered view protocol.
    ///
    /// - Parameter routableView: A routabe entry carrying a view protocol conformed by the view registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router class for the view protocol.
    fileprivate static func _router(toView viewProtocol: Any.Type) -> ZIKAnyViewRouterType? {
        if let route = viewProtocolContainer[_RouteKey(type:viewProtocol)], let routerType = ZIKAnyViewRouterType.tryMakeType(forRoute: route) {
            return routerType
        }
        if ZIKRouter_isObjcProtocol(viewProtocol), let routerType = _swift_ZIKViewRouterToView(viewProtocol) {
            return routerType
        }
        if !ZIKRouter_isObjcProtocol(viewProtocol) {
            ZIKAnyViewRouter
                ._callbackGlobalErrorHandler(
                    with: nil,
                    action: .toView,
                    error: ZIKAnyViewRouter.error(withCode:ZIKViewRouteError.invalidProtocol.rawValue,
                                                  localizedDescription:"Swift view protocol (\(viewProtocol)) was not registered with any view router."))
            assertionFailure("Swift view protocol (\(viewProtocol)) was not registered with any view router.")
        }
        return nil
    }
    
    /// Get view router class for registered config protocol.
    ///
    /// - Parameter routableViewModule: A routabe entry carrying a view module config protocol registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router class for the config protocol.
    fileprivate static func _router(toViewModule configProtocol: Any.Type) -> ZIKAnyViewRouterType? {
        if let route = viewConfigContainer[_RouteKey(type:configProtocol)], let routerType = ZIKAnyViewRouterType.tryMakeType(forRoute: route) {
            return routerType
        }
        if ZIKRouter_isObjcProtocol(configProtocol), let routerType = _swift_ZIKViewRouterToModule(configProtocol) {
            return routerType
        }
        
        if !ZIKRouter_isObjcProtocol(configProtocol) {
            ZIKAnyViewRouter
                ._callbackGlobalErrorHandler(
                    with: nil,
                    action: .toViewModule,
                    error: ZIKAnyViewRouter.error(withCode:ZIKViewRouteError.invalidProtocol.rawValue,
                                                  localizedDescription:"Swift module config protocol (\(configProtocol)) was not registered with any view router."))
            assertionFailure("Swift module config protocol (\(configProtocol)) was not registered with any view router.")
        }
        return nil
    }
    
    /// Get service router class for registered service protocol.
    ///
    /// - Parameter routableService: A routabe entry carrying a service protocol conformed by the service registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The service router class for the service protocol.
    fileprivate static func _router(toService serviceProtocol: Any.Type) -> ZIKAnyServiceRouterType? {
        if let route = serviceProtocolContainer[_RouteKey(type:serviceProtocol)], let routerType = ZIKAnyServiceRouterType.tryMakeType(forRoute: route) {
            return routerType
        }
        if ZIKRouter_isObjcProtocol(serviceProtocol), let routerType = _swift_ZIKServiceRouterToService(serviceProtocol) {
            return routerType
        }
        if !ZIKRouter_isObjcProtocol(serviceProtocol) {
            ZIKAnyServiceRouter
                ._callbackGlobalErrorHandler(
                    with: nil,
                    action: .toService,
                    error: ZIKAnyServiceRouter.error(withCode:ZIKServiceRouteError.invalidProtocol.rawValue,
                                                     localizedDescription:"Swift service protocol (\(serviceProtocol)) was not registered with any service router."))
            assertionFailure("Swift service protocol (\(serviceProtocol)) was not registered with any service router.")
        }
        return nil
    }
    
    /// Get service router class for registered config protocol.
    ///
    /// - Parameter routableServiceModule: A routabe entry carrying a service module config protocol registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The service router class for the config protocol.
    fileprivate static func _router(toServiceModule configProtocol: Any.Type) -> ZIKAnyServiceRouterType? {
        if let route = serviceConfigContainer[_RouteKey(type:configProtocol)], let routerType = ZIKAnyServiceRouterType.tryMakeType(forRoute: route) {
            return routerType
        }
        if ZIKRouter_isObjcProtocol(configProtocol), let routerType = _swift_ZIKServiceRouterToModule(configProtocol) {
            return routerType
        }
        if !ZIKRouter_isObjcProtocol(configProtocol) {
            ZIKAnyServiceRouter
                ._callbackGlobalErrorHandler(
                    with: nil,
                    action: .toServiceModule,
                    error: ZIKAnyServiceRouter.error(withCode:ZIKServiceRouteError.invalidProtocol.rawValue,
                                                     localizedDescription:"Swift module config protocol (\(configProtocol)) was not registered with any service router."))
            assertionFailure("Swift module config protocol (\(configProtocol)) was not registered with any service router.")
        }
        return nil
    }
}

// MARK: Validate
internal extension Registry {
    internal class func validateConformance(destination: Any, inViewRouterType routerType: ZIKAnyViewRouterType) -> Bool {
        guard let routeKey = _RouteKey(routerType: routerType) else {
            return false
        }
        if let protocols = _check_viewProtocolContainer[routeKey] {
            for viewProtocolEntry in protocols {
                assert(_swift_typeIsTargetType(type(of: destination), viewProtocolEntry.type!), "Bad implementation in router (\(routerType))'s destination(with configuration:), the destination (\(destination)) doesn't conforms to registered view protocol (\(viewProtocolEntry.type!))")
                if _swift_typeIsTargetType(type(of: destination), viewProtocolEntry) == false {
                    return false
                }
            }
        }
        return true
    }
    internal class func validateConformance(destination: Any, inServiceRouterType routerType: ZIKAnyServiceRouterType) -> Bool {
        guard let routeKey = _RouteKey(routerType: routerType) else {
            return false
        }
        if let protocols = _check_serviceProtocolContainer[routeKey] {
            for serviceProtocolEntry in protocols {
                assert(_swift_typeIsTargetType(type(of: destination), serviceProtocolEntry.type!), "Bad implementation in router (\(routerType))'s destination(with configuration:), the destination (\(destination)) doesn't conforms to registered service protocol (\(serviceProtocolEntry.type!))")
                if _swift_typeIsTargetType(type(of: destination), serviceProtocolEntry.type!) == false {
                    return false
                }
            }
        }
        return true
    }
}

///Make sure all registered view classes conform to their registered view protocols.
private class _ViewRouterValidater: ZIKViewRouteAdapter {
    override class func isAbstractRouter() -> Bool {
        return true
    }
    override class func registerRoutableDestination() {
        
    }
    override class func _didFinishRegistration() {
        for (routeKey, route) in Registry.viewProtocolContainer {
            let viewProtocol = routeKey.type!
            let badDestinationClass: AnyClass? = ZIKViewRouteRegistry.validateDestinations(forRoute: route, handler: { (destinationClass) -> Bool in
                return _swift_typeIsTargetType(destinationClass, viewProtocol)
            })
            assert(badDestinationClass == nil, "Registered view class (\(String(describing: badDestinationClass)) for router (\(route)) should conform to registered view protocol (\(viewProtocol)).")
        }
    }
}

///Make sure all registered service classes conform to their registered service protocols.
private class _ServiceRouterValidater: ZIKServiceRouteAdapter {
    override class func isAbstractRouter() -> Bool {
        return true
    }
    override class func registerRoutableDestination() {
        
    }
    override class func _didFinishRegistration() {
        for (routeKey, route) in Registry.serviceProtocolContainer {
            let serviceProtocol = routeKey.type!
            let badDestinationClass: AnyClass? = ZIKServiceRouteRegistry.validateDestinations(forRoute: route, handler: { (destinationClass) -> Bool in
                return _swift_typeIsTargetType(destinationClass, serviceProtocol)
            })
            assert(badDestinationClass == nil, "Registered service class (\(String(describing: badDestinationClass)) for router (\(route)) should conform to registered service protocol (\(serviceProtocol)).")
        }
    }
}
