
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
    init(type: Any.Type) {
        self.type = type
        key = String(describing:type)
    }
    init(key: String) {
        type = nil
        self.key = key
    }
    var hashValue: Int {
        return key.hashValue
    }
    static func ==(lhs: _RouteKey, rhs: _RouteKey) -> Bool {
        return lhs.key == rhs.key
    }
}

///Registry for registering pure Swift protocol and discovering ZIKRouter subclass.
public class Registry {
    fileprivate static var viewProtocolContainer = [_RouteKey: ZIKAnyViewRouter.Type]()
    private static var viewConfigContainer = [_RouteKey: ZIKAnyViewRouter.Type]()
    fileprivate static var swiftServiceContainer = [_RouteKey: RouterAware.Type]()
    fileprivate static var serviceProtocolContainer = [_RouteKey: ZIKAnyServiceRouter.Type]()
    private static var serviceConfigContainer = [_RouteKey: ZIKAnyServiceRouter.Type]()
    private static var _check_viewProtocolContainer = [_RouteKey: Set<_RouteKey>]()
    private static var _check_serviceProtocolContainer = [_RouteKey: Set<_RouteKey>]()
    
    // MARK: Register
    
    /// Register pure Swift protocol or objc protocol for view with a ZIKViewRouter subclass. Router will check whether the registered view protocol is conformed by the registered view.
    ///
    /// - Parameters:
    ///   - routableView: A routabe entry carrying a protocol conformed by the view of the router. Can be pure Swift protocol or objc protocol.
    ///   - router: The subclass of ZIKViewRouter.
    public static func register<Protocol>(_ routableView: RoutableView<Protocol>, forRouter router: AnyClass) {
        let viewProtocol = Protocol.self
        assert(ZIKAnyViewRouter._isAutoRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKAnyViewRouter.self), "This router must be subclass of ZIKViewRouter")
        if ZIKRouter_isObjcProtocol(viewProtocol) {
            (router as! ZIKAnyViewRouter.Type)._swift_registerViewProtocol(viewProtocol)
            return
        }
        assert(viewProtocolContainer[_RouteKey(type:viewProtocol)] == nil, "view protocol (\(viewProtocol)) was already registered with router (\(String(describing: viewProtocolContainer[_RouteKey(type:viewProtocol)]))).")
        if shouldCheckViewRouter {
            _add(viewProtocol: viewProtocol, toRouter: router as! ZIKAnyViewRouter.Type)
        }
        viewProtocolContainer[_RouteKey(type:viewProtocol)] = (router as! ZIKAnyViewRouter.Type)
    }
    
    /// Register pure Swift protocol or objc protocol for your custom configuration with a ZIKViewRouter subclass. Router will check whether the registered config protocol is conformed by the defaultRouteConfiguration of the router.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a protocol conformed by the custom configuration of the router. Can be pure Swift protocol or objc protocol.
    ///   - router: The subclass of ZIKViewRouter.
    public static func register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>, forRouter router: AnyClass) {
        let configProtocol = Protocol.self
        assert(ZIKAnyViewRouter._isAutoRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKAnyViewRouter.self), "This router must be subclass of ZIKViewRouter")
        if ZIKRouter_isObjcProtocol(configProtocol) {
            (router as! ZIKAnyViewRouter.Type)._swift_registerConfigProtocol(configProtocol)
            return
        }
        assert((router as! ZIKAnyViewRouter.Type).defaultRouteConfiguration() is Protocol, "The router (\(router))'s default configuration must conform to the config protocol (\(configProtocol)) to register.")
        assert(viewConfigContainer[_RouteKey(type:configProtocol)] == nil, "view config protocol (\(configProtocol)) was already registered with router (\(String(describing: viewConfigContainer[_RouteKey(type:configProtocol)]))).")
        viewConfigContainer[_RouteKey(type:configProtocol)] = (router as! ZIKAnyViewRouter.Type)
    }
    
    public static func register(swiftType: Any.Type, forRouter router: RouterAware.Type) {
        assert(ZIKAnyServiceRouter._isAutoRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKAnyServiceRouter.self), "This router must be subclass of ZIKServiceRouter")
        swiftServiceContainer[_RouteKey(type:swiftType)] = router
    }
    
    /// Register pure Swift protocol or objc protocol for your service with a ZIKServiceRouter subclass. Router will check whether the registered service protocol is conformed by the registered service.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a protocol conformed by the custom configuration of the router. Can be pure Swift protocol or objc protocol.
    ///   - router: The subclass of ZIKServiceRouter.
    public static func register<Protocol>(_ routableService: RoutableService<Protocol>, forRouter router: AnyClass) {
        let serviceProtocol = Protocol.self
        assert(ZIKAnyServiceRouter._isAutoRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKAnyServiceRouter.self), "This router must be subclass of ZIKServiceRouter")
        if ZIKRouter_isObjcProtocol(serviceProtocol) {
            (router as! ZIKAnyServiceRouter.Type)._swift_registerServiceProtocol(serviceProtocol)
            return
        }
        assert(serviceProtocolContainer[_RouteKey(type:serviceProtocol)] == nil, "service protocol (\(serviceProtocol)) was already registered with router (\(String(describing: serviceProtocolContainer[_RouteKey(type:serviceProtocol)]))).")
        if shouldCheckServiceRouter {
            _add(serviceProtocol: serviceProtocol, toRouter: router as! ZIKAnyServiceRouter.Type)
        }
        serviceProtocolContainer[_RouteKey(type:serviceProtocol)] = (router as! ZIKAnyServiceRouter.Type)
    }
    
    /// Register pure Swift protocol or objc protocol for your custom configuration with a ZIKServiceRouter subclass.  Router will check whether the registered config protocol is conformed by the defaultRouteConfiguration of the router.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a module config protocol conformed by the custom configuration of the router. Can be pure Swift protocol or objc protocol.
    ///   - router: The subclass of ZIKServiceRouter.
    public static func register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>, forRouter router: AnyClass) {
        let configProtocol = Protocol.self
        assert(ZIKAnyServiceRouter._isAutoRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKAnyServiceRouter.self), "This router must be subclass of ZIKServiceRouter")
        if ZIKRouter_isObjcProtocol(configProtocol) {
            (router as! ZIKAnyServiceRouter.Type)._swift_registerConfigProtocol(configProtocol)
            return
        }
        assert((router as! ZIKAnyServiceRouter.Type).defaultRouteConfiguration() is Protocol, "The router (\(router))'s default configuration must conform to the config protocol (\(configProtocol)) to register.")
        assert(serviceConfigContainer[_RouteKey(type:configProtocol)] == nil, "service config protocol (\(configProtocol)) was already registered with router (\(String(describing: serviceConfigContainer[_RouteKey(type:configProtocol)]))).")
        serviceConfigContainer[_RouteKey(type:configProtocol)] = (router as! ZIKAnyServiceRouter.Type)
    }
    
    
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
}

// MARK: Routable Discover
extension Registry {
    
    /// Get view router class for registered view protocol.
    ///
    /// - Parameter routableView: A routabe entry carrying a view protocol conformed by the view registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router class for the view protocol.
    public static func router<Destination>(to routableView: RoutableView<Destination>) -> ViewRouter<Destination, ViewRouteConfig>? {
        let routerClass = _router(toView: Destination.self)
        if routerClass != nil {
            return ViewRouter(routerType: routerClass!)
        }
        return nil
    }
    
    /// Get view router class for registered view module config protocol.
    ///
    /// - Parameter routableViewModule: A routabe entry carrying a view module config protocol registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router class for the config protocol.
    public static func router<Module>(to routableViewModule: RoutableViewModule<Module>) -> ViewRouter<Any, Module>? {
        let routerClass = _router(toViewModule: Module.self)
        if routerClass != nil {
            return ViewRouter(routerType: routerClass!)
        }
        return nil
    }
    
    /// Get service router class for registered service protocol.
    ///
    /// - Parameter routableService: A routabe entry carrying a service protocol conformed by the service registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router class for the service protocol.
    public static func router<Destination>(to routableService: RoutableService<Destination>) -> ServiceRouter<Destination, PerformRouteConfig>? {
        let routerClass = _router(toService: Destination.self)
        if routerClass != nil {
            return ServiceRouter(routerType: routerClass!)
        }
        return nil
    }
    
    /// Get service router class for registered servie module config protocol.
    ///
    /// - Parameter routableServiceModule: A routabe entry carrying a cconfg protocol registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The service router class for the config protocol.
    public static func router<Module>(to routableServiceModule: RoutableServiceModule<Module>) -> ServiceRouter<Any, Module>? {
        let routerClass = _router(toServiceModule: Module.self)
        if routerClass != nil {
            return ServiceRouter(routerType: routerClass!)
        }
        return nil
    }
}

// MARK: Switchable Discover

public extension Registry {
    
    /// Get view router class for switchable registered view protocol, when the destination view is switchable from some view protocols.
    ///
    /// - Parameter switchableView: A struct carrying any routable view protocol, but not a specified one.
    /// - Returns: The view router class for the view protocol.
    public static func router(to switchableView: SwitchableView) -> ViewRouter<Any, ViewRouteConfig>? {
        let routerClass = _router(toView: switchableView.routableProtocol)
        if routerClass != nil {
            return ViewRouter(routerType: routerClass!)
        }
        return nil
    }
    
    /// Get view router class for switchable registered view module protocol, when the destination view is switchable from some view module protocols.
    ///
    /// - Parameter switchableViewModule: A struct carrying any routable view module config protocol, but not a specified one.
    /// - Returns: The view router class for the view module config protocol.
    public static func router(to switchableViewModule: SwitchableViewModule) -> ZIKAnyViewRouter.Type? {
        return _router(toView: switchableViewModule.routableProtocol)
    }
    
    /// Get view service class for switchable registered service protocol, when the destination service is switchable from some service protocols.
    ///
    /// - Parameter switchableService: A struct carrying any routable service protocol, but not a specified one.
    /// - Returns: The service router class for the service protocol.
    public static func router(to switchableService: SwitchableService) -> ZIKAnyViewRouter.Type? {
        return _router(toView: switchableService.routableProtocol)
    }
    
    /// Get service router class for switchable registered service module config protocol, when the destination service is switchable from some service module protocols.
    ///
    /// - Parameter switchableServiceModule: A struct carrying any routable service module config protocol, but not a specified one.
    /// - Returns: The service router class for the service module config protocol.
    public static func router(to switchableServiceModule: SwitchableServiceModule) -> ZIKAnyViewRouter.Type? {
        return _router(toView: switchableServiceModule.routableProtocol)
    }
}

// MARK: Dynamic Discover

public extension Registry {
    
    /// Get view router class for registered view protocol name.
    /// - Warning: Only use this when the business logic requires highly dynamic route, e.g. handling open URL from outside and show dynamic view.
    ///
    /// - Parameter viewProtocolName: The name string of the view protocol.
    /// - Returns: The view router class for the view protocol.
    public static func router(toDynamicViewKey viewProtocolName: String) -> ZIKAnyViewRouter.Type? {
        var isObjcProtocol = false
        var routerClass = viewProtocolContainer[_RouteKey(key:viewProtocolName)]
        if routerClass == nil {
            let viewProtocol = NSProtocolFromString(viewProtocolName)
            if viewProtocol != nil && ZIKRouter_isObjcProtocol(viewProtocol!) {
                isObjcProtocol = true
                routerClass = _swift_ZIKViewRouterToView(viewProtocol!) as? ZIKAnyViewRouter.Type
            }
        }
        if routerClass == nil && isObjcProtocol == false {
            ZIKAnyViewRouter._callbackGlobalErrorHandler(with: nil,
                                                         action: ZIKRouteAction.toView,
                                                         error: ZIKAnyViewRouter.error(withCode:ZIKViewRouteError.invalidProtocol.rawValue,
                                                                                       localizedDescription:"Swift view protocol name (\(viewProtocolName)) is invalid, maybe it was not registered with any view router, or not a protocol type name."))
            assertionFailure("Swift view protocol name (\(viewProtocolName)) is invalid, maybe it was not registered with any view router, or not a protocol type name.")
        }
        return routerClass
    }
    
    /// Get view router class for registered view module protocol name.
    /// - Warning: Only use this when the business logic requires highly dynamic route, e.g. handling open URL from outside and show dynamic view.
    ///
    /// - Parameter configProtocolName: The name string of the view module config protocol.
    /// - Returns: The view router class for the view module config protocol.
    public static func router(toDynamicViewModuleKey configProtocolName: String) -> ZIKAnyViewRouter.Type? {
        var isObjcProtocol = false
        var routerClass = viewConfigContainer[_RouteKey(key:configProtocolName)]
        if routerClass == nil {
            let configProtocol = NSProtocolFromString(configProtocolName)
            if configProtocol != nil && ZIKRouter_isObjcProtocol(configProtocol!) {
                isObjcProtocol = true
                routerClass = _swift_ZIKViewRouterToModule(configProtocol!) as? ZIKAnyViewRouter.Type
            }
        }
        if routerClass == nil && isObjcProtocol == false {
            ZIKAnyViewRouter._callbackGlobalErrorHandler(with: nil,
                                                         action: ZIKRouteAction.toViewModule,
                                                         error: ZIKAnyViewRouter.error(withCode:ZIKViewRouteError.invalidProtocol.rawValue,
                                                                                       localizedDescription:"Swift view module protocol name (\(configProtocolName)) is invalid, maybe it was not registered with any view router, or not a protocol type name."))
            assertionFailure("Swift view module protocol name (\(configProtocolName)) is invalid, maybe it was not registered with any view router, or not a protocol type name.")
        }
        return routerClass
    }
    
    /// Get service router class for registered service protocol name.
    /// - Warning: Only use this when the business logic requires highly dynamic route.
    ///
    /// - Parameter serviceProtocolName: The name string of the service protocol.
    /// - Returns: The service router class for the service protocol.
    public static func router(toDynamicServiceKey serviceProtocolName: String) -> ZIKAnyServiceRouter.Type? {
        var isObjcProtocol = false
        var routerClass = serviceProtocolContainer[_RouteKey(key:serviceProtocolName)]
        if routerClass == nil {
            let serviceProtocol = NSProtocolFromString(serviceProtocolName)
            if serviceProtocol != nil && ZIKRouter_isObjcProtocol(serviceProtocol!) {
                isObjcProtocol = true
                routerClass = _swift_ZIKServiceRouterToService(serviceProtocol!) as? ZIKAnyServiceRouter.Type
            }
        }
        if routerClass == nil && isObjcProtocol == false {
            ZIKAnyServiceRouter._callbackGlobalErrorHandler(with: nil,
                                                            action: ZIKRouteAction.toService,
                                                            error: ZIKAnyServiceRouter.error(withCode:ZIKServiceRouteError.invalidProtocol.rawValue,
                                                                                             localizedDescription:"Swift service protocol name (\(serviceProtocolName)) is invalid, maybe it was not registered with any service router, or not a protocol name."))
            assertionFailure("Swift service protocol name (\(serviceProtocolName)) is invalid, maybe it was not registered with any service router, or not a protocol name.")
        }
        return routerClass
    }
    
    /// Get service router class for registered service module protocol name.
    /// - Warning: Only use this when the business logic requires highly dynamic route.
    ///
    /// - Parameter configProtocolName: The name string of the service module config protocol.
    /// - Returns: The service router class for the service module config protocol.
    public static func router(toDynamicServiceModuleKey configProtocolName: String) -> ZIKAnyServiceRouter.Type? {
        var isObjcProtocol = false
        var routerClass = serviceConfigContainer[_RouteKey(key:configProtocolName)]
        if routerClass == nil {
            let configProtocol = NSProtocolFromString(configProtocolName)
            if configProtocol != nil && ZIKRouter_isObjcProtocol(configProtocol!) {
                isObjcProtocol = true
                routerClass = _swift_ZIKServiceRouterToModule(configProtocol!) as? ZIKAnyServiceRouter.Type
            }
        }
        if routerClass == nil && isObjcProtocol == false {
            ZIKAnyServiceRouter._callbackGlobalErrorHandler(with: nil,
                                                            action: ZIKRouteAction.toServiceModule,
                                                            error: ZIKAnyServiceRouter.error(withCode:ZIKServiceRouteError.invalidProtocol.rawValue,
                                                                                             localizedDescription:"Swift service module protocol name (\(configProtocolName)) is invalid, maybe it was not registered with any service router, or not a protocol name."))
            assertionFailure("Swift service module protocol name (\(configProtocolName)) is invalid, maybe it was not registered with any service router, or not a protocol name.")
        }
        return routerClass
    }
}

// MARK: Type Discover

private extension Registry {
    
    /// Get view router class for registered view protocol.
    ///
    /// - Parameter routableView: A routabe entry carrying a view protocol conformed by the view registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router class for the view protocol.
    private static func _router(toView viewProtocol: Any.Type) -> ZIKAnyViewRouter.Type? {
        var routerClass = viewProtocolContainer[_RouteKey(type:viewProtocol)]
        if routerClass == nil && ZIKRouter_isObjcProtocol(viewProtocol) {
            routerClass = _swift_ZIKViewRouterToView(viewProtocol) as? ZIKAnyViewRouter.Type
        }
        if routerClass == nil && !ZIKRouter_isObjcProtocol(viewProtocol) {
            ZIKAnyViewRouter._callbackGlobalErrorHandler(with: nil,
                                                         action: ZIKRouteAction.toView,
                                                         error: ZIKAnyViewRouter.error(withCode:ZIKViewRouteError.invalidProtocol.rawValue,
                                                                                       localizedDescription:"Swift view protocol (\(viewProtocol)) was not registered with any view router."))
            assertionFailure("Swift view protocol (\(viewProtocol)) was not registered with any view router.")
        }
        return routerClass
    }
    
    /// Get view router class for registered config protocol.
    ///
    /// - Parameter routableViewModule: A routabe entry carrying a view module config protocol registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router class for the config protocol.
    private static func _router(toViewModule configProtocol: Any.Type) -> ZIKAnyViewRouter.Type? {
        var routerClass = viewConfigContainer[_RouteKey(type:configProtocol)]
        if routerClass == nil && ZIKRouter_isObjcProtocol(configProtocol) {
            routerClass = _swift_ZIKViewRouterToModule(configProtocol) as? ZIKAnyViewRouter.Type
        }
        if routerClass == nil && !ZIKRouter_isObjcProtocol(configProtocol) {
            ZIKAnyViewRouter._callbackGlobalErrorHandler(with: nil,
                                                         action: ZIKRouteAction.toViewModule,
                                                         error: ZIKAnyViewRouter.error(withCode:ZIKViewRouteError.invalidProtocol.rawValue,
                                                                                       localizedDescription:"Swift module config protocol (\(configProtocol)) was not registered with any view router."))
            assertionFailure("Swift module config protocol (\(configProtocol)) was not registered with any view router.")
        }
        return routerClass
    }
    
    /// Get service router class for registered service protocol.
    ///
    /// - Parameter routableService: A routabe entry carrying a service protocol conformed by the service registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router class for the service protocol.
    private static func _router(toService serviceProtocol: Any.Type) -> ZIKAnyServiceRouter.Type? {
        var routerClass = serviceProtocolContainer[_RouteKey(type:serviceProtocol)]
        if routerClass == nil && ZIKRouter_isObjcProtocol(serviceProtocol) {
            routerClass = _swift_ZIKServiceRouterToService(serviceProtocol) as? ZIKAnyServiceRouter.Type
        }
        if routerClass == nil && !ZIKRouter_isObjcProtocol(serviceProtocol) {
            ZIKAnyServiceRouter._callbackGlobalErrorHandler(with: nil,
                                                            action: ZIKRouteAction.toService,
                                                            error: ZIKAnyServiceRouter.error(withCode:ZIKServiceRouteError.invalidProtocol.rawValue,
                                                                                             localizedDescription:"Swift service protocol (\(serviceProtocol)) was not registered with any service router."))
            assertionFailure("Swift service protocol (\(serviceProtocol)) was not registered with any service router.")
        }
        return routerClass
    }
    
    /// Get service router class for registered config protocol.
    ///
    /// - Parameter routableServiceModule: A routabe entry carrying a service module config protocol registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The service router class for the config protocol.
    private static func _router(toServiceModule configProtocol: Any.Type) -> ZIKAnyServiceRouter.Type? {
        var routerClass = serviceConfigContainer[_RouteKey(type:configProtocol)]
        if routerClass == nil && ZIKRouter_isObjcProtocol(configProtocol) {
            routerClass = _swift_ZIKServiceRouterToModule(configProtocol) as? ZIKAnyServiceRouter.Type
        }
        if routerClass == nil && !ZIKRouter_isObjcProtocol(configProtocol) {
            ZIKAnyServiceRouter._callbackGlobalErrorHandler(with: nil,
                                                            action: ZIKRouteAction.toServiceModule,
                                                            error: ZIKAnyServiceRouter.error(withCode:ZIKServiceRouteError.invalidProtocol.rawValue,
                                                                                             localizedDescription:"Swift module config protocol (\(configProtocol)) was not registered with any service router."))
            assertionFailure("Swift module config protocol (\(configProtocol)) was not registered with any service router.")
        }
        return routerClass
    }
}

// MARK: Validate
internal extension Registry {
    internal class func validateConformance(destination: Any, inViewRouterType routerType: ZIKAnyViewRouter.Type) -> Bool {
        let protocols = _check_viewProtocolContainer[_RouteKey(type: routerType)]
        if protocols != nil {
            for viewProtocolEntry in protocols! {
                assert(_swift_typeIsTargetType(type(of: destination), viewProtocolEntry.type!), "Bad implementation in router (\(routerType))'s destination(with configuration:), the destination (\(destination)) doesn't conforms to registered view protocol (\(viewProtocolEntry.type!))")
                if _swift_typeIsTargetType(type(of: destination), viewProtocolEntry) == false {
                    return false
                }
            }
        }
        return true
    }
    internal class func validateConformance(destination: Any, inServiceRouterType routerType: ZIKAnyServiceRouter.Type) -> Bool {
        let protocols = _check_serviceProtocolContainer[_RouteKey(type: routerType)]
        if protocols != nil {
            for serviceProtocolEntry in protocols! {
                assert(_swift_typeIsTargetType(type(of: destination), serviceProtocolEntry.type!), "Bad implementation in router (\(routerType))'s destination(with configuration:), the destination (\(destination)) doesn't conforms to registered service protocol (\(serviceProtocolEntry.type!))")
                if _swift_typeIsTargetType(type(of: destination), serviceProtocolEntry.type!) == false {
                    return false
                }
            }
        }
        return true
    }
    internal class func validateConformance(destinationType: Any.Type, inServiceRouterType routerType: RouterAware.Type) -> Bool {
        let protocols = _check_serviceProtocolContainer[_RouteKey(type: routerType)]
        if protocols != nil {
            for serviceProtocolEntry in protocols! {
                assert(_swift_typeIsTargetType(destinationType, serviceProtocolEntry.type!), "Bad implementation in router (\(routerType))'s destination(with configuration:), the destination (\(destinationType)) doesn't conforms to registered service protocol (\(serviceProtocolEntry.type!))")
                if _swift_typeIsTargetType(destinationType, serviceProtocolEntry.type!) == false {
                    return false
                }
            }
        }
        return true
    }
}

///Make sure all registered view classes conform to their registered view protocols.
private class _ViewRouterValidater: ZIKViewRouteAdapter {
    override class func registerRoutableDestination() {
        
    }
    override class func _autoRegistrationDidFinished() {
        for (routeKey, routerClass) in Registry.viewProtocolContainer {
            let viewProtocol = routeKey.type!
            assert(routerClass.validateRegisteredViewClasses({return _swift_typeIsTargetType($0, viewProtocol)}) == nil,
                   "Registered view class (\(String(describing: routerClass.validateRegisteredViewClasses{return _swift_typeIsTargetType($0, viewProtocol)}!))) for router (\(routerClass)) should conform to registered view protocol (\(viewProtocol)).")
        }
    }
}

///Make sure all registered service classes conform to their registered service protocols.
private class _ServiceRouterValidater: ZIKServiceRouteAdapter {
    override class func registerRoutableDestination() {
        
    }
    override class func _autoRegistrationDidFinished() {
        for (routeKey, routerClass) in Registry.serviceProtocolContainer {
            let serviceProtocol = routeKey.type!
            assert(routerClass.validateRegisteredServiceClasses({return _swift_typeIsTargetType($0, serviceProtocol)}) == nil,
                   "Registered service class (\(String(describing: routerClass.validateRegisteredServiceClasses{return _swift_typeIsTargetType($0, serviceProtocol)}!))) for router (\(routerClass)) should conform to registered service protocol (\(serviceProtocol)).")
        }
        for (routeKey, routerType) in Registry.swiftServiceContainer {
            let destinationType = routeKey.type!
            assert(Registry.validateConformance(destinationType: destinationType, inServiceRouterType: routerType))
        }
    }
}

extension ZIKRouteRegistry {
    @objc class func _beforeStartRegistration() {
        self.add(SwiftServiceRegistry.self)
    }
}

private class SwiftServiceRegistry: ZIKRouteRegistry {
    override class func handleEnumerateClasses(_ aClass: AnyClass) {
        if let routerType = aClass as? RouterAware.Type {
            routerType.registerRoutableDestination()
        }
    }
    override class func didFinishAutoRegistration() {
        
    }
}
