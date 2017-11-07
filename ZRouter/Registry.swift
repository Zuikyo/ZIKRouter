
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

internal let shouldCheckViewRouter = ZIKViewRouter.shouldCheckImplementation()
internal let shouldCheckServiceRouter = ZIKServiceRouter.shouldCheckImplementation()

///Key of registered protocol.
internal struct _RouteKey<Type>: Hashable {
    fileprivate let type: Type
    private let key: String
    init(type: Type) {
        self.type = type
        key = String(describing:type)
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
    fileprivate static var viewProtocolContainer = [_RouteKey<Any>: DefaultViewRouter.Type]()
    fileprivate static var viewConfigContainer = [_RouteKey<Any>: DefaultViewRouter.Type]()
    fileprivate static var serviceProtocolContainer = [_RouteKey<Any>: DefaultServiceRouter.Type]()
    fileprivate static var serviceConfigContainer = [_RouteKey<Any>: DefaultServiceRouter.Type]()
    fileprivate static var _check_viewProtocolContainer = [_RouteKey<Any>: Set<_RouteKey<Any>>]()
    fileprivate static var _check_serviceProtocolContainer = [_RouteKey<Any>: Set<_RouteKey<Any>>]()
    
    // MARK: Register
    
    /// Register pure Swift protocol or objc protocol for view with a ZIKViewRouter subclass. Router will check whether the registered view protocol is conformed by the registered view.
    ///
    /// - Parameters:
    ///   - routableView: A routabe entry carrying a protocol conformed by the view of the router. Can be pure Swift protocol or objc protocol.
    ///   - router: The subclass of ZIKViewRouter.
    public static func register<Protocol>(_ routableView: RoutableView<Protocol>, forRouter router: AnyClass) {
        let viewProtocol = Protocol.self
        assert(ZIKViewRouter._isLoadFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKViewRouter.self), "This router must be subclass of ZIKViewRouter")
        if ZIKRouter_isObjcProtocol(viewProtocol) {
            (router as! ZIKViewRouter.Type)._swift_registerViewProtocol(viewProtocol)
            return
        }
        assert(viewProtocolContainer[_RouteKey(type:viewProtocol)] == nil, "view protocol (\(viewProtocol)) was already registered with router (\(String(describing: viewProtocolContainer[_RouteKey(type:viewProtocol)]))).")
        if shouldCheckViewRouter {
            _add(viewProtocol: viewProtocol, toRouter: router as! DefaultViewRouter.Type)
        }
        viewProtocolContainer[_RouteKey(type:viewProtocol)] = (router as! ZIKViewRouter.Type)
    }
    
    /// Register pure Swift protocol or objc protocol for your custom configuration with a ZIKViewRouter subclass. Router will check whether the registered config protocol is conformed by the defaultRouteConfiguration of the router.
    ///
    /// - Parameters:
    ///   - routableViewModule: A routabe entry carrying a protocol conformed by the custom configuration of the router. Can be pure Swift protocol or objc protocol.
    ///   - router: The subclass of ZIKViewRouter.
    public static func register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>, forRouter router: AnyClass) {
        let configProtocol = Protocol.self
        assert(ZIKViewRouter._isLoadFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKViewRouter.self), "This router must be subclass of ZIKViewRouter")
        if ZIKRouter_isObjcProtocol(configProtocol) {
            (router as! ZIKViewRouter.Type)._swift_registerConfigProtocol(configProtocol)
            return
        }
        assert((router as! ZIKViewRouter.Type).defaultRouteConfiguration() is Protocol, "The router (\(router))'s default configuration must conform to the config protocol (\(configProtocol)) to register.")
        assert(viewConfigContainer[_RouteKey(type:configProtocol)] == nil, "view config protocol (\(configProtocol)) was already registered with router (\(String(describing: viewConfigContainer[_RouteKey(type:configProtocol)]))).")
        viewConfigContainer[_RouteKey(type:configProtocol)] = (router as! ZIKViewRouter.Type)
    }
    
    /// Register pure Swift protocol or objc protocol for your service with a ZIKServiceRouter subclass. Router will check whether the registered service protocol is conformed by the registered service.
    ///
    /// - Parameters:
    ///   - routableService: A routabe entry carrying a protocol conformed by the custom configuration of the router. Can be pure Swift protocol or objc protocol.
    ///   - router: The subclass of ZIKServiceRouter.
    public static func register<Protocol>(_ routableService: RoutableService<Protocol>, forRouter router: AnyClass) {
        let serviceProtocol = Protocol.self
        assert(ZIKServiceRouter._isLoadFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKServiceRouter.self), "This router must be subclass of ZIKServiceRouter")
        if ZIKRouter_isObjcProtocol(serviceProtocol) {
            (router as! ZIKServiceRouter.Type)._swift_registerServiceProtocol(serviceProtocol)
            return
        }
        assert(serviceProtocolContainer[_RouteKey(type:serviceProtocol)] == nil, "service protocol (\(serviceProtocol)) was already registered with router (\(String(describing: serviceProtocolContainer[_RouteKey(type:serviceProtocol)]))).")
        if shouldCheckServiceRouter {
            _add(serviceProtocol: serviceProtocol, toRouter: router as! DefaultServiceRouter.Type)
        }
        serviceProtocolContainer[_RouteKey(type:serviceProtocol)] = (router as! ZIKServiceRouter.Type)
    }
    
    /// Register pure Swift protocol or objc protocol for your custom configuration with a ZIKServiceRouter subclass.  Router will check whether the registered config protocol is conformed by the defaultRouteConfiguration of the router.
    ///
    /// - Parameters:
    ///   - routableServiceModule: A routabe entry carrying a module config protocol conformed by the custom configuration of the router. Can be pure Swift protocol or objc protocol.
    ///   - router: The subclass of ZIKServiceRouter.
    public static func register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>, forRouter router: AnyClass) {
        let configProtocol = Protocol.self
        assert(ZIKServiceRouter._isLoadFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKServiceRouter.self), "This router must be subclass of ZIKServiceRouter")
        if ZIKRouter_isObjcProtocol(configProtocol) {
            (router as! ZIKServiceRouter.Type)._swift_registerConfigProtocol(configProtocol)
            return
        }
        assert((router as! ZIKServiceRouter.Type).defaultRouteConfiguration() is Protocol, "The router (\(router))'s default configuration must conform to the config protocol (\(configProtocol)) to register.")
        assert(serviceConfigContainer[_RouteKey(type:configProtocol)] == nil, "service config protocol (\(configProtocol)) was already registered with router (\(String(describing: serviceConfigContainer[_RouteKey(type:configProtocol)]))).")
        serviceConfigContainer[_RouteKey(type:configProtocol)] = (router as! ZIKServiceRouter.Type)
    }
    
    
    private static func _add(viewProtocol: Any.Type, toRouter router: DefaultViewRouter.Type) {
        var protocols = _check_viewProtocolContainer[_RouteKey(type: router.self)]
        if protocols == nil {
            protocols = Set()
            protocols?.insert(_RouteKey(type:viewProtocol))
        } else {
            protocols?.insert(_RouteKey(type:viewProtocol))
        }
        _check_viewProtocolContainer[_RouteKey(type: router.self)] = protocols
    }
    
    
    private static func _add(serviceProtocol: Any.Type, toRouter router: DefaultServiceRouter.Type) {
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

// MARK: Router Discover
extension Registry {
    
    /// Get view router class for registered view protocol.
    ///
    /// - Parameter routableView: A routabe entry carrying a view protocol conformed by the view registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router class for the view protocol.
    public static func router<Protocol>(to routableView: RoutableView<Protocol>) -> DefaultViewRouter.Type? {
        let viewProtocol = Protocol.self
        var routerClass = viewProtocolContainer[_RouteKey(type:viewProtocol)]
        if routerClass == nil && ZIKRouter_isObjcProtocol(viewProtocol) {
            routerClass = _swift_ZIKViewRouterToView(viewProtocol) as? ZIKViewRouter.Type
        }
        if routerClass == nil && !ZIKRouter_isObjcProtocol(viewProtocol) {
            ZIKViewRouter._callbackGlobalErrorHandler(with: nil,
                                                      action: #selector(DefaultViewRouter.init(configuration:remove:)),
                                                      error: ZIKViewRouter.error(withCode:ZIKViewRouteError.invalidProtocol.rawValue,
                                                      localizedDescription:"Swift view protocol (\(viewProtocol)) was not registered with any view router."))
            assertionFailure("Swift view protocol (\(viewProtocol)) was not registered with any view router.")
        }
        return routerClass
    }
    
    /// Get view router class for registered config protocol.
    ///
    /// - Parameter routableViewModule: A routabe entry carrying a view module config protocol registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router class for the config protocol.
    public static func router<Protocol>(to routableViewModule: RoutableViewModule<Protocol>) -> DefaultViewRouter.Type? {
        let configProtocol = Protocol.self
        var routerClass = viewConfigContainer[_RouteKey(type:configProtocol)]
        if routerClass == nil && ZIKRouter_isObjcProtocol(configProtocol) {
            routerClass = _swift_ZIKViewRouterToModule(configProtocol) as? ZIKViewRouter.Type
        }
        if routerClass == nil && !ZIKRouter_isObjcProtocol(configProtocol) {
            ZIKViewRouter._callbackGlobalErrorHandler(with: nil,
                                                      action: #selector(DefaultViewRouter.init(configuration:remove:)),
                                                      error: ZIKViewRouter.error(withCode:ZIKViewRouteError.invalidProtocol.rawValue,
                                                                                 localizedDescription:"Swift module config protocol (\(configProtocol)) was not registered with any view router."))
            assertionFailure("Swift module config protocol (\(configProtocol)) was not registered with any view router.")
        }
        return routerClass
    }
    
    /// Get service router class for registered service protocol.
    ///
    /// - Parameter routableService: A routabe entry carrying a service protocol conformed by the service registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router class for the service protocol.
    public static func router<Protocol>(to routableService: RoutableService<Protocol>) -> DefaultServiceRouter.Type? {
        let serviceProtocol = Protocol.self
        var routerClass = serviceProtocolContainer[_RouteKey(type:serviceProtocol)]
        if routerClass == nil && ZIKRouter_isObjcProtocol(serviceProtocol) {
            routerClass = _swift_ZIKServiceRouterToService(serviceProtocol) as? ZIKServiceRouter.Type
        }
        if routerClass == nil && !ZIKRouter_isObjcProtocol(serviceProtocol) {
            ZIKViewRouter._callbackGlobalErrorHandler(with: nil,
                                                      action: #selector(DefaultViewRouter.init(configuration:remove:)),
                                                      error: ZIKViewRouter.error(withCode:ZIKViewRouteError.invalidProtocol.rawValue,
                                                                                 localizedDescription:"Swift service protocol (\(serviceProtocol)) was not registered with any service router."))
            assertionFailure("Swift service protocol (\(serviceProtocol)) was not registered with any service router.")
        }
        return routerClass
    }
    
    /// Get service router class for registered config protocol.
    ///
    /// - Parameter routableServiceModule: A routabe entry carrying a cconfg protocol registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The service router class for the config protocol.
    public static func router<Protocol>(to routableServiceModule: RoutableServiceModule<Protocol>) -> DefaultServiceRouter.Type? {
        let configProtocol = Protocol.self
        var routerClass = serviceConfigContainer[_RouteKey(type:configProtocol)]
        if routerClass == nil && ZIKRouter_isObjcProtocol(configProtocol) {
            routerClass = _swift_ZIKServiceRouterToModule(configProtocol) as? ZIKServiceRouter.Type
        }
        if routerClass == nil && !ZIKRouter_isObjcProtocol(configProtocol) {
            ZIKViewRouter._callbackGlobalErrorHandler(with: nil,
                                                      action: #selector(DefaultViewRouter.init(configuration:remove:)),
                                                      error: ZIKViewRouter.error(withCode:ZIKViewRouteError.invalidProtocol.rawValue,
                                                                                 localizedDescription:"Swift module config protocol (\(configProtocol)) was not registered with any service router."))
            assertionFailure("Swift module config protocol (\(configProtocol)) was not registered with any service router.")
        }
        return routerClass
    }
}

// MARK: Validate
internal extension Registry {
    internal class func validateConformance(destination: Any, inViewRouter router: DefaultViewRouter) -> Bool {
        let protocols = _check_viewProtocolContainer[_RouteKey(type: type(of: router))]
        if protocols != nil {
            for viewProtocol in protocols! {
                assert(_swift_typeConformsToProtocol(type(of: destination), viewProtocol))
                if _swift_typeConformsToProtocol(type(of: destination), viewProtocol) == false {
                    return false
                }
            }
        }
        return true
    }
    internal class func validateConformance(destination: Any, inServiceRouter router: DefaultServiceRouter) -> Bool {
        let protocols = _check_serviceProtocolContainer[_RouteKey(type: type(of: router))]
        if protocols != nil {
            for serviceProtocolEntry in protocols! {
                assert(_swift_typeConformsToProtocol(type(of: destination), serviceProtocolEntry.type), "Bad implementation in router (\(type(of: router)))'s destination(with configuration:), the destination (\(destination)) doesn't conforms to registered service protocol (\(serviceProtocolEntry.type))")
                if _swift_typeConformsToProtocol(type(of: destination), serviceProtocolEntry.type) == false {
                    return false
                }
            }
        }
        return true
    }
}

///Make sure all registered view classes conform to their registered view protocols.
private class _ViewRouterValidater: ZIKViewRouteAdapter {
    static var observer: Any?
    override class func registerRoutableDestination() {
        if shouldCheckViewRouter {
            observer = NotificationCenter.default.addObserver(forName: Notification.Name.zikViewRouterRegisterComplete, object: nil, queue: OperationQueue.main) { _ in
                NotificationCenter.default.removeObserver(observer!)
                validateViewRouters()
            }
        }
    }
    class func validateViewRouters() {
        for (routeKey, routerClass) in Registry.viewProtocolContainer {
            let viewProtocol = routeKey.type
            assert(routerClass.validateRegisteredViewClasses({return _swift_typeConformsToProtocol($0, viewProtocol)}) == nil,
                   "Registered view class (\(String(describing: routerClass.validateRegisteredViewClasses{return _swift_typeConformsToProtocol($0, viewProtocol)}!))) for router (\(routerClass)) should conform to registered view protocol (\(viewProtocol)).")
        }
    }
}

///Make sure all registered service classes conform to their registered service protocols.
private class _ServiceRouterValidater: ZIKServiceRouteAdapter {
    static var observer: Any?
    override class func registerRoutableDestination() {
        if shouldCheckServiceRouter {
            observer = NotificationCenter.default.addObserver(forName: Notification.Name.zikServiceRouterRegisterComplete, object: nil, queue: OperationQueue.main) { _ in
                NotificationCenter.default.removeObserver(observer!)
                validateServiceRouters()
            }
        }
    }
    class func validateServiceRouters() {
        for (routeKey, routerClass) in Registry.serviceProtocolContainer {
            let serviceProtocol = routeKey.type
            assert(routerClass.validateRegisteredServiceClasses({return _swift_typeConformsToProtocol($0, serviceProtocol)}) == nil,
                   "Registered service class (\(String(describing: routerClass.validateRegisteredServiceClasses{return _swift_typeConformsToProtocol($0, serviceProtocol)}!))) for router (\(routerClass)) should conform to registered service protocol (\(serviceProtocol)).")
        }
    }
}
