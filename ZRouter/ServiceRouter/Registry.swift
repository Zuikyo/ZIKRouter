
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
        if let dotRange = name.range(of: ".", options: .backwards) {
            name.removeSubrange(name.startIndex...dotRange.lowerBound)
        }
        return name
    }
}

/// Key of registered protocol.
internal struct _RouteKey: Hashable {
    #if DEBUG
    /// Routable type
    internal let type: Any.Type?
    #endif
    internal let key: String
    internal private(set) var adapterProtocol: Protocol?
    internal init(type: Any.Type, name: String) {
        assert(name == String(describing: type), "name should be equal to String(describing:) of \(type)")
        #if DEBUG
        self.type = type
        #endif
        key = name
        assert(key.contains(".") == false, "Key shouldn't contain module prefix.")
    }
    internal init(protocol p: Protocol) {
        #if DEBUG
        self.type = nil
        #endif
        key = p.name
        adapterProtocol = p
        assert(key.contains(".") == false, "Remove module prefix for swift type.")
    }
    internal init(adapterProtocol p: Protocol) {
        #if DEBUG
        self.type = nil
        #endif
        key = p.name
        adapterProtocol = p
    }
    internal init(type: Any.Type, name: String, adapterProtocol p: Protocol) {
        #if DEBUG
        self.type = type
        #endif
        key = name
        adapterProtocol = p
        assert(key == String(describing: type), "name should be equal to String(describing:) of \(type)")
        assert(key.contains(".") == false, "Key shouldn't contain module prefix.")
    }
    fileprivate init<Protocol>(routable: RoutableService<Protocol>) {
        self.init(type: Protocol.self, name: routable.typeName)
    }
    fileprivate init<Protocol>(routable: RoutableServiceModule<Protocol>) {
        self.init(type: Protocol.self, name: routable.typeName)
    }
    #if DEBUG
    internal init(type: AnyClass) {
        self.type = type
        key = String(describing:type)
        assert(key.contains(".") == false, "Key shouldn't contain module prefix.")
    }
    internal init(route: Any) {
        self.type = nil
        key = String(describing:route)
    }
    /// Used for checking declared protocol names.
    internal init(key: String) {
        type = nil
        self.key = key
        assert(key.contains(".") == false, "Remove module prefix for swift type.")
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
    func hash(into hasher: inout Hasher) {
        hasher.combine(key.hashValue)
    }
    static func ==(lhs: _RouteKey, rhs: _RouteKey) -> Bool {
        return lhs.key == rhs.key
    }
}

/// Registry for registering pure Swift protocol and discovering ZIKRouter subclass.
internal class Registry {
    /// value: subclass of ZIKViewRouter or ZIKViewRoute
    internal static var viewProtocolContainer = [_RouteKey: Any]()
    /// value: subclass of ZIKViewRouter or ZIKViewRoute
    internal static var viewModuleProtocolContainer = [_RouteKey: Any]()
    /// key: adapter view protocol  value: adaptee view protocol
    internal static var viewAdapterContainer = [_RouteKey: _RouteKey]()
    /// key: adapter view module protocol  value: adaptee view module protocol
    internal static var viewModuleAdapterContainer = [_RouteKey: _RouteKey]()
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
    internal static var _check_viewProtocolContainer = [_RouteKey: Set<_RouteKey>]()
    /// key: subclass of ZIKServiceRouter or ZIKServiceRoute  value: set of routable service protocols
    fileprivate static var _check_serviceProtocolContainer = [_RouteKey: Set<_RouteKey>]()
    #endif
    
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
        assert(zix_classIsSubclassOfClass(router, ZIKAnyServiceRouter.self), "This router must be subclass of ZIKServiceRouter")
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
        assert(zix_classIsSubclassOfClass(router, ZIKAnyServiceRouter.self), "This router must be subclass of ZIKServiceRouter")
        if let routableProtocol = _routableServiceModuleProtocolFromObject(configProtocol), routableServiceModule.typeName == routableProtocol.name {
            router.registerModuleProtocol(routableProtocol)
            return
        }
        assert(router.defaultRouteConfiguration() is Protocol, "The module config protocol (\(configProtocol)) should be conformed by the router (\(router))'s defaultRouteConfiguration (\(Swift.type(of: router.defaultRouteConfiguration()))).")
        assert(serviceModuleProtocolContainer[_RouteKey(routable: routableServiceModule)] == nil, "service config protocol (\(configProtocol)) was already registered with router (\(serviceModuleProtocolContainer[_RouteKey(routable: routableServiceModule)]!)).")
        serviceModuleProtocolContainer[_RouteKey(routable: routableServiceModule)] = router
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
    
    internal static func register<Adapter, Adaptee>(adapter: RoutableService<Adapter>, forAdaptee adaptee: RoutableService<Adaptee>) {
        var adapterKey = _RouteKey(routable: adapter)
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
        
        if let objcAdapter = objcAdapter {
            adapterKey = _RouteKey(type: Adapter.self, name: adapter.typeName, adapterProtocol: objcAdapter)
        }
        let adapteeKey: _RouteKey
        if let objcAdaptee = objcAdaptee {
            adapteeKey = _RouteKey(type: Adaptee.self, name: adaptee.typeName, adapterProtocol: objcAdaptee)
        } else {
            adapteeKey = _RouteKey(routable: adaptee)
        }
        
        serviceAdapterContainer[adapterKey] = adapteeKey
    }
    
    internal static func register<Adapter, Adaptee>(adapter: RoutableServiceModule<Adapter>, forAdaptee adaptee: RoutableServiceModule<Adaptee>) {
        var adapterKey = _RouteKey(routable: adapter)
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
        
        if let objcAdapter = objcAdapter {
            adapterKey = _RouteKey(type: Adapter.self, name: adapter.typeName, adapterProtocol: objcAdapter)
        }
        let adapteeKey: _RouteKey
        if let objcAdaptee = objcAdaptee {
            adapteeKey = _RouteKey(type: Adaptee.self, name: adaptee.typeName, adapterProtocol: objcAdaptee)
        } else {
            adapteeKey = _RouteKey(routable: adaptee)
        }
        
        serviceModuleAdapterContainer[adapterKey] = adapteeKey
    }
    
    internal static let makingDestinationIdentifierPrefix = "~SwiftMakingDestination~"
    internal static let makingModuleIdentifierPrefix = "~SwiftMakingModule~"
    
    internal static func register<Protocol>(_ routableService: RoutableService<Protocol>, forMakingService destinationClass: AnyClass) {
        let destinationProtocol = Protocol.self
#if DEBUG
        assert(_swift_typeIsTargetType(destinationClass, destinationProtocol), "Destination (\(destinationClass)) should conforms to protocol (\(destinationProtocol))")
#endif
        assert(ZIKAnyServiceRouter.isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        // `UIViewController & ObjcProtocol` type is also a Protocol in objc, but we want to keep it in swift container
        if let routableProtocol = _routableServiceProtocolFromObject(destinationProtocol), routableService.typeName == routableProtocol.name {
            ZIKAnyServiceRouter.registerServiceProtocol(routableProtocol, forMakingService: destinationClass)
            return
        }
        assert(_ZIKServiceRouterToIdentifier(makingDestinationIdentifierPrefix + routableService.typeName) == nil, "Protocol (\(routableService.typeName)) already registered with router (\(_ZIKServiceRouterToIdentifier(makingDestinationIdentifierPrefix + routableService.typeName)!.routeObject)), can't register for making destination (\(destinationClass))");
        ZIKAnyServiceRouter.registerIdentifier(makingDestinationIdentifierPrefix + routableService.typeName, forMakingService: destinationClass)
    }
    
    static func register<Protocol>(_ routableService: RoutableService<Protocol>, forMakingService destinationClass: AnyClass, making factory: @escaping (PerformRouteConfig) -> Protocol?) {
        let destinationProtocol = Protocol.self
#if DEBUG
        assert(_swift_typeIsTargetType(destinationClass, destinationProtocol), "Destination (\(destinationClass)) should conforms to protocol (\(destinationProtocol))")
#endif
        assert(ZIKAnyServiceRouter.isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        // `UIViewController & ObjcProtocol` type is also a Protocol in objc, but we want to keep it in swift container
        if let routableProtocol = _routableServiceProtocolFromObject(destinationProtocol), routableService.typeName == routableProtocol.name {
            _registerServiceProtocolWithSwiftFactory(routableProtocol, destinationClass, factory)
            return
        }
        assert(_ZIKServiceRouterToIdentifier(makingDestinationIdentifierPrefix + routableService.typeName) == nil, "Protocol (\(routableService.typeName)) already registered with router (\(_ZIKServiceRouterToIdentifier(makingDestinationIdentifierPrefix + routableService.typeName)!.routeObject)), can't register for making destination (\(destinationClass)) with factory (\(String(describing: factory)))");
        _registerServiceIdentifierWithSwiftFactory(makingDestinationIdentifierPrefix + routableService.typeName, destinationClass, factory)
    }
    
    static func register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>, forMakingService destinationClass: AnyClass, making factory: @escaping () -> Protocol) {
        let destinationProtocol = Protocol.self
        assert(ZIKAnyServiceRouter.isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        // `UIViewController & ObjcProtocol` type is also a Protocol in objc, but we want to keep it in swift container
        if let routableProtocol = _routableServiceModuleProtocolFromObject(destinationProtocol), routableServiceModule.typeName == routableProtocol.name {
            _registerServiceModuleProtocolWithSwiftFactory(routableProtocol, destinationClass, factory)
            return
        }
        assert(_ZIKServiceRouterToIdentifier(makingModuleIdentifierPrefix + routableServiceModule.typeName) == nil, "Protocol (\(routableServiceModule.typeName)) already registered with router (\(_ZIKServiceRouterToIdentifier(makingModuleIdentifierPrefix + routableServiceModule.typeName)!.routeObject)), can't register for making destination (\(destinationClass)) with factory (\(String(describing: factory)))");
        _registerServiceModuleIdentifierWithSwiftFactory(makingModuleIdentifierPrefix + routableServiceModule.typeName, destinationClass, factory)
    }
    
    // MARK: Validate
    
    #if DEBUG
    
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

extension ZIKServiceRouteRegistry {
    @objc class func _swiftRouteForDestinationAdapter(_ adapter: Protocol) -> Any? {
        if let adaptee = Registry.serviceAdapterContainer[_RouteKey(protocol: adapter)] {
            return Registry._swiftRouter(toServiceKey: adaptee)?.routeObject
        }
        return nil
    }
    
    @objc class func _swiftRouteForModuleAdapter(_ adapter: Protocol) -> Any? {
        if let adaptee = Registry.serviceModuleAdapterContainer[_RouteKey(protocol: adapter)] {
            return Registry._swiftRouter(toServiceModuleKey: adaptee)?.routeObject
        }
        return nil
    }
}

// MARK: Routable Discover
internal extension Registry {
    
    /// Get service router type for registered service protocol.
    ///
    /// - Parameter routableService: A routabe entry carrying a service protocol conformed by the service registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Returns: The service router type for the service protocol.
    static func router<Destination>(to routableService: RoutableService<Destination>) -> ServiceRouterType<Destination, PerformRouteConfig>? {
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
    static func router<Module>(to routableServiceModule: RoutableServiceModule<Module>) -> ServiceRouterType<Any, Module>? {
        let routerType = _router(toServiceModule: Module.self, name: routableServiceModule.typeName)
        if let routerType = routerType {
            return ServiceRouterType(routerType: routerType)
        }
        return nil
    }
}

// MARK: Switchable Discover

internal extension Registry {
    
    /// Get service router type for switchable registered service protocol, when the destination service is switchable from some service protocols.
    ///
    /// - Parameter switchableService: A struct carrying any routable service protocol, but not a specified one.
    /// - Returns: The service router type for the service protocol.
    static func router(to switchableService: SwitchableService) -> ServiceRouterType<Any, PerformRouteConfig>? {
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
    static func router(to switchableServiceModule: SwitchableServiceModule) -> ServiceRouterType<Any, PerformRouteConfig>? {
        let routerType = _router(toServiceModule: switchableServiceModule.routableProtocol, name: switchableServiceModule.typeName)
        if let routerType = routerType {
            return ServiceRouterType(routerType: routerType)
        }
        return nil
    }
}

// MARK: Type Discover

fileprivate extension Registry {
    
    /// Get service router class for registered service protocol.
    ///
    /// - Parameter serviceProtocol: Service protocol conformed by the service registered with a service router. Support objc protocol and pure Swift protocol.
    /// - Parameter name: The name of the protocol.
    /// - Returns: The service router class for the service protocol.
    static func _router(toService serviceProtocol: Any.Type, name: String) -> ZIKAnyServiceRouterType? {
        if let routerType = _swiftRouter(toServiceKey: _RouteKey(type: serviceProtocol, name: name)) {
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
    
    static func _swiftRouter(toServiceKey serviceRouteKey: _RouteKey) -> ZIKAnyServiceRouterType? {
        if let route = serviceProtocolContainer[serviceRouteKey], let routerType = ZIKAnyServiceRouterType.tryMakeType(forRoute: route) {
            return routerType
        }
        if let routerType = _ZIKServiceRouterToIdentifier(makingDestinationIdentifierPrefix + serviceRouteKey.key) {
            return routerType
        }
        #if DEBUG
        var traversedProtocols: [_RouteKey] = []
        #endif
        var adapter = serviceRouteKey
        var adaptee: _RouteKey?
        repeat {
            adaptee = serviceAdapterContainer[adapter]
            if let adaptee = adaptee {
                if let route = serviceProtocolContainer[adaptee], let routerType = ZIKAnyServiceRouterType.tryMakeType(forRoute: route) {
                    return routerType
                }
                if let adapteeProtocol = adaptee.adapterProtocol,
                    let routableProtocol = _routableServiceProtocolFromObject(adapteeProtocol),
                    let routerType = _ZIKServiceRouterToService(routableProtocol) {
                    return routerType
                }
                if let routerType = _ZIKServiceRouterToIdentifier(makingDestinationIdentifierPrefix + adaptee.key) {
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
    static func _router(toServiceModule configProtocol: Any.Type, name: String) -> ZIKAnyServiceRouterType? {
        if let routerType = _swiftRouter(toServiceModuleKey: _RouteKey(type: configProtocol, name: name)) {
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
    
    static func _swiftRouter(toServiceModuleKey moduleRouteKey: _RouteKey) -> ZIKAnyServiceRouterType? {
        if let route = serviceModuleProtocolContainer[moduleRouteKey], let routerType = ZIKAnyServiceRouterType.tryMakeType(forRoute: route) {
            return routerType
        }
        if let routerType = _ZIKServiceRouterToIdentifier(makingModuleIdentifierPrefix + moduleRouteKey.key) {
            return routerType
        }
        #if DEBUG
        var traversedProtocols: [_RouteKey] = []
        #endif
        var adapter = moduleRouteKey
        var adaptee: _RouteKey?
        repeat {
            adaptee = serviceModuleAdapterContainer[adapter]
            if let adaptee = adaptee {
                if let route = serviceModuleProtocolContainer[adaptee], let routerType = ZIKAnyServiceRouterType.tryMakeType(forRoute: route) {
                    return routerType
                }
                if let adapteeProtocol = adaptee.adapterProtocol,
                    let routableProtocol = _routableServiceModuleProtocolFromObject(adapteeProtocol),
                    let routerType = _ZIKServiceRouterToModule(routableProtocol) {
                    return routerType
                }
                if let routerType = _ZIKServiceRouterToIdentifier(makingModuleIdentifierPrefix + adaptee.key) {
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
    class func validateConformance(destination: Any, inServiceRouterType routerType: ZIKAnyServiceRouterType) -> Bool {
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

internal extension String {
    var undotted: String {
        var undotted = self
        if undotted.contains(" & ") {
            let strs = self.components(separatedBy: " & ").map({ (str: String) -> String in
                var str = str
                if let dotRange = str.range(of: ".", options: .backwards)  {
                    str.removeSubrange(str.startIndex...dotRange.lowerBound)
                }
                return str
            })
            return strs.joined(separator: " & ")
        }
        if let dotRange = undotted.range(of: ".", options: .backwards)  {
            undotted.removeSubrange(undotted.startIndex...dotRange.lowerBound)
        }
        return undotted
    }
}

/// Make sure all registered service classes conform to their registered service protocols.
private class _ServiceRouterValidater: ZIKServiceRouteAdapter {
    override class func isAbstractRouter() -> Bool {
        return true
    }
    override class func _didFinishRegistration() {
        
        var errorDescription = ""
        // Declared protocol in extension of RoutableService and RoutableServiceModule should be registered
        var declaredRoutableTypes = [String]()
        // Types in method signature used as RoutableService<Type>(), RoutableService<Type>(declaredProtocol: Type.self) and RoutableService<Type>(declaredTypeName: typeName), maybe not declared yet
        var serviceRoutingTypes = [(String, String)]()
        // Types in method signature used as RoutableServiceModule<Type>(), RoutableServiceModule<Type>(declaredProtocol: Type.self) and RoutableServiceModule<Type>(declaredTypeName: typeName), maybe not declared yet
        var serviceModuleRoutingTypes = [(String, String)]()
        
        let serviceRoutingTypeRegex = try! NSRegularExpression(pattern: "(?<=RoutableService<).*(?=>$)", options: [.anchorsMatchLines])
        let serviceModuleRoutingTypeRegex = try! NSRegularExpression(pattern: "(?<=RoutableServiceModule<).*(?=>$)", options: [.anchorsMatchLines])
        zix_enumerateSymbolName { (name, demangledAsSwift) -> Bool in
            if (strstr(name, "RoutableService") != nil) {
                let symbolName = demangledAsSwift(name, false)
                if symbolName.hasPrefix("(extension in"), symbolName.contains(">.init") {
                    if symbolName.contains("(extension in ZRouter)") == false {
                        let simplifiedName = demangledAsSwift(name, true)
                        declaredRoutableTypes.append(simplifiedName)
                    } else if symbolName.contains(".NSObject"), symbolName.contains(".ZIKServiceRoutable") {
                        let imagePath = imagePathOfAddress(name)
                        assert(imagePath.contains("/ZRouter.framework/") || !zix_hasDynamicLibrary("ZRouter"), """
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
                        assert(imagePath.contains("/ZRouter.framework/") || !zix_hasDynamicLibrary("ZRouter"), """
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
                        assert(imagePath.contains("/ZRouter.framework/") || !zix_hasDynamicLibrary("ZRouter"), """
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
                        serviceRoutingTypes.append((routingType, simplifiedRoutingType.undotted))
                    }
                } else if symbolName.hasPrefix("type metadata accessor for ZRouter.RoutableServiceModule<") {
                    let simplifiedName = demangledAsSwift(name, true)
                    if let routingType = symbolName.subString(forRegex: serviceModuleRoutingTypeRegex),
                        let simplifiedRoutingType = simplifiedName.subString(forRegex: serviceModuleRoutingTypeRegex) {
                        serviceModuleRoutingTypes.append((routingType, simplifiedRoutingType.undotted))
                    }
                }
            }
            return true
        }
        
        let destinationProtocolRegex = try! NSRegularExpression(pattern: "(?<=-> ZRouter.RoutableService<)(.)*.*(?=>$)", options: [.anchorsMatchLines])
        let moduleProtocolRegex = try! NSRegularExpression(pattern: "(?<=-> ZRouter.RoutableServiceModule<)(.)*.*(?=>$)", options: [.anchorsMatchLines])
        var declaredDestinationProtocols = [String]()
        var declaredModuleProtocols = [String]()
        for declaration in declaredRoutableTypes {
            if let declaredProtocol = declaration.subString(forRegex: destinationProtocolRegex) {
                declaredDestinationProtocols.append(declaredProtocol.undotted)
            } else if let declaredProtocol = declaration.subString(forRegex: moduleProtocolRegex) {
                declaredModuleProtocols.append(declaredProtocol.undotted)
            }
        }
        
        for declaredProtocol in declaredDestinationProtocols {
            if !(Registry.serviceProtocolContainer.keys.contains(_RouteKey(key: declaredProtocol)) ||
                Registry.serviceAdapterContainer.keys.contains(_RouteKey(key: declaredProtocol)) ||
                _ZIKServiceRouterToIdentifier(Registry.makingDestinationIdentifierPrefix + declaredProtocol) != nil) {
                errorDescription.append("\n\n❌Declared service protocol (\(declaredProtocol)) is not registered with any router.")
            }
        }
        for declaredProtocol in declaredModuleProtocols {
            if !(Registry.serviceModuleProtocolContainer.keys.contains(_RouteKey(key: declaredProtocol)) ||
                Registry.serviceModuleAdapterContainer.keys.contains(_RouteKey(key: declaredProtocol)) ||
                _ZIKServiceRouterToIdentifier(Registry.makingModuleIdentifierPrefix + declaredProtocol) != nil) {
                errorDescription.append("\n\n❌Declared service module config protocol (\(declaredProtocol)) is not registered with any router.")
            }
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
            if !(declaredDestinationProtocols.contains(simplifiedName) || routableProtocol != nil) {
                errorDescription.append("\n\n❌Find invalid generic type usage for routing: RoutableService<\(simplifiedName)>. You should only use declared protocol type as generic type, don't use \"RoutableService<\(simplifiedName)>\" or \"RoutableService(declaredProtocol:\(simplifiedName))\" in your code!")
            }
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
            if !(declaredModuleProtocols.contains(simplifiedName) || routableProtocol != nil) {
                errorDescription.append("\n\n❌Find invalid generic type usage for routing: RoutableServiceModule<\(simplifiedName)>. You should only use declared protocol type as generic type, don't use \"RoutableServiceModule<\(simplifiedName)>\" or \"RoutableServiceModule(declaredProtocol:\(simplifiedName))\" in your code!")
            }
        }
        
        // Destination should conforms to registered destination protocols
        for (routeKey, route) in Registry.serviceProtocolContainer {
            let serviceProtocol = routeKey.type!
            let badDestinationClass: AnyClass? = ZIKServiceRouteRegistry.validateDestinations(forRoute: route, handler: { (destinationClass) -> Bool in
                return _swift_typeIsTargetType(destinationClass, serviceProtocol)
            })
            if badDestinationClass != nil {
                errorDescription.append("\n\n❌Registered service class (\(badDestinationClass!)) for router (\(route)) should conform to registered service protocol (\(serviceProtocol)).")
            }
        }
        
        // Destination should conforms to registered adapter destination protocols
        for (adapter, _) in Registry.serviceAdapterContainer {
            assert(adapter.type != nil)
            guard let routerType = Registry._swiftRouter(toServiceKey: adapter) else {
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
            if badDestinationClass != nil {
                errorDescription.append("\n\n❌Registered service class (\(badDestinationClass!)) for router (\(route)) should conform to registered service adapter protocol (\(serviceProtocol)).")
            }
        }
        
        // Router's defaultRouteConfiguration should conforms to registered module config protocols
        for (routeKey, route) in Registry.serviceModuleProtocolContainer {
            guard let routerType = ZIKAnyServiceRouterType.tryMakeType(forRoute: route) else {
                assertionFailure("Invalid route (\(route))")
                continue
            }
            let configProtocol = routeKey.type!
            let configType = type(of: routerType.defaultRouteConfiguration())
            if _swift_typeIsTargetType(configType, configProtocol) == false {
                errorDescription.append("\n\n❌The router (\(route))'s default configuration (\(configType)) must conform to the registered config protocol (\(configProtocol)).")
            }
        }
        
        // Router's defaultRouteConfiguration should conforms to registered adapter module config protocols
        for (adapter, _) in Registry.serviceModuleAdapterContainer {
            assert(adapter.type != nil)
            guard let routerType = Registry._swiftRouter(toServiceModuleKey: adapter) else {
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
            if _swift_typeIsTargetType(configType, configProtocol) == false {
                errorDescription.append("\n\n❌The router (\(routerType))'s default configuration (\(configType)) must conform to the registered module adapter protocol (\(configProtocol)).")
            }
        }
        
        if errorDescription.count > 0 {
            print("\n❌Found router implementation errors: \(errorDescription)")
            assertionFailure("Found router implementation errors")
        }
    }
}

#endif
