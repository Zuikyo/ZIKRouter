
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

extension Protocol {
    var name: String {
        var name = NSStringFromProtocol(self)
        if let dotRange = name.range(of: ".") {
            name.removeSubrange(name.startIndex...dotRange.lowerBound)
        }
        return name
    }
}

/// Key of registered protocol.
internal struct _RouteKey: Hashable {
    #if DEBUG
    /// Routable type
    fileprivate let type: Any.Type?
    #endif
    fileprivate let key: String
    fileprivate init(type: Any.Type, name: String) {
        assert(name == String(describing: type), "name should be equal to String(describing:) of \(type)")
        #if DEBUG
        self.type = type
        #endif
        key = name
        assert(key.contains(".") == false, "Key shouldn't contain module prefix.")
    }
    fileprivate init(protocol p: Protocol) {
        #if DEBUG
        self.type = nil
        #endif
        key = p.name
        assert(key.contains(".") == false, "Remove module prefix for swift type.")
    }
    fileprivate init<Protocol>(routable: RoutableView<Protocol>) {
        self.init(type: Protocol.self, name: routable.typeName)
    }
    fileprivate init<Protocol>(routable: RoutableViewModule<Protocol>) {
        self.init(type: Protocol.self, name: routable.typeName)
    }
    fileprivate init<Protocol>(routable: RoutableService<Protocol>) {
        self.init(type: Protocol.self, name: routable.typeName)
    }
    fileprivate init<Protocol>(routable: RoutableServiceModule<Protocol>) {
        self.init(type: Protocol.self, name: routable.typeName)
    }
    #if DEBUG
    fileprivate init(type: AnyClass) {
        self.type = type
        key = String(describing:type)
        assert(key.contains(".") == false, "Key shouldn't contain module prefix.")
    }
    fileprivate init(route: Any) {
        self.type = nil
        key = String(describing:route)
    }
    /// Used for checking declared protocol names.
    fileprivate init(key: String) {
        type = nil
        self.key = key
        assert(key.contains(".") == false, "Remove module prefix for swift type.")
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
    #endif
    var hashValue: Int {
        return key.hashValue
    }
    static func ==(lhs: _RouteKey, rhs: _RouteKey) -> Bool {
        return lhs.key == rhs.key
    }
}

/// Registry for registering pure Swift protocol and discovering ZIKRouter subclass.
internal class Registry {
    /// value: subclass of ZIKViewRouter or ZIKViewRoute
    fileprivate static var viewProtocolContainer = [_RouteKey: Any]()
    /// value: subclass of ZIKViewRouter or ZIKViewRoute
    fileprivate static var viewModuleProtocolContainer = [_RouteKey: Any]()
    /// key: adapter view protocol  value: adaptee view protocol
    fileprivate static var viewAdapterContainer = [_RouteKey: _RouteKey]()
    /// key: adapter view module protocol  value: adaptee view module protocol
    fileprivate static var viewModuleAdapterContainer = [_RouteKey: _RouteKey]()
    /// value: subclass of ZIKServiceRouter or ZIKServiceRoute
    fileprivate static var serviceProtocolContainer = [_RouteKey: Any]()
    /// value: subclass of ZIKServiceRouter or ZIKServiceRoute
    fileprivate static var serviceModuleProtocolContainer = [_RouteKey: Any]()
    /// key: adapter service protocol  value: adaptee service protocol
    fileprivate static var serviceAdapterContainer = [_RouteKey: _RouteKey]()
    /// key: adapter service module protocol  value: adaptee service module protocol
    fileprivate static var serviceModuleAdapterContainer = [_RouteKey: _RouteKey]()
    #if DEBUG
    /// key: subclass of ZIKViewRouter or ZIKViewRoute  value: set of routable view protocols
    fileprivate static var _check_viewProtocolContainer = [_RouteKey: Set<_RouteKey>]()
    /// key: subclass of ZIKServiceRouter or ZIKServiceRoute  value: set of routable service protocols
    fileprivate static var _check_serviceProtocolContainer = [_RouteKey: Set<_RouteKey>]()
    #endif
    
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
        assert(ZIKAnyViewRouter.isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKAnyViewRouter.self), "This router must be subclass of ZIKViewRouter")
        // `UIViewController & ObjcProtocol` type is also a Protocol in objc, but we want to keep it in swift container
        if let routableProtocol = _routableViewProtocolFromObject(destinationProtocol), routableView.typeName == routableProtocol.name {
            router.registerViewProtocol(routableProtocol)
            return
        }
        assert(viewProtocolContainer[_RouteKey(routable: routableView)] == nil, "view protocol (\(destinationProtocol)) was already registered with router (\(viewProtocolContainer[_RouteKey(routable: routableView)]!)).")
        #if DEBUG
        _addToValidateList(for: routableView, router: router)
        #endif
        viewProtocolContainer[_RouteKey(routable: routableView)] = router
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
        assert(ZIKAnyViewRouter.isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKAnyViewRouter.self), "This router must be subclass of ZIKViewRouter")
        if let routableProtocol = _routableViewModuleProtocolFromObject(configProtocol), routableViewModule.typeName == routableProtocol.name {
            router.registerModuleProtocol(routableProtocol)
            return
        }
        assert(router.defaultRouteConfiguration() is Protocol, "The router (\(router))'s default configuration must conform to the config protocol (\(configProtocol)) to register.")
        assert(viewModuleProtocolContainer[_RouteKey(routable: routableViewModule)] == nil, "view config protocol (\(configProtocol)) was already registered with router (\(viewModuleProtocolContainer[_RouteKey(routable: routableViewModule)]!)).")
        viewModuleProtocolContainer[_RouteKey(routable: routableViewModule)] = router
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
        assert(ZIKAnyServiceRouter.isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKAnyServiceRouter.self), "This router must be subclass of ZIKServiceRouter")
        if let routableProtocol = _routableServiceProtocolFromObject(destinationProtocol), routableService.typeName == routableProtocol.name {
            router.registerServiceProtocol(routableProtocol)
            return
        }
        assert(serviceProtocolContainer[_RouteKey(routable: routableService)] == nil, "service protocol (\(destinationProtocol)) was already registered with router (\(serviceProtocolContainer[_RouteKey(routable: routableService)]!)).")
        #if DEBUG
        _addToValidateList(for: routableService, router: router)
        #endif
        serviceProtocolContainer[_RouteKey(routable: routableService)] = router
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
        assert(ZIKAnyServiceRouter.isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        assert(ZIKRouter_classIsSubclassOfClass(router, ZIKAnyServiceRouter.self), "This router must be subclass of ZIKServiceRouter")
        if let routableProtocol = _routableServiceModuleProtocolFromObject(configProtocol), routableServiceModule.typeName == routableProtocol.name {
            router.registerModuleProtocol(routableProtocol)
            return
        }
        assert(router.defaultRouteConfiguration() is Protocol, "The router (\(router))'s default configuration must conform to the config protocol (\(configProtocol)) to register.")
        assert(serviceModuleProtocolContainer[_RouteKey(routable: routableServiceModule)] == nil, "service config protocol (\(configProtocol)) was already registered with router (\(serviceModuleProtocolContainer[_RouteKey(routable: routableServiceModule)]!)).")
        serviceModuleProtocolContainer[_RouteKey(routable: routableServiceModule)] = router
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
        assert(ZIKAnyViewRouter.isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        if let routableProtocol = _routableViewProtocolFromObject(destinationProtocol), routableView.typeName == routableProtocol.name {
            _ = route.registerDestinationProtocol(routableProtocol)
            return
        }
        assert(viewProtocolContainer[_RouteKey(routable: routableView)] == nil, "view protocol (\(destinationProtocol)) was already registered with router (\(viewProtocolContainer[_RouteKey(routable: routableView)]!)).")
        #if DEBUG
        _addTovalidateList(for: routableView, route: route)
        #endif
        viewProtocolContainer[_RouteKey(routable: routableView)] = route
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
        assert(ZIKAnyViewRouter.isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        if let routableProtocol = _routableViewModuleProtocolFromObject(configProtocol), routableViewModule.typeName == routableProtocol.name {
            _ = route.registerModuleProtocol(routableProtocol)
            return
        }
        assert(viewModuleProtocolContainer[_RouteKey(routable: routableViewModule)] == nil, "view config protocol (\(configProtocol)) was already registered with router (\(viewModuleProtocolContainer[_RouteKey(routable: routableViewModule)]!)).")
        viewModuleProtocolContainer[_RouteKey(routable: routableViewModule)] = route
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
        assert(ZIKAnyServiceRouter.isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        if let routableProtocol = _routableServiceProtocolFromObject(destinationProtocol), routableService.typeName == routableProtocol.name {
            _ = route.registerDestinationProtocol(routableProtocol)
            return
        }
        assert(serviceProtocolContainer[_RouteKey(routable: routableService)] == nil, "service protocol (\(destinationProtocol)) was already registered with router (\(serviceProtocolContainer[_RouteKey(routable: routableService)]!)).")
        #if DEBUG
        _addTovalidateList(for: routableService, route: route)
        #endif
        serviceProtocolContainer[_RouteKey(routable: routableService)] = route
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
        assert(ZIKAnyServiceRouter.isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        if let routableProtocol = _routableServiceModuleProtocolFromObject(configProtocol), String(describing: Protocol.self) == routableProtocol.name {
            _ = route.registerModuleProtocol(routableProtocol)
            return
        }
        assert(serviceModuleProtocolContainer[_RouteKey(routable: routableServiceModule)] == nil, "service config protocol (\(configProtocol)) was already registered with router (\(serviceModuleProtocolContainer[_RouteKey(routable: routableServiceModule)]!)).")
        serviceModuleProtocolContainer[_RouteKey(routable: routableServiceModule)] = route
    }
    
    internal static func register<Adapter, Adaptee>(adapter: RoutableView<Adapter>, forAdaptee adaptee: RoutableView<Adaptee>) {
        let adapterKey = _RouteKey(routable: adapter)
        let objcAdapter = _routableViewProtocolFromObject(Adapter.self)
        let objcAdaptee = _routableViewProtocolFromObject(Adaptee.self)
        if let objcAdapter = objcAdapter, let objcAdaptee = objcAdaptee,
            adapter.typeName == objcAdapter.name,
            adaptee.typeName == objcAdaptee.name {
            assert(viewProtocolContainer[adapterKey] == nil, "Adapter (\(Adapter.self)) is already registered with a router (\(viewProtocolContainer[adapterKey]!))")
            assert(viewAdapterContainer[adapterKey] == nil, "Adapter (\(Adapter.self)) can't register adaptee (\(Adaptee.self)), already register another adaptee (\(viewAdapterContainer[adapterKey]!.key))")
            ZIKViewRouteRegistry.registerDestinationAdapter(objcAdapter, forAdaptee: objcAdaptee)
            return
        }
        assert(viewProtocolContainer[adapterKey] == nil, "Adapter (\(Adapter.self)) is already registered with a router (\(viewProtocolContainer[adapterKey]!))")
        assert(viewAdapterContainer[adapterKey] == nil, "Adapter (\(Adapter.self)) can't register adaptee (\(Adaptee.self)), already register another adaptee (\(viewAdapterContainer[adapterKey]!.key))")
        viewAdapterContainer[adapterKey] = _RouteKey(routable: adaptee)
    }
    
    internal static func register<Adapter, Adaptee>(adapter: RoutableViewModule<Adapter>, forAdaptee adaptee: RoutableViewModule<Adaptee>) {
        let adapterKey = _RouteKey(routable: adapter)
        let objcAdapter = _routableViewModuleProtocolFromObject(Adapter.self)
        let objcAdaptee = _routableViewModuleProtocolFromObject(Adaptee.self)
        if let objcAdapter = objcAdapter, let objcAdaptee = objcAdaptee,
            adapter.typeName == objcAdapter.name,
            adaptee.typeName == objcAdaptee.name {
            assert(viewModuleProtocolContainer[adapterKey] == nil, "Adapter (\(Adapter.self)) is already registered with a router (\(viewModuleProtocolContainer[adapterKey]!))")
            assert(viewModuleAdapterContainer[adapterKey] == nil, "Adapter (\(Adapter.self)) can't register adaptee (\(Adaptee.self)), already register another adaptee (\(viewModuleAdapterContainer[adapterKey]!.key))")
            ZIKViewRouteRegistry.registerModuleAdapter(objcAdapter, forAdaptee: objcAdaptee)
            return
        }
        assert(viewModuleProtocolContainer[adapterKey] == nil, "Adapter (\(Adapter.self)) is already registered with a router (\(viewModuleProtocolContainer[adapterKey]!))")
        assert(viewModuleAdapterContainer[adapterKey] == nil, "Adapter (\(Adapter.self)) can't register adaptee (\(Adaptee.self)), already register another adaptee (\(viewModuleAdapterContainer[adapterKey]!.key))")
        viewModuleAdapterContainer[adapterKey] = _RouteKey(routable: adaptee)
    }
    
    internal static func register<Adapter, Adaptee>(adapter: RoutableService<Adapter>, forAdaptee adaptee: RoutableService<Adaptee>) {
        let adapterKey = _RouteKey(routable: adapter)
        let objcAdapter = _routableServiceProtocolFromObject(Adapter.self)
        let objcAdaptee = _routableServiceProtocolFromObject(Adaptee.self)
        if let objcAdapter = objcAdapter, let objcAdaptee = objcAdaptee,
            adapter.typeName == objcAdapter.name,
            adaptee.typeName == objcAdaptee.name {
            assert(serviceProtocolContainer[adapterKey] == nil, "Adapter (\(Adapter.self)) is already registered with a router (\(serviceProtocolContainer[adapterKey]!))")
            assert(serviceAdapterContainer[adapterKey] == nil, "Adapter (\(Adapter.self)) can't register adaptee (\(Adaptee.self)), already register another adaptee (\(serviceAdapterContainer[adapterKey]!.key))")
            ZIKServiceRouteRegistry.registerDestinationAdapter(objcAdapter, forAdaptee: objcAdaptee)
            return
        }
        assert(serviceProtocolContainer[adapterKey] == nil, "Adapter (\(Adapter.self)) is already registered with a router (\(serviceProtocolContainer[adapterKey]!))")
        assert(serviceAdapterContainer[adapterKey] == nil, "Adapter (\(Adapter.self)) can't register adaptee (\(Adaptee.self)), already register another adaptee (\(serviceAdapterContainer[adapterKey]!.key))")
        serviceAdapterContainer[adapterKey] = _RouteKey(routable: adaptee)
    }
    
    internal static func register<Adapter, Adaptee>(adapter: RoutableServiceModule<Adapter>, forAdaptee adaptee: RoutableServiceModule<Adaptee>) {
        let adapterKey = _RouteKey(routable: adapter)
        let objcAdapter = _routableServiceModuleProtocolFromObject(Adapter.self)
        let objcAdaptee = _routableServiceModuleProtocolFromObject(Adaptee.self)
        if let objcAdapter = objcAdapter, let objcAdaptee = objcAdaptee,
            adapter.typeName == objcAdapter.name,
            adaptee.typeName == objcAdaptee.name {
            assert(serviceModuleProtocolContainer[adapterKey] == nil, "Adapter (\(Adapter.self)) is already registered with a router (\(serviceModuleProtocolContainer[adapterKey]!))")
            assert(serviceModuleAdapterContainer[adapterKey] == nil, "Adapter (\(Adapter.self)) can't register adaptee (\(Adaptee.self)), already register another adaptee (\(serviceModuleAdapterContainer[adapterKey]!.key))")
            ZIKServiceRouteRegistry.registerModuleAdapter(objcAdapter, forAdaptee: objcAdaptee)
            return
        }
        assert(serviceModuleProtocolContainer[adapterKey] == nil, "Adapter (\(Adapter.self)) is already registered with a router (\(serviceModuleProtocolContainer[adapterKey]!))")
        assert(serviceModuleAdapterContainer[adapterKey] == nil, "Adapter (\(Adapter.self)) can't register adaptee (\(Adaptee.self)), already register another adaptee (\(serviceModuleAdapterContainer[adapterKey]!.key))")
        serviceModuleAdapterContainer[adapterKey] = _RouteKey(routable: adaptee)
    }
    
    // MARK: Validate
    
    #if DEBUG
    
    private static func _addToValidateList<Protocol>(for routableView: RoutableView<Protocol>, router: ZIKAnyViewRouter.Type) {
        var protocols = _check_viewProtocolContainer[_RouteKey(type: router.self)]
        if protocols == nil {
            protocols = Set()
            protocols?.insert(_RouteKey(routable: routableView))
        } else {
            protocols?.insert(_RouteKey(routable: routableView))
        }
        _check_viewProtocolContainer[_RouteKey(type: router.self)] = protocols
    }
    
    
    private static func _addToValidateList<Protocol>(for routableService: RoutableService<Protocol>, router: ZIKAnyServiceRouter.Type) {
        var protocols = _check_serviceProtocolContainer[_RouteKey(type: router.self)]
        if protocols == nil {
            protocols = Set()
            protocols?.insert(_RouteKey(routable: routableService))
        } else {
            protocols?.insert(_RouteKey(routable: routableService))
        }
        _check_serviceProtocolContainer[_RouteKey(type: router.self)] = protocols
    }
    
    private static func _addTovalidateList<Protocol>(for routableView: RoutableView<Protocol>, route: ZIKAnyViewRoute) {
        var protocols = _check_viewProtocolContainer[_RouteKey(route: route)]
        if protocols == nil {
            protocols = Set()
            protocols?.insert(_RouteKey(routable: routableView))
        } else {
            protocols?.insert(_RouteKey(routable: routableView))
        }
        _check_viewProtocolContainer[_RouteKey(route: route)] = protocols
    }
    
    
    private static func _addTovalidateList<Protocol>(for routableService: RoutableService<Protocol>, route: ZIKAnyServiceRoute) {
        var protocols = _check_serviceProtocolContainer[_RouteKey(route: route)]
        if protocols == nil {
            protocols = Set()
            protocols?.insert(_RouteKey(routable: routableService))
        } else {
            protocols?.insert(_RouteKey(routable: routableService))
        }
        _check_serviceProtocolContainer[_RouteKey(route: route)] = protocols
    }
    
    #endif
}

// MARK: Adapter

extension ZIKViewRouteRegistry {
    @objc class func _swiftRouteForDestinationAdapter(_ adapter: Protocol) -> Any? {
        let adaptee = Registry.viewAdapterContainer[_RouteKey(protocol: adapter)]
        var route: Any?
        repeat {
            guard let adaptee = adaptee else {
                return nil
            }
            route = Registry.viewProtocolContainer[adaptee]
        } while route == nil
        return route
    }
    
    @objc class func _swiftRouteForModuleAdapter(_ adapter: Protocol) -> Any? {
        let adaptee = Registry.viewModuleAdapterContainer[_RouteKey(protocol: adapter)]
        var route: Any?
        repeat {
            guard let adaptee = adaptee else {
                return nil
            }
            route = Registry.viewModuleProtocolContainer[adaptee]
        } while route == nil
        return route
    }
}

extension ZIKServiceRouteRegistry {
    @objc class func _swiftRouteForDestinationAdapter(_ adapter: Protocol) -> Any? {
        let adaptee = Registry.serviceAdapterContainer[_RouteKey(protocol: adapter)]
        var route: Any?
        repeat {
            guard let adaptee = adaptee else {
                return nil
            }
            route = Registry.serviceProtocolContainer[adaptee]
        } while route == nil
        return route
    }
    
    @objc class func _swiftRouteForModuleAdapter(_ adapter: Protocol) -> Any? {
        let adaptee = Registry.serviceModuleAdapterContainer[_RouteKey(protocol: adapter)]
        var route: Any?
        repeat {
            guard let adaptee = adaptee else {
                return nil
            }
            route = Registry.serviceModuleProtocolContainer[adaptee]
        } while route == nil
        return route
    }
}

// MARK: Routable Discover
internal extension Registry {
    
    /// Get view router type for registered view protocol.
    ///
    /// - Parameter routableView: A routabe entry carrying a view protocol conformed by the view registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router type for the view protocol.
    internal static func router<Destination>(to routableView: RoutableView<Destination>) -> ViewRouterType<Destination, ViewRouteConfig>? {
        let routerType = _router(toView: Destination.self, name: routableView.typeName)
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
        let routerType = _router(toViewModule: Module.self , name: routableViewModule.typeName)
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
        let routerType = _router(toService: Destination.self, name: routableService.typeName)
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
        let routerType = _router(toServiceModule: Module.self, name: routableServiceModule.typeName)
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
        let routerType = _router(toView: switchableView.routableProtocol, name: switchableView.typeName)
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
        let routerType = _router(toViewModule: switchableViewModule.routableProtocol, name: switchableViewModule.typeName)
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
        let routerType = _router(toService: switchableService.routableProtocol, name: switchableService.typeName)
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
        let routerType = _router(toServiceModule: switchableServiceModule.routableProtocol, name: switchableServiceModule.typeName)
        if let routerType = routerType {
            return ServiceRouterType(routerType: routerType)
        }
        return nil
    }
}

// MARK: Type Discover

fileprivate extension Registry {
    
    /// Get view router class for registered view protocol.
    ///
    /// - Parameter viewProtocol: View protocol conformed by the view registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Parameter name: The name of the protocol.
    /// - Returns: The view router class for the view protocol.
    fileprivate static func _router(toView viewProtocol: Any.Type, name: String) -> ZIKAnyViewRouterType? {
        if let routerType = _swiftRouter(toView: viewProtocol, name: name) {
            return routerType
        }
        if let routableProtocol = _routableViewProtocolFromObject(viewProtocol), let routerType = _ZIKViewRouterToView(routableProtocol) {
            return routerType
        }
        if _routableViewProtocolFromObject(viewProtocol) == nil {
            ZIKAnyViewRouter
                .notifyGlobalError(
                    with: nil,
                    action: .toView,
                    error: ZIKAnyViewRouter.routeError(withCode:.invalidProtocol, localizedDescription:"Swift view protocol (\(viewProtocol)) was not registered with any view router."))
            assertionFailure("Swift view protocol (\(viewProtocol)) was not registered with any view router.")
        }
        return nil
    }
    fileprivate static func _swiftRouter(toView viewProtocol: Any.Type, name: String) -> ZIKAnyViewRouterType? {
        if let route = viewProtocolContainer[_RouteKey(type: viewProtocol, name: name)], let routerType = ZIKAnyViewRouterType.tryMakeType(forRoute: route) {
            return routerType
        }
        #if DEBUG
        var traversedProtocols: [_RouteKey] = []
        #endif
        var adapter = _RouteKey(type: viewProtocol, name: name)
        var adaptee: _RouteKey?
        repeat {
            adaptee = viewAdapterContainer[adapter]
            if let adaptee = adaptee {
                if let route = viewProtocolContainer[adaptee], let routerType = ZIKAnyViewRouterType.tryMakeType(forRoute: route) {
                    return routerType
                }
                if let adapteeProtocol = NSProtocolFromString(adaptee.key),
                   let routableProtocol = _routableViewProtocolFromObject(adapteeProtocol),
                   let routerType = _ZIKViewRouterToView(routableProtocol) {
                    return routerType
                }
                #if DEBUG
                traversedProtocols.append(adapter)
                if traversedProtocols.contains(adaptee) {
                    let adapterChain = traversedProtocols.reduce("") { (r, e) -> String in
                        return r + "\(e.key) -> "
                    }
                    assertionFailure("Dead cycle in destination adapter -> adaptee chain: \(adapterChain + adaptee.key). Check your register(adapter:forAdaptee:).")
                    break
                }
                #endif
                adapter = adaptee
            }
        } while adaptee != nil
        return nil
    }
    
    /// Get view router class for registered config protocol.
    ///
    /// - Parameter configProtocol: View module config protocol registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Parameter name: The name of the protocol.
    /// - Returns: The view router class for the config protocol.
    fileprivate static func _router(toViewModule configProtocol: Any.Type, name: String) -> ZIKAnyViewRouterType? {
        if let routerType = _swiftRouter(toViewModule: configProtocol, name: name) {
            return routerType
        }
        if let routableProtocol = _routableViewModuleProtocolFromObject(configProtocol), let routerType = _ZIKViewRouterToModule(routableProtocol) {
            return routerType
        }
        
        if _routableViewModuleProtocolFromObject(configProtocol) == nil {
            ZIKAnyViewRouter
                .notifyGlobalError(
                    with: nil,
                    action: .toViewModule,
                    error: ZIKAnyViewRouter.routeError(withCode:.invalidProtocol, localizedDescription:"Swift module config protocol (\(configProtocol)) was not registered with any view router."))
            assertionFailure("Swift module config protocol (\(configProtocol)) was not registered with any view router.")
        }
        return nil
    }
    fileprivate static func _swiftRouter(toViewModule configProtocol: Any.Type, name: String) -> ZIKAnyViewRouterType? {
        if let route = viewModuleProtocolContainer[_RouteKey(type: configProtocol, name: name)], let routerType = ZIKAnyViewRouterType.tryMakeType(forRoute: route) {
            return routerType
        }
        #if DEBUG
        var traversedProtocols: [_RouteKey] = []
        #endif
        var adapter = _RouteKey(type: configProtocol, name: name)
        var adaptee: _RouteKey?
        repeat {
            adaptee = viewModuleAdapterContainer[adapter]
            if let adaptee = adaptee {
                if let route = viewModuleProtocolContainer[adaptee], let routerType = ZIKAnyViewRouterType.tryMakeType(forRoute: route) {
                    return routerType
                }
                if let adapteeProtocol = NSProtocolFromString(adaptee.key),
                   let routableProtocol = _routableViewModuleProtocolFromObject(adapteeProtocol),
                   let routerType = _ZIKViewRouterToModule(routableProtocol) {
                    return routerType
                }
                #if DEBUG
                traversedProtocols.append(adapter)
                if traversedProtocols.contains(adaptee) {
                    let adapterChain = traversedProtocols.reduce("") { (r, e) -> String in
                        return r + "\(e.key) -> "
                    }
                    assertionFailure("Dead cycle in module adapter -> adaptee chain: \(adapterChain + adaptee.key). Check your register(adapter:forAdaptee:).")
                    break
                }
                #endif
                adapter = adaptee
            }
        } while adaptee != nil
        return nil
    }
    
    /// Get service router class for registered service protocol.
    ///
    /// - Parameter serviceProtocol: Service protocol conformed by the service registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Parameter name: The name of the protocol.
    /// - Returns: The service router class for the service protocol.
    fileprivate static func _router(toService serviceProtocol: Any.Type, name: String) -> ZIKAnyServiceRouterType? {
        if let routerType = _swiftRouter(toService: serviceProtocol, name: name) {
            return routerType
        }
        if let routableProtocol = _routableServiceProtocolFromObject(serviceProtocol), let routerType = _ZIKServiceRouterToService(routableProtocol) {
            return routerType
        }
        if _routableServiceProtocolFromObject(serviceProtocol) == nil {
            ZIKAnyServiceRouter
                .notifyGlobalError(
                    with: nil,
                    action: .toService,
                    error: ZIKAnyServiceRouter.routeError(withCode:.invalidProtocol, localizedDescription:"Swift service protocol (\(serviceProtocol)) was not registered with any service router."))
            assertionFailure("Swift service protocol (\(serviceProtocol)) was not registered with any service router.")
        }
        return nil
    }
    fileprivate static func _swiftRouter(toService serviceProtocol: Any.Type, name: String) -> ZIKAnyServiceRouterType? {
        if let route = serviceProtocolContainer[_RouteKey(type: serviceProtocol, name: name)], let routerType = ZIKAnyServiceRouterType.tryMakeType(forRoute: route) {
            return routerType
        }
        #if DEBUG
        var traversedProtocols: [_RouteKey] = []
        #endif
        var adapter = _RouteKey(type: serviceProtocol, name: name)
        var adaptee: _RouteKey?
        repeat {
            adaptee = serviceAdapterContainer[adapter]
            if let adaptee = adaptee {
                if let route = serviceProtocolContainer[adaptee], let routerType = ZIKAnyServiceRouterType.tryMakeType(forRoute: route) {
                    return routerType
                }
                if let adapteeProtocol = NSProtocolFromString(adaptee.key),
                   let routableProtocol = _routableServiceProtocolFromObject(adapteeProtocol),
                   let routerType = _ZIKServiceRouterToService(routableProtocol) {
                    return routerType
                }
                #if DEBUG
                traversedProtocols.append(adapter)
                if traversedProtocols.contains(adaptee) {
                    let adapterChain = traversedProtocols.reduce("") { (r, e) -> String in
                        return r + "\(e.key) -> "
                    }
                    assertionFailure("Dead cycle in destination adapter -> adaptee chain: \(adapterChain + adaptee.key). Check your register(adapter:forAdaptee:).")
                    break
                }
                #endif
                adapter = adaptee
            }
        } while adaptee != nil
        return nil
    }
    
    /// Get service router class for registered config protocol.
    ///
    /// - Parameter configProtocol: Service module config protocol registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Parameter name: The name of the protocol.
    /// - Returns: The service router class for the config protocol.
    fileprivate static func _router(toServiceModule configProtocol: Any.Type, name: String) -> ZIKAnyServiceRouterType? {
        if let routerType = _swiftRouter(toServiceModule: configProtocol, name: name) {
            return routerType
        }
        
        if let routableProtocol = _routableServiceModuleProtocolFromObject(configProtocol), let routerType = _ZIKServiceRouterToModule(routableProtocol) {
            return routerType
        }
        if _routableServiceModuleProtocolFromObject(configProtocol) == nil {
            ZIKAnyServiceRouter
                .notifyGlobalError(
                    with: nil,
                    action: .toServiceModule,
                    error: ZIKAnyServiceRouter.routeError(withCode:.invalidProtocol, localizedDescription:"Swift module config protocol (\(configProtocol)) was not registered with any service router."))
            assertionFailure("Swift module config protocol (\(configProtocol)) was not registered with any service router.")
        }
        return nil
    }
    fileprivate static func _swiftRouter(toServiceModule configProtocol: Any.Type, name: String) -> ZIKAnyServiceRouterType? {
        if let route = serviceModuleProtocolContainer[_RouteKey(type: configProtocol, name: name)], let routerType = ZIKAnyServiceRouterType.tryMakeType(forRoute: route) {
            return routerType
        }
        #if DEBUG
        var traversedProtocols: [_RouteKey] = []
        #endif
        var adapter = _RouteKey(type: configProtocol, name: name)
        var adaptee: _RouteKey?
        repeat {
            adaptee = serviceModuleAdapterContainer[adapter]
            if let adaptee = adaptee {
                if let route = serviceModuleProtocolContainer[adaptee], let routerType = ZIKAnyServiceRouterType.tryMakeType(forRoute: route) {
                    return routerType
                }
                if let adapteeProtocol = NSProtocolFromString(adaptee.key),
                   let routableProtocol = _routableServiceModuleProtocolFromObject(adapteeProtocol),
                   let routerType = _ZIKServiceRouterToModule(routableProtocol) {
                    return routerType
                }
                #if DEBUG
                traversedProtocols.append(adapter)
                if traversedProtocols.contains(adaptee) {
                    let adapterChain = traversedProtocols.reduce("") { (r, e) -> String in
                        return r + "\(e.key) -> "
                    }
                    assertionFailure("Dead cycle in module adapter -> adaptee chain: \(adapterChain + adaptee.key). Check your register(adapter:forAdaptee:).")
                    break
                }
                #endif
                adapter = adaptee
            }
        } while adaptee != nil
        return nil
    }
}

// MARK: Validate

internal extension Registry {
    internal class func validateConformance(destination: Any, inViewRouterType routerType: ZIKAnyViewRouterType) -> Bool {
        #if DEBUG
        guard let routeKey = _RouteKey(routerType: routerType) else {
            return false
        }
        if let protocols = _check_viewProtocolContainer[routeKey] {
            for viewProtocolEntry in protocols {
                assert(_swift_typeIsTargetType(type(of: destination), viewProtocolEntry.type!), "Bad implementation in router (\(routerType))'s destination(with configuration:), the destination (\(destination)) doesn't conforms to registered view protocol (\(viewProtocolEntry.type!))")
                if _swift_typeIsTargetType(type(of: destination), viewProtocolEntry.type!) == false {
                    return false
                }
            }
        }
        return true
        #else
        return true
        #endif
    }
    internal class func validateConformance(destination: Any, inServiceRouterType routerType: ZIKAnyServiceRouterType) -> Bool {
        #if DEBUG
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
        #else
        return true
        #endif
    }
}

#if DEBUG

extension String {
    func subString(forRegex regex: NSRegularExpression) -> String? {
        if let result = regex.firstMatch(in: self, options: .reportCompletion, range: NSRange(location: 0, length: self.utf8.count)) {
            let subString = (self as NSString).substring(with: result.range)
            return subString
        }
        return nil
    }
}

internal func imagePathOfAddress(_ address: UnsafePointer<Int8>) -> String {
    var info: Dl_info = Dl_info()
    dladdr(address, &info)
    let imagePath = String(cString: info.dli_fname)
    return imagePath
}

/// Make sure all registered view classes conform to their registered view protocols.
private class _ViewRouterValidater: ZIKViewRouteAdapter {
    override class func isAbstractRouter() -> Bool {
        return true
    }
    override class func _didFinishRegistration() {
        
        // Declared protocol by extend RoutableView and RoutableViewModule should be registered
        var declaredRoutableTypes = [String]()
        // Types in method signature used as RoutableView<Type>(), RoutableView<Type>(declaredProtocol: Type.self) and RoutableView<Type>(declaredTypeName: typeName), maybe not declared yet
        var viewRoutingTypes = [(String, String)]()
        // Types in method signature used as RoutableViewModule<Type>(), RoutableViewModule<Type>(declaredProtocol: Type.self) and RoutableViewModule<Type>(declaredTypeName: typeName), maybe not declared yet
        var viewModuleRoutingTypes = [(String, String)]()
        let viewRoutingTypeRegex = try! NSRegularExpression(pattern: "(?<=RoutableView<).*(?=>$)", options: [.anchorsMatchLines])
        let viewModuleRoutingTypeRegex = try! NSRegularExpression(pattern: "(?<=RoutableViewModule<).*(?=>$)", options: [.anchorsMatchLines])
        _enumerateSymbolName { (name, demangledAsSwift) -> Bool in
            if (strstr(name, "RoutableView") != nil) {
                let symbolName = demangledAsSwift(name, false)
                if symbolName.hasPrefix("(extension in"), symbolName.contains(">.init") {
                    if symbolName.contains("(extension in ZRouter)") == false {
                        let simplifiedName = demangledAsSwift(name, true)
                        declaredRoutableTypes.append(simplifiedName)
                    } else if symbolName.contains("." + String(describing: ViewController.self)), symbolName.contains(".ZIKViewRoutable") {
                        let imagePath = imagePathOfAddress(name)
                        assert(imagePath.contains("/ZRouter.framework/") || !hasDynamicLibrary("ZRouter"), """
                            Don't use an UIViewController as generic parameter of RoutableView:
                            ```
                            @objc protocol SomeViewProtocol: ZIKViewRoutable {

                            }
                            class SomeViewController: \(String(describing: ViewController.self)), SomeViewProtocol {

                            }
                            ```
                            ```
                            // Invalid usage
                            RoutableView<SomeViewController>()
                            ```
                            You should use the protocol to get its router.
                            How to resolve: search code in \((imagePath as NSString).lastPathComponent), fix `RoutableView<SomeViewController>()` to `RoutableView<SomeViewProtocol>()`
                            If it's hard to find out the bad code, you can use `Hopper Disassembler` to analyze your app and see references to this symbol:
                            (extension in ZRouter):ZRouter.RoutableView<A where A: __ObjC.\(String(describing: ViewController.self)), A: __ObjC.ZIKViewRoutable>.init() -> ZRouter.RoutableView<A>
                            """)
                    } else if symbolName.contains("." + String(describing: View.self)), symbolName.contains(".ZIKViewRoutable") {
                        let imagePath = imagePathOfAddress(name)
                        assert(imagePath.contains("/ZRouter.framework/") || !hasDynamicLibrary("ZRouter"), """
                            Don't use an UIViewController as generic parameter of RoutableView:
                            ```
                            @objc protocol SomeViewProtocol: ZIKViewRoutable {
                            
                            }
                            class SomeView: \(String(describing: View.self)), SomeViewProtocol {
                            
                            }
                            ```
                            ```
                            // Invalid usage
                            RoutableView<SomeView>()
                            ```
                            You should use the protocol to get its router.
                            How to resolve: search code in \((imagePath as NSString).lastPathComponent), fix `RoutableView<SomeView>()` to `RoutableView<SomeViewProtocol>()`
                            If it's hard to find out the bad code, you can use `Hopper Disassembler` to analyze your app and see references to this symbol:
                            (extension in ZRouter):ZRouter.RoutableView<A where A: __ObjC.\(String(describing: View.self)), A: __ObjC.ZIKViewRoutable>.init() -> ZRouter.RoutableView<A>
                            """)
                    } else if symbolName.contains(".ZIKViewRouteConfiguration"), symbolName.contains(".ZIKViewModuleRoutable") {
                        let imagePath = imagePathOfAddress(name)
                        assert(imagePath.contains("/ZRouter.framework/") || !hasDynamicLibrary("ZRouter"), """
                            Don't use a ZIKViewRouteConfiguration as generic parameter of RoutableViewModule:
                            ```
                            @objc protocol SomeViewModuleProtocol: ZIKViewModuleRoutable {

                            }
                            class SomeViewRouteConfiguration: ZIKViewRouteConfiguration, SomeViewModuleProtocol {

                            }
                            ```
                            ```
                            // Invalid usage
                            RoutableViewModule<SomeViewRouteConfiguration>()
                            ```
                            You should use the protocol to get its router.
                            How to resolve: search code in \((imagePath as NSString).lastPathComponent), fix `RoutableViewModule<SomeViewRouteConfiguration>()` to `RoutableViewModule<SomeViewModuleProtocol>()`
                            If it's hard to find out the bad code, you can use `Hopper Disassembler` to analyze your app and see references to this symbol:
                            (extension in ZRouter):ZRouter.RoutableViewModule<A where A: __ObjC.ZIKViewRouteConfiguration, A: __ObjC.ZIKViewModuleRoutable>.init() -> ZRouter.RoutableViewModule<A>
                            """)
                    } else if symbolName.contains("where"), symbolName.contains("=="), (symbolName.contains(".ZIKViewRoutable>") || symbolName.contains(".ZIKViewModuleRoutable>")) {
                        let imagePath = imagePathOfAddress(name)
                        assert(imagePath.contains("/ZRouter.framework/") || !hasDynamicLibrary("ZRouter"), """
                            Don't use ZIKViewRoutable or ZIKViewModuleRoutable as generic parameter:
                            ```
                            // Invalid usage
                            RoutableView<ZIKViewRoutable>()
                            RoutableViewModule<ZIKViewModuleRoutable>()
                            ```
                            You should use the explicit protocol to get its router.
                            How to resolve: search code in \((imagePath as NSString).lastPathComponent), fix `RoutableView<ZIKViewRoutable>()` to `RoutableView<SomeViewProtocol>()` or `RoutableViewModule<ZIKViewModuleRoutable>()` to `RoutableViewModule<SomeViewModuleProtocol>()`
                            """)
                    }
                } else if symbolName.hasPrefix("type metadata accessor for ZRouter.RoutableView<") {
                    let simplifiedName = demangledAsSwift(name, true)
                    if let routingType = symbolName.subString(forRegex: viewRoutingTypeRegex),
                        let simplifiedRoutingType = simplifiedName.subString(forRegex: viewRoutingTypeRegex) {
                        viewRoutingTypes.append((routingType, simplifiedRoutingType))
                    }
                } else if symbolName.hasPrefix("type metadata accessor for ZRouter.RoutableViewModule<") {
                    let simplifiedName = demangledAsSwift(name, true)
                    if let routingType = symbolName.subString(forRegex: viewModuleRoutingTypeRegex),
                        let simplifiedRoutingType = simplifiedName.subString(forRegex: viewModuleRoutingTypeRegex) {
                        viewModuleRoutingTypes.append((routingType, simplifiedRoutingType))
                    }
                }
            }
            return true
        }
        
        let destinationProtocolRegex = try! NSRegularExpression(pattern: "(?<=-> RoutableView<).*(?=>$)", options: [.anchorsMatchLines])
        let moduleProtocolRegex = try! NSRegularExpression(pattern: "(?<=-> RoutableViewModule<).*(?=>$)", options: [.anchorsMatchLines])
        var declaredDestinationProtocols = [String]()
        var declaredModuleProtocols = [String]()
        for declaration in declaredRoutableTypes {
            if let declaredProtocol = declaration.subString(forRegex: destinationProtocolRegex) {
                declaredDestinationProtocols.append(declaredProtocol)
            } else if let declaredProtocol = declaration.subString(forRegex: moduleProtocolRegex) {
                declaredModuleProtocols.append(declaredProtocol)
            }
        }
        
        for declaredProtocol in declaredDestinationProtocols {
            assert(Registry.viewProtocolContainer.keys.contains(_RouteKey(key: declaredProtocol)) ||
                Registry.viewAdapterContainer.keys.contains(_RouteKey(key: declaredProtocol)), "Declared view protocol (\(declaredProtocol)) is not registered with any router.")
        }
        for declaredProtocol in declaredModuleProtocols {
            assert(Registry.viewModuleProtocolContainer.keys.contains(_RouteKey(key: declaredProtocol)) ||
                Registry.viewModuleAdapterContainer.keys.contains(_RouteKey(key: declaredProtocol)), "Declared view protocol (\(declaredProtocol)) is not registered with any router.")
        }
        
        for (routingType, simplifiedName) in viewRoutingTypes {
            var routingTypeName = routingType
            var routableProtocol: Protocol?
            if routingTypeName.hasPrefix("__ObjC.") {
                routingTypeName = simplifiedName
            }
            if let objcProtocol = NSProtocolFromString(routingTypeName) {
                routableProtocol  = _routableViewProtocolFromObject(objcProtocol)
            }
            assert(declaredDestinationProtocols.contains(simplifiedName) || routableProtocol != nil, "Find invalid generic type usage for routing: RoutableView<\(simplifiedName)>. You should only use declared protocol type as generic type, don't use \"RoutableView<\(simplifiedName)>\" or \"RoutableView(declaredProtocol:\(simplifiedName))\" in your code !")
        }
        for (routingType, simplifiedName) in viewModuleRoutingTypes {
            var routingTypeName = routingType
            var routableProtocol: Protocol?
            if routingTypeName.hasPrefix("__ObjC.") {
                routingTypeName = simplifiedName
            }
            if let objcProtocol = NSProtocolFromString(routingTypeName) {
                routableProtocol  = _routableViewModuleProtocolFromObject(objcProtocol)
            }
            assert(declaredModuleProtocols.contains(simplifiedName) || routableProtocol != nil, "Find invalid generic type usage for routing: RoutableViewModule<\(simplifiedName)>. You should only use declared protocol type as generic type, don't use \"RoutableViewModule<\(simplifiedName)>\" or \"RoutableViewModule(declaredProtocol:\(simplifiedName))\" in your code!")
        }
        
        // Destination should conform to registered destination protocols
        for (routeKey, route) in Registry.viewProtocolContainer {
            let viewProtocol = routeKey.type!
            let badDestinationClass: AnyClass? = ZIKViewRouteRegistry.validateDestinations(forRoute: route, handler: { (destinationClass) -> Bool in
                return _swift_typeIsTargetType(destinationClass, viewProtocol)
            })
            assert(badDestinationClass == nil, "Registered view class (\(badDestinationClass!)) for router (\(route)) should conform to registered view protocol (\(viewProtocol)).")
        }
        
        // Destination should conforms to registered adapter destination protocols
        for (adapter, _) in Registry.viewAdapterContainer {
            assert(adapter.type != nil)
            guard let type = adapter.type, let routerType = Registry._swiftRouter(toView: type, name: adapter.key) else {
                assertionFailure("View adapter protocol(\(adapter.key)) is not registered with any router!")
                continue
            }
            let route = routerType.routeObject
            var adapterProtocol: Any? = adapter.type
            if adapterProtocol == nil {
                adapterProtocol = NSProtocolFromString(adapter.key)
            }
            guard let viewProtocol = adapterProtocol else {
                assertionFailure("Invalid adapter (\(adapter.key)), can't get its type")
                continue
            }
            let badDestinationClass: AnyClass? = ZIKViewRouteRegistry.validateDestinations(forRoute: route, handler: { (destinationClass) -> Bool in
                return _swift_typeIsTargetType(destinationClass, viewProtocol)
            })
            assert(badDestinationClass == nil, "Registered view class (\(badDestinationClass!)) for router (\(route)) should conform to registered view adapter protocol (\(viewProtocol)).")
        }
        
        // Router's defaultRouteConfiguration should conforms to registered module config protocols
        for (routeKey, route) in Registry.viewModuleProtocolContainer {
            guard let routerType = ZIKAnyViewRouterType.tryMakeType(forRoute: route) else {
                assertionFailure("Invalid route (\(route))")
                continue
            }
            let configProtocol = routeKey.type!
            let configType = type(of: routerType.defaultRouteConfiguration())
            assert(_swift_typeIsTargetType(configType, configProtocol), "The router (\(route))'s default configuration (\(configType)) must conform to the registered config protocol (\(configProtocol)).")
        }
        
        // Router's defaultRouteConfiguration should conforms to registered adapter module config protocols
        for (adapter, _) in Registry.viewModuleAdapterContainer {
            assert(adapter.type != nil)
            guard let type = adapter.type, let routerType = Registry._swiftRouter(toViewModule: type, name: adapter.key) else {
                assertionFailure("View adapter protocol(\(adapter.key)) is not registered with any router!")
                continue
            }
            var adapterProtocol: Any? = adapter.type
            if adapterProtocol == nil {
                adapterProtocol = NSProtocolFromString(adapter.key)
            }
            guard let configProtocol = adapterProtocol else {
                assertionFailure("Invalid adapter (\(adapter.key)), can't get its type")
                continue
            }
            let config = routerType.defaultRouteConfiguration()
            let configType = Swift.type(of: config)
            assert(_swift_typeIsTargetType(configType, configProtocol), "The router (\(routerType))'s default configuration (\(configType)) must conform to the registered adapter config protocol (\(configProtocol)).")
        }
    }
}

/// Make sure all registered service classes conform to their registered service protocols.
private class _ServiceRouterValidater: ZIKServiceRouteAdapter {
    override class func isAbstractRouter() -> Bool {
        return true
    }
    override class func _didFinishRegistration() {
        
        // Declared protocol by extend RoutableService and RoutableServiceModule should be registered
        var declaredRoutableTypes = [String]()
        // Types in method signature used as RoutableService<Type>(), RoutableService<Type>(declaredProtocol: Type.self) and RoutableService<Type>(declaredTypeName: typeName), maybe not declared yet
        var serviceRoutingTypes = [(String, String)]()
        // Types in method signature used as RoutableServiceModule<Type>(), RoutableServiceModule<Type>(declaredProtocol: Type.self) and RoutableServiceModule<Type>(declaredTypeName: typeName), maybe not declared yet
        var serviceModuleRoutingTypes = [(String, String)]()
        
        let serviceRoutingTypeRegex = try! NSRegularExpression(pattern: "(?<=RoutableService<).*(?=>$)", options: [.anchorsMatchLines])
        let serviceModuleRoutingTypeRegex = try! NSRegularExpression(pattern: "(?<=RoutableServiceModule<).*(?=>$)", options: [.anchorsMatchLines])
        _enumerateSymbolName { (name, demangledAsSwift) -> Bool in
            if (strstr(name, "RoutableService") != nil) {
                let symbolName = demangledAsSwift(name, false)
                if symbolName.hasPrefix("(extension in"), symbolName.contains(">.init") {
                    if symbolName.contains("(extension in ZRouter)") == false {
                        let simplifiedName = demangledAsSwift(name, true)
                        declaredRoutableTypes.append(simplifiedName)
                    } else if symbolName.contains(".NSObject"), symbolName.contains(".ZIKServiceRoutable") {
                        let imagePath = imagePathOfAddress(name)
                        assert(imagePath.contains("/ZRouter.framework/") || !hasDynamicLibrary("ZRouter"), """
                            Don't use a Class type as generic parameter of RoutableService:
                            ```
                            @objc protocol SomeServiceProtocol: ZIKServiceRoutable {

                            }
                            class SomeClassType: NSObject, SomeServiceProtocol {

                            }
                            ```
                            ```
                            // Invalid usage
                            RoutableService<SomeClassType>()
                            ```
                            You should use the protocol to get its router.
                            How to resolve: search code in \((imagePath as NSString).lastPathComponent), fix `RoutableService<SomeClassType>()` to `RoutableService<SomeServiceProtocol>()`
                            If it's hard to find out the bad code, you can use `Hopper Disassembler` to analyze your app and see references to this symbol:
                            (extension in ZRouter):ZRouter.RoutableService<A where A: __ObjC.NSObject, A: __ObjC.ZIKServiceRoutable>.init() -> ZRouter.RoutableService<A>
                            """)
                    } else if symbolName.contains(".ZIKPerformRouteConfiguration"), symbolName.contains(".ZIKServiceModuleRoutable") {
                        let imagePath = imagePathOfAddress(name)
                        assert(imagePath.contains("/ZRouter.framework/") || !hasDynamicLibrary("ZRouter"), """
                            Don't use a ZIKPerformRouteConfiguration as generic parameter of RoutableServiceModule:
                            ```
                            @objc protocol SomeServiceModuleProtocol: ZIKServiceModuleRoutable {

                            }
                            class SomeServiceRouteConfiguration: ZIKPerformRouteConfiguration, SomeServiceModuleProtocol {

                            }
                            ```
                            ```
                            // Invalid usage
                            RoutableServiceModule<SomeServiceRouteConfiguration>()
                            ```
                            You should use the protocol to get its router.
                            How to resolve: search code in \((imagePath as NSString).lastPathComponent), fix `RoutableServiceModule<SomeServiceRouteConfiguration>()` to `RoutableServiceModule<SomeServiceModuleProtocol>()`
                            If it's hard to find out the bad code, you can use `Hopper Disassembler` to analyze your app and see references to this symbol:
                            (extension in ZRouter):ZRouter.RoutableServiceModule<A where A: __ObjC.ZIKPerformRouteConfiguration, A: __ObjC.ZIKServiceModuleRoutable>.init() -> ZRouter.RoutableServiceModule<A>
                            """)
                    } else if symbolName.contains("where"), symbolName.contains("=="), (symbolName.contains(".ZIKServiceRoutable>") || symbolName.contains(".ZIKServiceModuleRoutable>")) {
                        let imagePath = imagePathOfAddress(name)
                        assert(imagePath.contains("/ZRouter.framework/") || !hasDynamicLibrary("ZRouter"), """
                            Don't use ZIKServiceRoutable or ZIKServiceModuleRoutable as generic parameter:
                            ```
                            // Invalid usage
                            RoutableService<ZIKServiceRoutable>()
                            RoutableServiceModule<ZIKServiceModuleRoutable>()
                            ```
                            You should use the explicit protocol to get its router.
                            How to resolve: search code in \((imagePath as NSString).lastPathComponent), fix `RoutableService<ZIKServiceRoutable>()` to `RoutableService<SomeServiceProtocol>()` or `RoutableServiceModule<ZIKServiceModuleRoutable>()` to `RoutableServiceModule<SomeServiceModuleProtocol>()`
                            """)
                    }
                } else if symbolName.hasPrefix("type metadata accessor for ZRouter.RoutableService<") {
                    let simplifiedName = demangledAsSwift(name, true)
                    if let routingType = symbolName.subString(forRegex: serviceRoutingTypeRegex),
                        let simplifiedRoutingType = simplifiedName.subString(forRegex: serviceRoutingTypeRegex) {
                        serviceRoutingTypes.append((routingType, simplifiedRoutingType))
                    }
                } else if symbolName.hasPrefix("type metadata accessor for ZRouter.RoutableServiceModule<") {
                    let simplifiedName = demangledAsSwift(name, true)
                    if let routingType = symbolName.subString(forRegex: serviceModuleRoutingTypeRegex),
                        let simplifiedRoutingType = simplifiedName.subString(forRegex: serviceModuleRoutingTypeRegex) {
                        serviceModuleRoutingTypes.append((routingType, simplifiedRoutingType))
                    }
                }
            }
            return true
        }
        
        let destinationProtocolRegex = try! NSRegularExpression(pattern: "(?<=-> RoutableService<).*(?=>$)", options: [.anchorsMatchLines])
        let moduleProtocolRegex = try! NSRegularExpression(pattern: "(?<=-> RoutableServiceModule<).*(?=>$)", options: [.anchorsMatchLines])
        var declaredDestinationProtocols = [String]()
        var declaredModuleProtocols = [String]()
        for declaration in declaredRoutableTypes {
            if let declaredProtocol = declaration.subString(forRegex: destinationProtocolRegex) {
                declaredDestinationProtocols.append(declaredProtocol)
            } else if let declaredProtocol = declaration.subString(forRegex: moduleProtocolRegex) {
                declaredModuleProtocols.append(declaredProtocol)
            }
        }
        
        for declaredProtocol in declaredDestinationProtocols {
            assert(Registry.serviceProtocolContainer.keys.contains(_RouteKey(key: declaredProtocol)) ||
                Registry.serviceAdapterContainer.keys.contains(_RouteKey(key: declaredProtocol)), "Declared service protocol (\(declaredProtocol)) is not registered with any router.")
        }
        for declaredProtocol in declaredModuleProtocols {
            assert(Registry.serviceModuleProtocolContainer.keys.contains(_RouteKey(key: declaredProtocol)) ||
                Registry.serviceModuleAdapterContainer.keys.contains(_RouteKey(key: declaredProtocol)), "Declared service protocol (\(declaredProtocol)) is not registered with any router.")
        }
        
        for (routingType, simplifiedName) in serviceRoutingTypes {
            var routingTypeName = routingType
            var routableProtocol: Protocol?
            if routingTypeName.hasPrefix("__ObjC.") {
                routingTypeName = simplifiedName
            }
            if let objcProtocol = NSProtocolFromString(routingTypeName) {
                routableProtocol  = _routableServiceProtocolFromObject(objcProtocol)
            }
            assert(declaredDestinationProtocols.contains(simplifiedName) || routableProtocol != nil, "Find invalid generic type usage for routing: RoutableService<\(simplifiedName)>. You should only use declared protocol type as generic type, don't use \"RoutableService<\(simplifiedName)>\" or \"RoutableService(declaredProtocol:\(simplifiedName))\" in your code!")
        }
        for (routingType, simplifiedName) in serviceModuleRoutingTypes {
            var routingTypeName = routingType
            var routableProtocol: Protocol?
            if routingTypeName.hasPrefix("__ObjC.") {
                routingTypeName = simplifiedName
            }
            if let objcProtocol = NSProtocolFromString(routingTypeName) {
                routableProtocol  = _routableServiceModuleProtocolFromObject(objcProtocol)
            }
            assert(declaredModuleProtocols.contains(simplifiedName) || routableProtocol != nil, "Find invalid generic type usage for routing: RoutableServiceModule<\(simplifiedName)>. You should only use declared protocol type as generic type, don't use \"RoutableServiceModule<\(simplifiedName)>\" or \"RoutableServiceModule(declaredProtocol:\(simplifiedName))\" in your code!")
        }
        
        // Destination should conforms to registered destination protocols
        for (routeKey, route) in Registry.serviceProtocolContainer {
            let serviceProtocol = routeKey.type!
            let badDestinationClass: AnyClass? = ZIKServiceRouteRegistry.validateDestinations(forRoute: route, handler: { (destinationClass) -> Bool in
                return _swift_typeIsTargetType(destinationClass, serviceProtocol)
            })
            assert(badDestinationClass == nil, "Registered service class (\(badDestinationClass!)) for router (\(route)) should conform to registered service protocol (\(serviceProtocol)).")
        }
        
        // Destination should conforms to registered adapter destination protocols
        for (adapter, _) in Registry.serviceAdapterContainer {
            assert(adapter.type != nil)
            guard let type = adapter.type, let routerType = Registry._swiftRouter(toService: type, name: adapter.key) else {
                assertionFailure("Service adapter protocol(\(adapter.key)) is not registered with any router!")
                continue
            }
            let route = routerType.routeObject
            var adapterProtocol: Any? = adapter.type
            if adapterProtocol == nil {
                adapterProtocol = NSProtocolFromString(adapter.key)
            }
            guard let serviceProtocol = adapterProtocol else {
                assertionFailure("Invalid adapter (\(adapter.key)), can't get its type")
                continue
            }
            let badDestinationClass: AnyClass? = ZIKServiceRouteRegistry.validateDestinations(forRoute: route, handler: { (destinationClass) -> Bool in
                return _swift_typeIsTargetType(destinationClass, serviceProtocol)
            })
            assert(badDestinationClass == nil, "Registered service class (\(badDestinationClass!)) for router (\(route)) should conform to registered service adapter protocol (\(serviceProtocol)).")
        }
        
        // Router's defaultRouteConfiguration should conforms to registered module config protocols
        for (routeKey, route) in Registry.serviceModuleProtocolContainer {
            guard let routerType = ZIKAnyServiceRouterType.tryMakeType(forRoute: route) else {
                assertionFailure("Invalid route (\(route))")
                continue
            }
            let configProtocol = routeKey.type!
            let configType = type(of: routerType.defaultRouteConfiguration())
            assert(_swift_typeIsTargetType(configType, configProtocol), "The router (\(route))'s default configuration (\(configType)) must conform to the registered config protocol (\(configProtocol)).")
        }
        
        // Router's defaultRouteConfiguration should conforms to registered adapter module config protocols
        for (adapter, _) in Registry.serviceModuleAdapterContainer {
            assert(adapter.type != nil)
            guard let type = adapter.type, let routerType = Registry._swiftRouter(toServiceModule: type, name: adapter.key) else {
                assertionFailure("Service module adapter protocol(\(adapter.key)) is not registered with any router!")
                continue
            }
            var adapterProtocol: Any? = adapter.type
            if adapterProtocol == nil {
                adapterProtocol = NSProtocolFromString(adapter.key)
            }
            guard let configProtocol = adapterProtocol else {
                assertionFailure("Invalid adapter (\(adapter.key)), can't get its type")
                continue
            }
            let configType = Swift.type(of: routerType.defaultRouteConfiguration())
            assert(_swift_typeIsTargetType(configType, configProtocol), "The router (\(routerType))'s default configuration (\(configType)) must conform to the registered module adapter protocol (\(configProtocol)).")
        }
    }
}

#endif
