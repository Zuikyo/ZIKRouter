
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

/// Key of registered protocol.
extension _RouteKey {
    fileprivate init<Protocol>(routable: RoutableView<Protocol>) {
        self.init(type: Protocol.self, name: routable.typeName)
    }
    fileprivate init<Protocol>(routable: RoutableViewModule<Protocol>) {
        self.init(type: Protocol.self, name: routable.typeName)
    }
    #if DEBUG
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
    #endif
}

/// Registry for registering pure Swift protocol and discovering ZIKRouter subclass.
extension Registry {
    
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
        assert(zix_classIsSubclassOfClass(router, ZIKAnyViewRouter.self), "This router must be subclass of ZIKViewRouter")
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
        assert(zix_classIsSubclassOfClass(router, ZIKAnyViewRouter.self), "This router must be subclass of ZIKViewRouter")
        if let routableProtocol = _routableViewModuleProtocolFromObject(configProtocol), routableViewModule.typeName == routableProtocol.name {
            router.registerModuleProtocol(routableProtocol)
            return
        }
        assert(router.defaultRouteConfiguration() is Protocol, "The module config protocol (\(configProtocol)) should be conformed by the router (\(router))'s defaultRouteConfiguration (\(Swift.type(of: router.defaultRouteConfiguration()))).")
        assert(viewModuleProtocolContainer[_RouteKey(routable: routableViewModule)] == nil, "view config protocol (\(configProtocol)) was already registered with router (\(viewModuleProtocolContainer[_RouteKey(routable: routableViewModule)]!)).")
        viewModuleProtocolContainer[_RouteKey(routable: routableViewModule)] = router
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
    
    internal static func register<Adapter, Adaptee>(adapter: RoutableView<Adapter>, forAdaptee adaptee: RoutableView<Adaptee>) {
        var adapterKey = _RouteKey(routable: adapter)
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
        
        if let objcAdapter = objcAdapter {
            adapterKey = _RouteKey(type: Adapter.self, name: adapter.typeName, adapterProtocol: objcAdapter)
        }
        let adapteeKey: _RouteKey
        if let objcAdaptee = objcAdaptee {
            adapteeKey = _RouteKey(type: Adaptee.self, name: adaptee.typeName, adapterProtocol: objcAdaptee)
        } else {
            adapteeKey = _RouteKey(routable: adaptee)
        }
        
        viewAdapterContainer[adapterKey] = adapteeKey
    }
    
    internal static func register<Adapter, Adaptee>(adapter: RoutableViewModule<Adapter>, forAdaptee adaptee: RoutableViewModule<Adaptee>) {
        var adapterKey = _RouteKey(routable: adapter)
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
        
        if let objcAdapter = objcAdapter {
            adapterKey = _RouteKey(type: Adapter.self, name: adapter.typeName, adapterProtocol: objcAdapter)
        }
        let adapteeKey: _RouteKey
        if let objcAdaptee = objcAdaptee {
            adapteeKey = _RouteKey(type: Adaptee.self, name: adaptee.typeName, adapterProtocol: objcAdaptee)
        } else {
            adapteeKey = _RouteKey(routable: adaptee)
        }
        
        viewModuleAdapterContainer[adapterKey] = adapteeKey
    }
    
    internal static func register<Protocol>(_ routableView: RoutableView<Protocol>, forMakingView destinationClass: AnyClass) {
        let destinationProtocol = Protocol.self
#if DEBUG
        assert(_swift_typeIsTargetType(destinationClass, destinationProtocol), "Destination (\(destinationClass)) should conforms to protocol (\(destinationProtocol))")
#endif
        assert(ZIKAnyViewRouter.isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        // `UIViewController & ObjcProtocol` type is also a Protocol in objc, but we want to keep it in swift container
        if let routableProtocol = _routableViewProtocolFromObject(destinationProtocol), routableView.typeName == routableProtocol.name {
            ZIKAnyViewRouter.registerViewProtocol(routableProtocol, forMakingView: destinationClass)
            return
        }
        assert(_ZIKViewRouterToIdentifier(makingDestinationIdentifierPrefix + routableView.typeName) == nil, "Protocol (\(routableView.typeName)) already registered with router (\(_ZIKViewRouterToIdentifier(makingDestinationIdentifierPrefix + routableView.typeName)!.routeObject)), can't register for making destination (\(destinationClass))");
        ZIKAnyViewRouter.registerIdentifier(makingDestinationIdentifierPrefix + routableView.typeName, forMakingView: destinationClass)
    }
    
    internal static func register<Protocol>(_ routableView: RoutableView<Protocol>, forMakingView destinationClass: AnyClass, making factory: @escaping (ViewRouteConfig) -> Protocol?) {
        let destinationProtocol = Protocol.self
#if DEBUG
        assert(_swift_typeIsTargetType(destinationClass, destinationProtocol), "Destination (\(destinationClass)) should conforms to protocol (\(destinationProtocol))")
#endif
        assert(ZIKAnyViewRouter.isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        // `UIViewController & ObjcProtocol` type is also a Protocol in objc, but we want to keep it in swift container
        if let routableProtocol = _routableViewProtocolFromObject(destinationProtocol), routableView.typeName == routableProtocol.name {
            _registerViewProtocolWithSwiftFactory(routableProtocol, destinationClass, factory)
            return
        }
        assert(_ZIKViewRouterToIdentifier(makingDestinationIdentifierPrefix + routableView.typeName) == nil, "Protocol (\(routableView.typeName)) already registered with router (\(_ZIKViewRouterToIdentifier(makingDestinationIdentifierPrefix + routableView.typeName)!.routeObject)), can't register for making destination (\(destinationClass)) with factory (\(String(describing: factory)))");
        _registerViewIdentifierWithSwiftFactory(makingDestinationIdentifierPrefix + routableView.typeName, destinationClass, factory)
    }
    
    static func register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>, forMakingView destinationClass: AnyClass, making factory: @escaping () -> Protocol) {
        let destinationProtocol = Protocol.self
        assert(ZIKAnyViewRouter.isRegistrationFinished() == false, "Can't register after app did finish launch. Only register in registerRoutableDestination().")
        // `UIViewController & ObjcProtocol` type is also a Protocol in objc, but we want to keep it in swift container
        if let routableProtocol = _routableViewModuleProtocolFromObject(destinationProtocol), routableViewModule.typeName == routableProtocol.name {
            _registerViewModuleProtocolWithSwiftFactory(routableProtocol, destinationClass, factory)
            return
        }
        assert(_ZIKViewRouterToIdentifier(makingModuleIdentifierPrefix + routableViewModule.typeName) == nil, "Protocol (\(routableViewModule.typeName)) already registered with router (\(_ZIKViewRouterToIdentifier(makingModuleIdentifierPrefix + routableViewModule.typeName)!.routeObject)), can't register for making destination (\(destinationClass)) with factory (\(String(describing: factory)))");
        _registerViewModuleIdentifierWithSwiftFactory(makingModuleIdentifierPrefix + routableViewModule.typeName, destinationClass, factory)
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
    
    #endif
}

// MARK: Adapter

extension ZIKViewRouteRegistry {
    @objc class func _swiftRouteForDestinationAdapter(_ adapter: Protocol) -> Any? {
        guard let adaptee = Registry.viewAdapterContainer[_RouteKey(protocol: adapter)] else {
            return nil
        }
        return Registry._swiftRouter(toViewKey: adaptee)?.routeObject
    }
    
    @objc class func _swiftRouteForModuleAdapter(_ adapter: Protocol) -> Any? {
        guard let adaptee = Registry.viewModuleAdapterContainer[_RouteKey(protocol: adapter)] else {
            return nil
        }
        return Registry._swiftRouter(toViewModuleKey: adaptee)?.routeObject
    }
}

// MARK: Routable Discover
internal extension Registry {
    
    /// Get view router type for registered view protocol.
    ///
    /// - Parameter routableView: A routabe entry carrying a view protocol conformed by the view registered with a view router. Support objc protocol and pure Swift protocol.
    /// - Returns: The view router type for the view protocol.
    static func router<Destination>(to routableView: RoutableView<Destination>) -> ViewRouterType<Destination, ViewRouteConfig>? {
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
    static func router<Module>(to routableViewModule: RoutableViewModule<Module>) -> ViewRouterType<Any, Module>? {
        let routerType = _router(toViewModule: Module.self , name: routableViewModule.typeName)
        if let routerType = routerType {
            return ViewRouterType(routerType: routerType)
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
    static func router(to switchableView: SwitchableView) -> ViewRouterType<Any, ViewRouteConfig>? {
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
    static func router(to switchableViewModule: SwitchableViewModule) -> ViewRouterType<Any, ViewRouteConfig>? {
        let routerType = _router(toViewModule: switchableViewModule.routableProtocol, name: switchableViewModule.typeName)
        if let routerType = routerType {
            return ViewRouterType(routerType: routerType)
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
    static func _router(toView viewProtocol: Any.Type, name: String) -> ZIKAnyViewRouterType? {
        if let routerType = _swiftRouter(toViewKey: _RouteKey(type: viewProtocol, name: name)) {
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
    
    static func _swiftRouter(toViewKey viewRouteKey: _RouteKey) -> ZIKAnyViewRouterType? {
        if let route = viewProtocolContainer[viewRouteKey], let routerType = ZIKAnyViewRouterType.tryMakeType(forRoute: route) {
            return routerType
        }
        if let routerType = _ZIKViewRouterToIdentifier(makingDestinationIdentifierPrefix + viewRouteKey.key) {
            return routerType
        }
        #if DEBUG
        var traversedProtocols: [_RouteKey] = []
        #endif
        var adapter = viewRouteKey
        var adaptee: _RouteKey?
        repeat {
            adaptee = viewAdapterContainer[adapter]
            if let adaptee = adaptee {
                if let route = viewProtocolContainer[adaptee], let routerType = ZIKAnyViewRouterType.tryMakeType(forRoute: route) {
                    return routerType
                }
                if let adapteeProtocol = adaptee.adapterProtocol,
                    let routableProtocol = _routableViewProtocolFromObject(adapteeProtocol),
                    let routerType = _ZIKViewRouterToView(routableProtocol) {
                    return routerType
                }
                if let routerType = _ZIKViewRouterToIdentifier(makingDestinationIdentifierPrefix + adaptee.key) {
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
    static func _router(toViewModule configProtocol: Any.Type, name: String) -> ZIKAnyViewRouterType? {
        if let routerType = _swiftRouter(toViewModuleKey: _RouteKey(type: configProtocol, name: name)) {
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
    
    static func _swiftRouter(toViewModuleKey moduleRouteKey: _RouteKey) -> ZIKAnyViewRouterType? {
        if let route = viewModuleProtocolContainer[moduleRouteKey], let routerType = ZIKAnyViewRouterType.tryMakeType(forRoute: route) {
            return routerType
        }
        if let routerType = _ZIKViewRouterToIdentifier(makingModuleIdentifierPrefix + moduleRouteKey.key) {
            return routerType
        }
        #if DEBUG
        var traversedProtocols: [_RouteKey] = []
        #endif
        var adapter = moduleRouteKey
        var adaptee: _RouteKey?
        repeat {
            adaptee = viewModuleAdapterContainer[adapter]
            if let adaptee = adaptee {
                if let route = viewModuleProtocolContainer[adaptee], let routerType = ZIKAnyViewRouterType.tryMakeType(forRoute: route) {
                    return routerType
                }
                if let adapteeProtocol = adaptee.adapterProtocol,
                    let routableProtocol = _routableViewModuleProtocolFromObject(adapteeProtocol),
                    let routerType = _ZIKViewRouterToModule(routableProtocol) {
                    return routerType
                }
                if let routerType = _ZIKViewRouterToIdentifier(makingModuleIdentifierPrefix + adaptee.key) {
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
    class func validateConformance(destination: Any, inViewRouterType routerType: ZIKAnyViewRouterType) -> Bool {
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
}

#if DEBUG

/// Make sure all registered view classes conform to their registered view protocols.
private class _ViewRouterValidater: ZIKViewRouteAdapter {
    override class func isAbstractRouter() -> Bool {
        return true
    }
    override class func _didFinishRegistration() {
        
        var errorDescription = ""
        // Declared protocols in extension of RoutableView and RoutableViewModule should be registered
        var declaredRoutableTypes = [String]()
        // Types in method signature used as RoutableView<Type>(), RoutableView<Type>(declaredProtocol: Type.self) and RoutableView<Type>(declaredTypeName: typeName), maybe not declared yet
        var viewRoutingTypes = [(String, String)]()
        // Types in method signature used as RoutableViewModule<Type>(), RoutableViewModule<Type>(declaredProtocol: Type.self) and RoutableViewModule<Type>(declaredTypeName: typeName), maybe not declared yet
        var viewModuleRoutingTypes = [(String, String)]()
        let viewRoutingTypeRegex = try! NSRegularExpression(pattern: "(?<=RoutableView<).*(?=>$)", options: [.anchorsMatchLines])
        let viewModuleRoutingTypeRegex = try! NSRegularExpression(pattern: "(?<=RoutableViewModule<).*(?=>$)", options: [.anchorsMatchLines])
        zix_enumerateSymbolName { (name, demangledAsSwift) -> Bool in            
            if (strstr(name, "RoutableView") != nil) {
                let symbolName = demangledAsSwift(name, false)
                if symbolName.hasPrefix("(extension in"), symbolName.contains(">.init") {
                    if symbolName.contains("(extension in ZRouter)") == false {
                        let simplifiedName = demangledAsSwift(name, true)
                        declaredRoutableTypes.append(simplifiedName)
                    } else if symbolName.contains("." + String(describing: ViewController.self)), symbolName.contains(".ZIKViewRoutable") {
                        let imagePath = imagePathOfAddress(name)
                        assert(imagePath.contains("/ZRouter.framework/") || !zix_hasDynamicLibrary("ZRouter"), """
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
                        assert(imagePath.contains("/ZRouter.framework/") || !zix_hasDynamicLibrary("ZRouter"), """
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
                        assert(imagePath.contains("/ZRouter.framework/") || !zix_hasDynamicLibrary("ZRouter"), """
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
                        assert(imagePath.contains("/ZRouter.framework/") || !zix_hasDynamicLibrary("ZRouter"), """
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
                        viewRoutingTypes.append((routingType, simplifiedRoutingType.undotted))
                    }
                } else if symbolName.hasPrefix("type metadata accessor for ZRouter.RoutableViewModule<") {
                    let simplifiedName = demangledAsSwift(name, true)
                    if let routingType = symbolName.subString(forRegex: viewModuleRoutingTypeRegex),
                        let simplifiedRoutingType = simplifiedName.subString(forRegex: viewModuleRoutingTypeRegex) {
                        viewModuleRoutingTypes.append((routingType, simplifiedRoutingType.undotted))
                    }
                }
            }
            return true
        }
        
        let destinationProtocolRegex = try! NSRegularExpression(pattern: "(?<=-> ZRouter.RoutableView<)(.)*.*(?=>$)", options: [.anchorsMatchLines])
        let moduleProtocolRegex = try! NSRegularExpression(pattern: "(?<=-> ZRouter.RoutableViewModule<)(.)*.*(?=>$)", options: [.anchorsMatchLines])
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
            if !(Registry.viewProtocolContainer.keys.contains(_RouteKey(key: declaredProtocol)) ||
                Registry.viewAdapterContainer.keys.contains(_RouteKey(key: declaredProtocol)) ||
                _ZIKViewRouterToIdentifier(Registry.makingDestinationIdentifierPrefix + declaredProtocol) != nil) {
                errorDescription.append("\n\n❌Declared view protocol (\(declaredProtocol)) is not registered with any router.")
            }
        }
        for declaredProtocol in declaredModuleProtocols {
            if !(Registry.viewModuleProtocolContainer.keys.contains(_RouteKey(key: declaredProtocol)) ||
                Registry.viewModuleAdapterContainer.keys.contains(_RouteKey(key: declaredProtocol)) ||
                _ZIKViewRouterToIdentifier(Registry.makingModuleIdentifierPrefix + declaredProtocol) != nil) {
                errorDescription.append("\n\n❌Declared view module config protocol (\(declaredProtocol)) is not registered with any router.")
            }
        }
        
        for (routingType, simplifiedName) in viewRoutingTypes {
            var routingTypeName = routingType
            var routableProtocol: Protocol?
            if routingTypeName.hasPrefix("__ObjC.") {
                routingTypeName = simplifiedName
            }
            if let objcProtocol = NSProtocolFromString(routingTypeName) {
                routableProtocol = _routableViewProtocolFromObject(objcProtocol)
            }
            if !(declaredDestinationProtocols.contains(simplifiedName) || routableProtocol != nil) {
                errorDescription.append("\n\n❌Find invalid generic type usage for routing: RoutableView<\(simplifiedName)>. You should only use declared protocol type as generic type, don't use \"RoutableView<\(simplifiedName)>\" or \"RoutableView(declaredProtocol:\(simplifiedName))\" in your code !")
            }
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
            if !(declaredModuleProtocols.contains(simplifiedName) || routableProtocol != nil) {
                errorDescription.append("\n\n❌Find invalid generic type usage for routing: RoutableViewModule<\(simplifiedName)>. You should only use declared protocol type as generic type, don't use \"RoutableViewModule<\(simplifiedName)>\" or \"RoutableViewModule(declaredProtocol:\(simplifiedName))\" in your code!")
            }
        }
        
        // Destination should conform to registered destination protocols
        for (routeKey, route) in Registry.viewProtocolContainer {
            let viewProtocol = routeKey.type!
            let badDestinationClass: AnyClass? = ZIKViewRouteRegistry.validateDestinations(forRoute: route, handler: { (destinationClass) -> Bool in
                return _swift_typeIsTargetType(destinationClass, viewProtocol)
            })
            if badDestinationClass != nil {
                errorDescription.append("\n\n❌Registered view class (\(badDestinationClass!)) for router (\(route)) should conform to registered view protocol (\(viewProtocol)).")
            }
        }
        
        // Destination should conforms to registered adapter destination protocols
        for (adapter, _) in Registry.viewAdapterContainer {
            assert(adapter.type != nil)
            guard let routerType = Registry._swiftRouter(toViewKey: adapter) else {
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
            if badDestinationClass != nil {
                errorDescription.append("\n\n❌Registered view class (\(badDestinationClass!)) for router (\(route)) should conform to registered view adapter protocol (\(viewProtocol)).")
            }
        }
        
        // Router's defaultRouteConfiguration should conforms to registered module config protocols
        for (routeKey, route) in Registry.viewModuleProtocolContainer {
            guard let routerType = ZIKAnyViewRouterType.tryMakeType(forRoute: route) else {
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
        for (adapter, _) in Registry.viewModuleAdapterContainer {
            assert(adapter.type != nil)
            guard let routerType = Registry._swiftRouter(toViewModuleKey: adapter) else {
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
            if _swift_typeIsTargetType(configType, configProtocol) == false {
                errorDescription.append("\n\n❌The router (\(routerType))'s default configuration (\(configType)) must conform to the registered adapter config protocol (\(configProtocol)).")
            }
        }
        
        if errorDescription.count > 0 {
            print("\n❌Found router implementation errors: \(errorDescription)")
            assertionFailure("Found router implementation errors")
        }
    }
}

#endif
