//
//  Router.swift
//  ZIKRouterSwift
//
//  Created by zuik on 2017/10/16.
//  Copyright © 2017 zuik. All rights reserved.
//

import ZIKRouter.Internal
import ZIKRouter.Private

internal struct RouteKey: Hashable {
    let key: String
    var hashValue: Int {
        return key.hashValue
    }
    static func ==(lhs: RouteKey, rhs: RouteKey) -> Bool {
        return lhs.key == rhs.key
    }
}

/// Router for pure Swift protocol and some convenient methods for ZIKRouter.
public class Router {
    private static var viewProtocolContainer = [RouteKey: ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>.Type]()
    private static var viewConfigContainer = [RouteKey: ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>.Type]()
    private static var serviceProtocolContainer = [RouteKey: ZIKServiceRouter<ZIKServiceRouteConfiguration, ZIKRouteConfiguration>.Type]()
    private static var serviceConfigContainer = [RouteKey: ZIKServiceRouter<ZIKServiceRouteConfiguration, ZIKRouteConfiguration>.Type]()
    
    // MARK: Register
    
    /// Register pure Swift protocol for view with a ZIKViewRouter subclass
    ///
    /// - Note: This function is only for pure Swift protocol. If you want to register objc protocol, use +[ZIKViewRouter registerViewProtocol:].
    ///
    /// In Swift we won't check whether the view protocol you register is conformed by the view of the router, unless we instantiate the destination everytime. You are responsible for checking the protocol. If you need to check, use +[ZIKViewRouter registerViewProtocol:] with objc protocol.
    ///
    /// - Parameters:
    ///   - viewProtocol: The protocol conformed by the view of the router
    ///   - router: The subclass of ZIKViewRouter
    public static func register(viewProtocol: Any.Type, router: AnyClass) {
        assert(ZIKViewRouter._isLoadFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert((ZIKRouter_isObjcProtocol(viewProtocol)) == false, "This function is only for pure Swift protocol, \(viewProtocol) is objc protocol. Use +[ZIKViewRouter registerViewProtocol:] to register objc protocol.")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKViewRouter.self), "This router must be subclass of ZIKViewRouter")
        assert(viewProtocolContainer[RouteKey(key:String(describing:viewProtocol))] == nil, "view protocol (\(viewProtocol)) was already registered with router (\(String(describing: viewProtocolContainer[RouteKey(key:String(describing:viewProtocol))]))).")
        viewProtocolContainer[RouteKey(key:String(describing:viewProtocol))] = (router as! ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>.Type)
    }
    
    /// Register pure Swift protocol for your custom configuration with a ZIKViewRouter subclass
    ///
    /// - Note: This function is only for pure Swift protocol. If you want to register objc protocol, use +[ZIKViewRouter registerConfigProtocol:].
    ///
    /// - Parameters:
    ///   - configProtocol: The protocol conformed by the custom configuration of the router
    ///   - router: The subclass of ZIKViewRouter
    public static func register<Config>(viewConfig configProtocol: Config.Type, router: AnyClass) {
        assert(ZIKViewRouter._isLoadFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert((ZIKRouter_isObjcProtocol(configProtocol)) == false, "This function is only for pure Swift protocol, \(configProtocol) is objc protocol. Use +[ZIKViewRouter registerConfigProtocol:] to register objc protocol.")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKViewRouter.self), "This router must be subclass of ZIKViewRouter")
        assert((router as! ZIKViewRouter.Type).defaultRouteConfiguration() is Config, "The router (\(router))'s default configuration must conform to the config protocol (\(configProtocol)) to register.")
        assert(viewConfigContainer[RouteKey(key:String(describing:configProtocol))] == nil, "view config protocol (\(configProtocol)) was already registered with router (\(String(describing: viewConfigContainer[RouteKey(key:String(describing:configProtocol))]))).")
        viewConfigContainer[RouteKey(key:String(describing:configProtocol))] = (router as! ZIKViewRouter.Type)
    }
    
    /// Register pure Swift protocol for your service with a ZIKServiceRouter subclass
    ///
    /// - Note: This function is only for pure Swift protocol. If you want to register objc protocol, use +[ZIKServiceRouter registerServiceProtocol:].
    ///
    /// In Swift we won't check whether the service protocol you register is conformed by the service of the router, unless we instantiate the destination everytime. You are responsible for checking the protocol. If you need to check, use +[ZIKServiceRouter registerServiceProtocol:] with objc protocol.
    ///
    /// - Parameters:
    ///   - viewProtocol: The protocol conformed by the custom configuration of the router
    ///   - router: The subclass of ZIKServiceRouter
    public static func register(serviceProtocol: Any.Type, router: AnyClass) {
        assert(ZIKServiceRouter._isLoadFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert((ZIKRouter_isObjcProtocol(serviceProtocol)) == false, "This function is only for pure Swift protocol, \(serviceProtocol) is objc protocol. Use +[ZIKServiceRouter registerServiceProtocol:] to register objc protocol.")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKServiceRouter.self), "This router must be subclass of ZIKServiceRouter")
        assert(serviceProtocolContainer[RouteKey(key:String(describing:serviceProtocol))] == nil, "service protocol (\(serviceProtocol)) was already registered with router (\(String(describing: serviceProtocolContainer[RouteKey(key:String(describing:serviceProtocol))]))).")
        serviceProtocolContainer[RouteKey(key:String(describing:serviceProtocol))] = (router as! ZIKServiceRouter.Type)
    }
    
    /// Register pure Swift protocol for your custom configuration with a ZIKServiceRouter subclass
    ///
    /// - Note: This function is only for pure Swift protocol. If you want to register objc protocol, use +[ZIKServiceRouter registerConfigProtocol:].
    ///
    /// - Parameters:
    ///   - configProtocol: The protocol conformed by the custom configuration of the router
    ///   - router: The subclass of ZIKServiceRouter
    public static func register<Config>(serviceConfig configProtocol: Config.Type, router: AnyClass) {
        assert(ZIKServiceRouter._isLoadFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert((ZIKRouter_isObjcProtocol(configProtocol)) == false, "This function is only for pure Swift protocol, \(configProtocol) is objc protocol. Use +[ZIKServiceRouter registerConfigProtocol:] to register objc protocol.")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKServiceRouter.self), "This router must be subclass of ZIKServiceRouter")
        assert((router as! ZIKServiceRouter.Type).defaultRouteConfiguration() is Config, "The router (\(router))'s default configuration must conform to the config protocol (\(configProtocol)) to register.")
        assert(serviceConfigContainer[RouteKey(key:String(describing:configProtocol))] == nil, "service config protocol (\(configProtocol)) was already registered with router (\(String(describing: serviceConfigContainer[RouteKey(key:String(describing:configProtocol))]))).")
        serviceConfigContainer[RouteKey(key:String(describing:configProtocol))] = (router as! ZIKServiceRouter.Type)
    }
    
    // MARK: Router Discover
    
    /// Get view router class for registered view protocol
    ///
    /// - Parameter viewProtocol: The view protocol registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router class for the view protocol
    public static func router(forViewProtocol viewProtocol:Any.Type) -> ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>.Type? {
        var routerClass = viewProtocolContainer[RouteKey(key:String(describing:viewProtocol))]
        if routerClass == nil && ZIKRouter_isObjcProtocol(viewProtocol) {
            routerClass = _Swift_ZIKViewRouterForView(viewProtocol) as? ZIKViewRouter.Type
        }
        return routerClass
    }
    
    /// Get view router class for registered config protocol
    ///
    /// - Parameter configProtocol: The cconfg protocol registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router class for the config protocol
    public static func router(forViewConfig configProtocol:Any.Type) -> ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>.Type? {
        var routerClass = viewConfigContainer[RouteKey(key:String(describing:configProtocol))]
        if routerClass == nil && ZIKRouter_isObjcProtocol(configProtocol) {
            routerClass = _Swift_ZIKViewRouterForConfig(configProtocol) as? ZIKViewRouter.Type
        }
        return routerClass
    }
    
    /// Get service router class for registered service protocol
    ///
    /// - Parameter serviceProtocol: The service protocol registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router class for the service protocol
    public static func router(forServiceProtocol serviceProtocol: Any.Type) -> ZIKServiceRouter<ZIKServiceRouteConfiguration, ZIKRouteConfiguration>.Type? {
        var routerClass = serviceProtocolContainer[RouteKey(key:String(describing:serviceProtocol))]
        if routerClass == nil && ZIKRouter_isObjcProtocol(serviceProtocol) {
            routerClass = _Swift_ZIKServiceRouterForService(serviceProtocol) as? ZIKServiceRouter<ZIKServiceRouteConfiguration, ZIKRouteConfiguration>.Type
        }
        return routerClass
    }
    
    /// Get service router class for registered config protocol
    ///
    /// - Parameter configProtocol: The cconfg protocol registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The service router class for the config protocol
    public static func router(forServiceConfig configProtocol:Any.Type) -> ZIKServiceRouter<ZIKServiceRouteConfiguration, ZIKRouteConfiguration>.Type? {
        var routerClass = serviceConfigContainer[RouteKey(key:String(describing:configProtocol))]
        if routerClass == nil && ZIKRouter_isObjcProtocol(configProtocol) {
            routerClass = _Swift_ZIKServiceRouterForConfig(configProtocol) as? ZIKServiceRouter.Type
        }
        return routerClass
    }
    
    // MARK: Convenient - Perform
    
    /// Perform route with view protocol and prepare the destination with the protocol
    ///
    /// - Parameters:
    ///   - viewProtocol: The view protocol registered with a view router
    ///   - option: Options for view route
    ///   - prepare: Prepare the destination with the protocol
    /// - Returns: The view router
    public static func perform<Destination>(
        forViewProtocol viewProtocol:Destination.Type,
        routeOption option: (ZIKViewRouteConfiguration) -> Swift.Void,
        preparation prepare: ((Destination?) -> Swift.Void)? = nil
        ) -> ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>? {
        return self.router(forViewProtocol: viewProtocol)?.perform(configure: { (config) in
            option(config)
            config.prepareForRoute = { d in
                prepare?(d as? Destination)
            }
        })
    }
    
    /// Perform route with view config protocol and prepare the module with the protocol
    ///
    /// - Parameters:
    ///   - configProtocol: The config protocol registered with a view router
    ///   - option: Options for view route
    ///   - prepare: Prepare the module with the protocol
    /// - Returns: The view router
    public static func perform<Config>(
        forViewConfig configProtocol:Config.Type,
        routeOption option: (ZIKViewRouteConfiguration) -> Swift.Void,
        preparation prepare: ((Config?) -> Swift.Void)? = nil
        ) -> ZIKViewRouter<ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration>? {
        return self.router(forViewConfig: configProtocol)?.perform(configure: { (config) in
            option(config)
            prepare?(config as? Config)
        })
    }
    
    // MARK: Convenient - Destination
    
    /// Get view destination conforming the view protocol
    ///
    /// - Parameters:
    ///   - viewProtocol: The view protocol registered with a view router
    ///   - prepare: Prepare the destination with the protocol
    /// - Returns: The view destination
    public static func makeDestination<Destination>(
        forViewProtocol viewProtocol:Destination.Type,
        preparation prepare: ((Destination?) -> Swift.Void)? = nil
        ) -> Destination? {
        var destination: Destination?
        let routerClass = self.router(forViewProtocol: viewProtocol)
        assert((routerClass?.completeSynchronously())!,"router class (\(String(describing: routerClass))) can't get destination synchronously")
        routerClass?.perform(configure: { (config) in
            config.routeType = ZIKViewRouteType.getDestination
            config.prepareForRoute = { d in
                let destination = d as? Destination
                prepare?(destination)
            }
            config.routeCompletion = { d in
                assert(d is Destination,"Bad implementation in router(\(String(describing: routerClass))), destination(\(type(of: d))) is not \(Destination.self) type.")
                destination = d as? Destination
            }
        })
        return destination
    }
    
    /// Get view destination with view config protocol
    ///
    /// - Parameters:
    ///   - configProtocol: The config protocol registered with a view router
    ///   - prepare: Prepare the module with the protocol
    /// - Returns: The view destination
    public static func makeDestination<Config>(
        forViewConfig configProtocol:Config.Type,
        preparation prepare: ((Config?) -> Swift.Void)? = nil
        ) -> Any? {
        var destination: Any?
        let routerClass = self.router(forViewConfig: configProtocol)
        assert((routerClass?.completeSynchronously())!,"router class (\(String(describing: routerClass))) can't get destination synchronously")
        routerClass?.perform(configure: { (config) in
            config.routeType = ZIKViewRouteType.getDestination
            if config is Config {
                prepare?(config as? Config)
            }
            config.routeCompletion = { d in
                destination = d
            }
        })
        return destination
    }
    
    /// Get service destination conforming the service protocol
    ///
    /// - Parameters:
    ///   - serviceProtocol: The service protocol registered with a service router
    ///   - prepare: Prepare the destination with the protocol
    /// - Returns: The service destination
    public static func makeDestination<Destination>(
        forServiceProtocol serviceProtocol:Destination.Type,
        preparation prepare: ((Destination?) -> Swift.Void)? = nil
        ) -> Destination? {
        var destination: Destination?
        let routerClass = self.router(forServiceProtocol: serviceProtocol)
        assert((routerClass?.completeSynchronously())!,"router class (\(String(describing: routerClass))) can't get destination synchronously")
        routerClass?.perform(configure: { (config) in
            config.prepareForRoute = { d in
                prepare?(d as? Destination)
            }
            config.routeCompletion = { d in
                assert(d is Destination,"Bad implementation in router(\(String(describing: routerClass))), destination(\(type(of: d))) is not \(Destination.self) type.")
                destination = d as? Destination
            }
        })
        return destination
    }
    
    /// Get service destination with service config protocol
    ///
    /// - Parameters:
    ///   - configProtocol: The config protocol registered with a service router
    ///   - prepare: Prepare the module with the protocol
    /// - Returns: The service destination
    public static func makeDestination<Config>(
        forServiceConfig configProtocol:Config.Type,
        preparation prepare: ((Config?) -> Swift.Void)? = nil
        ) -> Any? {
        var destination: Any?
        let routerClass = self.router(forServiceConfig: configProtocol)
        assert((routerClass?.completeSynchronously())!,"router class (\(String(describing: routerClass))) can't get destination synchronously")
        routerClass?.perform(configure: { (config) in
            if config is Config {
                prepare?(config as? Config)
            }
            config.routeCompletion = { d in
                destination = d
            }
        })
        return destination
    }
}
