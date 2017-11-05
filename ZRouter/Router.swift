
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

///Key of registered protocol.
internal struct _RouteKey<Protocol>: Hashable {
    let type: Protocol
    private let key: String
    init(type: Protocol) {
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

///Router for pure Swift protocol and some swifty convenient methods for ZIKRouter.
public class Router {
    fileprivate static var viewProtocolContainer = [_RouteKey<Any>: DefaultViewRouter.Type]()
    fileprivate static var viewConfigContainer = [_RouteKey<Any>: DefaultViewRouter.Type]()
    fileprivate static var serviceProtocolContainer = [_RouteKey<Any>: DefaultServiceRouter.Type]()
    fileprivate static var serviceConfigContainer = [_RouteKey<Any>: DefaultServiceRouter.Type]()
    
    // MARK: Register
    
    /// Register pure Swift protocol or objc protocol for view with a ZIKViewRouter subclass. Router will check whether the registered view protocol is conformed by the registered view.
    ///
    /// - Parameters:
    ///   - viewProtocol: The protocol conformed by the view of the router. Can be pure Swift protocol or objc protocol.
    ///   - router: The subclass of ZIKViewRouter.
    public static func register(viewProtocol: Any.Type, router: AnyClass) {
        assert(ZIKViewRouter._isLoadFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKViewRouter.self), "This router must be subclass of ZIKViewRouter")
        if ZIKRouter_isObjcProtocol(viewProtocol) {
            (router as! ZIKViewRouter.Type)._swift_registerViewProtocol(viewProtocol)
            return
        }
        assert(viewProtocolContainer[_RouteKey(type:viewProtocol)] == nil, "view protocol (\(viewProtocol)) was already registered with router (\(String(describing: viewProtocolContainer[_RouteKey(type:viewProtocol)]))).")
        
        viewProtocolContainer[_RouteKey(type:viewProtocol)] = (router as! ZIKViewRouter.Type)
    }
    
    /// Register pure Swift protocol or objc protocol for your custom configuration with a ZIKViewRouter subclass. Router will check whether the registered config protocol is conformed by the defaultRouteConfiguration of the router.
    ///
    /// - Parameters:
    ///   - configProtocol: The protocol conformed by the custom configuration of the router. Can be pure Swift protocol or objc protocol.
    ///   - router: The subclass of ZIKViewRouter.
    public static func register<ModuleConfig>(viewModule configProtocol: ModuleConfig.Type, router: AnyClass) {
        assert(ZIKViewRouter._isLoadFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKViewRouter.self), "This router must be subclass of ZIKViewRouter")
        if ZIKRouter_isObjcProtocol(configProtocol) {
            (router as! ZIKViewRouter.Type)._swift_registerConfigProtocol(configProtocol)
            return
        }
        assert((router as! ZIKViewRouter.Type).defaultRouteConfiguration() is ModuleConfig, "The router (\(router))'s default configuration must conform to the config protocol (\(configProtocol)) to register.")
        assert(viewConfigContainer[_RouteKey(type:configProtocol)] == nil, "view config protocol (\(configProtocol)) was already registered with router (\(String(describing: viewConfigContainer[_RouteKey(type:configProtocol)]))).")
        viewConfigContainer[_RouteKey(type:configProtocol)] = (router as! ZIKViewRouter.Type)
    }
    
    /// Register pure Swift protocol or objc protocol for your service with a ZIKServiceRouter subclass. Router will check whether the registered service protocol is conformed by the registered service.
    ///
    /// - Parameters:
    ///   - viewProtocol: The protocol conformed by the custom configuration of the router. Can be pure Swift protocol or objc protocol.
    ///   - router: The subclass of ZIKServiceRouter.
    public static func register(serviceProtocol: Any.Type, router: AnyClass) {
        assert(ZIKServiceRouter._isLoadFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKServiceRouter.self), "This router must be subclass of ZIKServiceRouter")
        if ZIKRouter_isObjcProtocol(serviceProtocol) {
            (router as! ZIKServiceRouter.Type)._swift_registerServiceProtocol(serviceProtocol)
            return
        }
        assert(serviceProtocolContainer[_RouteKey(type:serviceProtocol)] == nil, "service protocol (\(serviceProtocol)) was already registered with router (\(String(describing: serviceProtocolContainer[_RouteKey(type:serviceProtocol)]))).")
        serviceProtocolContainer[_RouteKey(type:serviceProtocol)] = (router as! ZIKServiceRouter.Type)
    }
    
    /// Register pure Swift protocol or objc protocol for your custom configuration with a ZIKServiceRouter subclass.  Router will check whether the registered config protocol is conformed by the defaultRouteConfiguration of the router.
    ///
    /// - Parameters:
    ///   - configProtocol: The protocol conformed by the custom configuration of the router. Can be pure Swift protocol or objc protocol.
    ///   - router: The subclass of ZIKServiceRouter.
    public static func register<ModuleConfig>(serviceModule configProtocol: ModuleConfig.Type, router: AnyClass) {
        assert(ZIKServiceRouter._isLoadFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKServiceRouter.self), "This router must be subclass of ZIKServiceRouter")
        if ZIKRouter_isObjcProtocol(configProtocol) {
            (router as! ZIKServiceRouter.Type)._swift_registerConfigProtocol(configProtocol)
            return
        }
        assert((router as! ZIKServiceRouter.Type).defaultRouteConfiguration() is ModuleConfig, "The router (\(router))'s default configuration must conform to the config protocol (\(configProtocol)) to register.")
        assert(serviceConfigContainer[_RouteKey(type:configProtocol)] == nil, "service config protocol (\(configProtocol)) was already registered with router (\(String(describing: serviceConfigContainer[_RouteKey(type:configProtocol)]))).")
        serviceConfigContainer[_RouteKey(type:configProtocol)] = (router as! ZIKServiceRouter.Type)
    }
}

// MARK: Router Discover
extension Router {
    
    /// Get view router class for registered view protocol.
    ///
    /// - Parameter viewProtocol: The view protocol registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router class for the view protocol.
    public static func router(forViewProtocol viewProtocol:Any.Type) -> DefaultViewRouter.Type? {
        var routerClass = viewProtocolContainer[_RouteKey(type:viewProtocol)]
        if routerClass == nil && ZIKRouter_isObjcProtocol(viewProtocol) {
            routerClass = _swift_ZIKViewRouterForView(viewProtocol) as? ZIKViewRouter.Type
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
    /// - Parameter configProtocol: The cconfg protocol registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router class for the config protocol.
    public static func router(forViewModule configProtocol:Any.Type) -> DefaultViewRouter.Type? {
        var routerClass = viewConfigContainer[_RouteKey(type:configProtocol)]
        if routerClass == nil && ZIKRouter_isObjcProtocol(configProtocol) {
            routerClass = _swift_ZIKViewRouterForModule(configProtocol) as? ZIKViewRouter.Type
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
    /// - Parameter serviceProtocol: The service protocol registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router class for the service protocol.
    public static func router(forServiceProtocol serviceProtocol: Any.Type) -> DefaultServiceRouter.Type? {
        var routerClass = serviceProtocolContainer[_RouteKey(type:serviceProtocol)]
        if routerClass == nil && ZIKRouter_isObjcProtocol(serviceProtocol) {
            routerClass = _swift_ZIKServiceRouterForService(serviceProtocol) as? ZIKServiceRouter.Type
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
    /// - Parameter configProtocol: The cconfg protocol registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The service router class for the config protocol.
    public static func router(forServiceModule configProtocol:Any.Type) -> DefaultServiceRouter.Type? {
        var routerClass = serviceConfigContainer[_RouteKey(type:configProtocol)]
        if routerClass == nil && ZIKRouter_isObjcProtocol(configProtocol) {
            routerClass = _swift_ZIKServiceRouterForModule(configProtocol) as? ZIKServiceRouter.Type
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

// MARK: Convenient - Perform
extension Router {
    
    /// Perform route with view protocol and prepare the destination with the protocol.
    ///
    /// - Parameters:
    ///   - viewProtocol: The view protocol registered with a view router.
    ///   - configure: Configure the configuration for view route.
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The view router.
    internal static func perform<Destination>(
        forViewProtocol viewProtocol:Destination.Type,
        routeConfig configure: (ViewRouteConfig) -> Swift.Void,
        preparation prepare: ((Destination) -> Swift.Void)? = nil
        ) -> DefaultViewRouter? {
        return router(forViewProtocol: viewProtocol)?.perform(configure: { config in
            configure(config)
            config.prepareForRoute = { d in
                if let destination = d as? Destination {
                    prepare?(destination)
                }
            }
        })
    }
    
    /// Perform route with view config protocol and prepare the module with the protocol.
    ///
    /// - Parameters:
    ///   - configProtocol: The config protocol registered with a view router.
    ///   - configure: Configure the configuration for view route.
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The view router.
    internal static func perform<Config>(
        forViewModule configProtocol:Config.Type,
        routeConfig configure: (ViewRouteConfig) -> Swift.Void,
        preparation prepare: ((Config) -> Swift.Void)? = nil
        ) -> DefaultViewRouter? {
        return router(forViewModule: configProtocol)?.perform(configure: { config in
            configure(config)
            if let configuration = config as? Config {
                prepare?(configuration)
            }
        })
    }
    
    /// Perform route with service protocol and prepare the destination with the protocol.
    ///
    /// - Parameters:
    ///   - serviceProtocol: The service protocol registered with a service router.
    ///   - configure: Configure the configuration for service route.
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The service router.
    internal static func perform<Destination>(
        forServiceProtocol serviceProtocol:Destination.Type,
        routeConfig configure: (ServiceRouteConfig) -> Swift.Void,
        preparation prepare: ((Destination) -> Swift.Void)? = nil
        ) -> DefaultServiceRouter? {
        return router(forServiceProtocol: serviceProtocol)?.perform(configure: { config in
            configure(config)
            config.prepareForRoute = { d in
                if let destination = d as? Destination {
                    prepare?(destination)
                }
            }
        })
    }
    
    /// Perform route with service module config protocol and prepare the module with the protocol.
    ///
    /// - Parameters:
    ///   - configProtocol: The module config protocol registered with a service router.
    ///   - configure: Configure the configuration for service route.
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The service router.
    internal static func perform<Module>(
        forServiceModule configProtocol:Module.Type,
        routeConfig configure: (ServiceRouteConfig) -> Swift.Void,
        preparation prepare: ((Module) -> Swift.Void)? = nil
        ) -> DefaultServiceRouter? {
        return router(forServiceModule: configProtocol)?.perform(configure: { config in
            configure(config)
            if let configuration = config as? Module {
                prepare?(configuration)
            }
        })
    }
}

// MARK: Convenient - Destination
extension Router {
    
    /// Get view destination conforming the view protocol.
    ///
    /// - Parameters:
    ///   - viewProtocol: The view protocol registered with a view router.
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The view destination.
    internal static func makeDestination<Destination>(
        forViewProtocol viewProtocol:Destination.Type,
        preparation prepare: ((Destination) -> Swift.Void)? = nil
        ) -> Destination? {
        var destination: Destination?
        let routerClass = router(forViewProtocol: viewProtocol)
        assert((routerClass?.completeSynchronously())!,"router class (\(String(describing: routerClass))) can't get destination synchronously.")
        routerClass?.perform(configure: { config in
            config.routeType = ViewRouteType.getDestination
            config.prepareForRoute = { d in
                if let destination = d as? Destination {
                    prepare?(destination)
                }
            }
            config.routeCompletion = { d in
                assert(d is Destination,"Bad implementation in router(\(String(describing: routerClass))), destination(\(type(of: d))) is not \(Destination.self) type.")
                destination = d as? Destination
            }
        })
        return destination
    }
    
    /// Get view destination with view config protocol.
    ///
    /// - Parameters:
    ///   - configProtocol: The config protocol registered with a view router.
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The view destination.
    internal static func makeDestination<Module>(
        forViewModule configProtocol:Module.Type,
        preparation prepare: ((Module) -> Swift.Void)? = nil
        ) -> Any? {
        var destination: Any?
        let routerClass = router(forViewModule: configProtocol)
        assert((routerClass?.completeSynchronously())!,"router class (\(String(describing: routerClass))) can't get destination synchronously")
        routerClass?.perform(configure: { config in
            config.routeType = ViewRouteType.getDestination
            if config is Module {
                prepare?(config as! Module)
            }
            config.routeCompletion = { d in
                destination = d
            }
        })
        return destination
    }
    
    /// Get service destination conforming the service protocol.
    ///
    /// - Parameters:
    ///   - serviceProtocol: The service protocol registered with a service router.
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The service destination.
    internal static func makeDestination<Destination>(
        forServiceProtocol serviceProtocol:Destination.Type,
        preparation prepare: ((Destination) -> Swift.Void)? = nil
        ) -> Destination? {
        var destination: Destination?
        let routerClass = router(forServiceProtocol: serviceProtocol)
        assert((routerClass?.completeSynchronously())!,"router class (\(String(describing: routerClass))) can't get destination synchronously")
        routerClass?.perform(configure: { config in
            config.prepareForRoute = { d in
                if let destination = d as? Destination {
                    prepare?(destination)
                }
            }
            config.routeCompletion = { d in
                assert(d is Destination,"Bad implementation in router(\(String(describing: routerClass))), destination(\(type(of: d))) is not \(Destination.self) type.")
                destination = d as? Destination
            }
        })
        return destination
    }
    
    /// Get service destination with service config protocol.
    ///
    /// - Parameters:
    ///   - configProtocol: The config protocol registered with a service router.
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The service destination.
    internal static func makeDestination<Config>(
        forServiceModule configProtocol:Config.Type,
        preparation prepare: ((Config) -> Swift.Void)? = nil
        ) -> Any? {
        var destination: Any?
        let routerClass = router(forServiceModule: configProtocol)
        assert((routerClass?.completeSynchronously())!,"router class (\(String(describing: routerClass))) can't get destination synchronously")
        routerClass?.perform(configure: { config in
            if config is Config {
                prepare?(config as! Config)
            }
            config.routeCompletion = { d in
                destination = d
            }
        })
        return destination
    }
}

///Make sure registered view class conforms to registered view protocol.
private class _ViewRouterValidater: ZIKViewRouteAdapter {
    static var observer: Any?
    override class func registerRoutableDestination() {
        observer = NotificationCenter.default.addObserver(forName: Notification.Name.zikViewRouterRegisterComplete, object: nil, queue: OperationQueue.main) { _ in
            NotificationCenter.default.removeObserver(observer!)
            validateViewRouters()
        }
    }
    class func validateViewRouters() {
        for (routeKey, routerClass) in Router.viewProtocolContainer {
            let viewProtocol = routeKey.type
            assert(routerClass.validateRegisteredViewClasses({return _swift_typeConformsToProtocol($0, viewProtocol)}) == nil,
                   "Registered view class(\(String(describing: routerClass.validateRegisteredViewClasses{return _swift_typeConformsToProtocol($0, viewProtocol)}!))) for router \(routerClass) should conform to protocol \(viewProtocol)")
        }
    }
}

///Make sure registered service class conforms to registered service protocol.
private class _ServiceRouterValidater: ZIKServiceRouteAdapter {
    static var observer: Any?
    override class func registerRoutableDestination() {
        observer = NotificationCenter.default.addObserver(forName: Notification.Name.zikServiceRouterRegisterComplete, object: nil, queue: OperationQueue.main) { _ in
            NotificationCenter.default.removeObserver(observer!)
            validateServiceRouters()
        }
    }
    class func validateServiceRouters() {
        for (routeKey, routerClass) in Router.serviceProtocolContainer {
            let serviceProtocol = routeKey.type
            assert(routerClass.validateRegisteredServiceClasses({return _swift_typeConformsToProtocol($0, serviceProtocol)}) == nil,
                   "Registered service class(\(String(describing: routerClass.validateRegisteredServiceClasses{return _swift_typeConformsToProtocol($0, serviceProtocol)}!))) for router \(routerClass) should conform to protocol \(serviceProtocol)")
        }
    }
}
