//
//  SwiftServiceRouter.swift
//  ZRouter
//
//  Created by zuik on 2017/11/25.
//  Copyright © 2017 zuik. All rights reserved.
//

import ZIKRouter

public protocol RouteConfig: class {
    var errorHandler: ((ZIKRouteAction, Error) -> Void)? { get set }
    var successHandler: (() -> Void)? { get set }
}

 public protocol PerformRouteConfig: RouteConfig {
    var prepareDestination: ((Any) -> Void)? { get set }
    var routeCompletion: ((Any) -> Void)? { get set }
}

public protocol RemoveRouteConfig: RouteConfig {
    var prepareDestination: ((Any) -> Void)? { get set }
}

extension ZIKRouteConfiguration: RouteConfig {
    public var errorHandler: ((ZIKRouteAction, Error) -> Void)? {
        get {
            return self.oc_errorHandler
        }
        set {
            self.oc_errorHandler = newValue
        }
    }
    public var successHandler: (() -> Void)? {
        get {
            return self.oc_successHandler
        }
        set {
            self.oc_successHandler = newValue
        }
    }
}

extension ZIKPerformRouteConfiguration: PerformRouteConfig {
    public var routeCompletion: ((Any) -> Void)? {
        get {
            return self.oc_routeCompletion
        }
        set {
            self.oc_routeCompletion = newValue
        }
    }
    
    public var prepareDestination: ((Any) -> Void)? {
        get {
            return self.oc_prepareDestination
        }
        set {
            self.oc_prepareDestination = newValue
        }
    }
}

extension ZIKRemoveRouteConfiguration: RemoveRouteConfig {
    public var prepareDestination: ((Any) -> Void)? {
        get {
            return self.oc_prepareDestination
        }
        set {
            self.oc_prepareDestination = newValue
        }
    }
}

//extension ZIKViewRemoveConfiguration: RemoveRouteConfig {
//
//}

//open class RouteConfiguration: RouteConfig {
//    public var errorHandler: ((ZIKRouteAction, Error) -> Void)?
//    public var successHandler: (() -> Void)?
//}
//
//open class PerformRouteConfiguration:RouteConfiguration, PerformRouteConfig {
//    public var prepareDestination: ((Any) -> Void)?
//    public var routeCompletion: ((Any) -> Void)?
//}
//
//open class RemoveRouteConfiguration:RouteConfiguration, RemoveRouteConfig {
//    public var prepareDestination: ((Any) -> Void)?
//}

public protocol RouterAware: class {
    static func registerRoutableDestination()
    
    init?(_config: Any, _removeConfig: Any?)
    init?(_configuring configure: @escaping (PerformRouteConfig, (@escaping (Any) -> Void) -> Void, ((Any) -> Void) -> Void) -> Void,
         _removing removeConfigure: ((RemoveRouteConfig, ((Any) -> Void) -> Void) -> Void)?)
    static func perform(
        _configuring configure: @escaping (PerformRouteConfig, (@escaping (Any) -> Void) -> Void, ((Any) -> Void) -> Void) -> Void,
        _removing removeConfigure: ((RemoveRouteConfig, ((Any) -> Void) -> Void) -> Void)?
    )
    
    var state: RouterState { get set }
    
    var canPerform: Bool { get }
    
    var canRemove: Bool { get }
    
    func removeRoute()
    
    static var canMakeDestination: Bool { get }
}

public protocol SwiftServiceRouter: RouterAware {
    associatedtype Destination
    associatedtype ModuleConfig: PerformRouteConfig
    associatedtype RemoveModuleConfig: RemoveRouteConfig
    
    static var defaultConfig: ModuleConfig { get }
    static var defaultRemoveConfig: RemoveModuleConfig { get }
    ///Store destination
    var destination: Destination? { get set }
    var config: ModuleConfig { get set }
    var removeConfig: RemoveModuleConfig { get set }
    
    init?(config: ModuleConfig, removeConfig: RemoveModuleConfig?)
    init?(configuring configure: @escaping (PerformRouteConfig, (@escaping (Destination) -> Void) -> Void, ((ModuleConfig) -> Void) -> Void) -> Void,
          removing removeConfigure: ((RemoveRouteConfig, ((RemoveModuleConfig) -> Void) -> Void) -> Void)?)
    
    func destination(with config: ModuleConfig) -> Destination?
}
public extension SwiftServiceRouter {
    public init?(_config: Any, _removeConfig: Any?) {
        assert(_config is ModuleConfig)
        assert(_removeConfig == nil || _removeConfig is RemoveModuleConfig)
        var removeConfig: RemoveModuleConfig?
        if _removeConfig != nil {
            if let r = _removeConfig as? RemoveModuleConfig {
                removeConfig = r
            } else {
                assertionFailure("Invalid remove config \(_removeConfig!), should be a \(RemoveModuleConfig.self) type.")
            }
        }
        self.init(config: _config as! ModuleConfig, removeConfig: removeConfig)
    }
    
    public init?(_configuring configure: @escaping (PerformRouteConfig, (@escaping (Any) -> Void) -> Void, ((Any) -> Void) -> Void) -> Void, _removing removeConfigure: ((RemoveRouteConfig, ((Any) -> Void) -> Void) -> Void)?) {
        let routerType = Swift.type(of: self)
        let config = routerType.preparedPerformConfig(withConfiguring: configure)
        let removeConfig = routerType.preparedRemoveConfig(withConfiguring: removeConfigure)
        self.init(config: config, removeConfig: removeConfig)
    }
    
    public static func perform(_configuring configure: @escaping (PerformRouteConfig, (@escaping (Any) -> Void) -> Void, ((Any) -> Void) -> Void) -> Void, _removing removeConfigure: ((RemoveRouteConfig, ((Any) -> Void) -> Void) -> Void)?) {
        if let router = self.init(configuring: configure, removing: removeConfigure) {
            router.perform(with: router.config)
        }
    }
    
    public static var defaultConfig: ZIKPerformRouteConfiguration {
        return ZIKPerformRouteConfiguration()
    }
    public static var defaultRemoveConfig: ZIKRemoveRouteConfiguration {
        return ZIKRemoveRouteConfiguration()
    }
    
//    public init?(config: PerformRouteConfig, removeConfig: RemoveRouteConfig?) {
//        self.config = config
//        let routerType = Swift.type(of: self)
//        self.removeConfig = removeConfig ?? routerType.defaultRemoveConfig
//    }
    
    public init?(configuring configure: @escaping (PerformRouteConfig, (@escaping (Destination) -> Void) -> Void, ((ModuleConfig) -> Void) -> Void) -> Void,
         removing removeConfigure: ((RemoveRouteConfig, ((RemoveModuleConfig) -> Void) -> Void) -> Void)?) {
        let routerType = Swift.type(of: self)
        let config = routerType.preparedPerformConfig(withConfiguring: configure)
        let removeConfig = routerType.preparedRemoveConfig(withConfiguring: removeConfigure)
        self.init(config: config, removeConfig: removeConfig)
    }
    
    public var canPerform: Bool {
        return state == .notRoute
            || state == .routeFailed
            || state == .removed
    }
    
    public func perform(with config: ModuleConfig) -> Void {
        guard canPerform else {
            assertionFailure("Can't perform route now for router: \(self)")
            return
        }
        state = .routing
        if let destination = self.destination(with: config) {
            self.config.prepareDestination?(destination)
            self.config.routeCompletion?(destination)
            self.destination = destination
            state = .routed
        } else {
            self.destination = nil
            state = .routeFailed
        }
    }
    
    public static func perform(
        configuring configure: @escaping (PerformRouteConfig, (@escaping (Destination) -> Void) -> Void, ((ModuleConfig) -> Void) -> Void) -> Void,
        removing removeConfigure: ((RemoveRouteConfig, ((RemoveModuleConfig) -> Void) -> Void) -> Void)?
        ) {
        if let router = self.init(configuring: configure, removing: removeConfigure) {
            router.perform(with: router.config)
        }
    }
    
    public var canRemove: Bool {
        return false
    }
    
    public func removeRoute() {
        guard destination != nil else {
            return
        }
        removeRouteOnDestination(destination!, removeConfig: removeConfig, routeConfig: config)
    }
    
    public func removeRouteOnDestination(_ destination: Destination, removeConfig: RemoveModuleConfig, routeConfig: ModuleConfig) {
        //Default do nothing
    }
    
    public static var canMakeDestination: Bool {
        return true
    }
    
    public static func makeDestination() {
        
    }
    
    public static func makeDestination(configuring configure: @escaping (PerformRouteConfig, (@escaping (Destination) -> Void) -> Void, ((ModuleConfig) -> Void) -> Void) -> Void) -> Destination? {
        if let router = self.init(configuring: configure, removing: nil) {
            if let destination = router.destination(with: router.config) {
                router.config.prepareDestination?(destination)
                router.config.routeCompletion?(destination)
                router.destination = destination
            }
        }
        return nil
    }
    
    static func preparedPerformConfig(withConfiguring configure: @escaping (PerformRouteConfig, (@escaping (Destination) -> Void) -> Void, ((ModuleConfig) -> Void) -> Void) -> Void) -> ModuleConfig {
        let routeConfig = self.defaultConfig
        let prepareDestination = { (prepare: @escaping (Destination) ->Void) in
            routeConfig.prepareDestination = { d in
                if d is Destination {
                    prepare(d as! Destination)
                }
            }
        }
        let prepareModule = { (prepare: (ModuleConfig) ->Void) in
            prepare(routeConfig)
        }
        configure(routeConfig, prepareDestination, prepareModule)
        return routeConfig
    }
    
    static func preparedRemoveConfig(withConfiguring configure: ((RemoveRouteConfig, ((RemoveModuleConfig) -> Void) -> Void) -> Void)?) -> RemoveModuleConfig {
        let removeConfig = self.defaultRemoveConfig
        let prepareRemoveDestination = { (prepare: @escaping (Destination) ->Void) in
            removeConfig.prepareDestination = { d in
                if d is Destination {
                    prepare(d as! Destination)
                }
            }
        }
        let prepareRemoveModule = { (prepare: (RemoveModuleConfig) ->Void) in
            prepare(removeConfig)
        }
        configure?(removeConfig, prepareRemoveModule)
        return removeConfig
    }
    
    static func preparedPerformConfig(withConfiguring configure: @escaping (PerformRouteConfig, (@escaping (Any) -> Void) -> Void, ((ModuleConfig) -> Void) -> Void) -> Void) -> ModuleConfig {
        let routeConfig = self.defaultConfig
        let prepareDestination = { (prepare: @escaping (Destination) ->Void) in
            routeConfig.prepareDestination = { d in
                if d is Destination {
                    prepare(d as! Destination)
                }
            }
        }
        let prepareModule = { (prepare: (ModuleConfig) ->Void) in
            prepare(routeConfig)
        }
        configure(routeConfig, prepareDestination, prepareModule)
        return routeConfig
    }
    
    static func preparedRemoveConfig(withConfiguring configure: ((RemoveRouteConfig, ((Any) -> Void) -> Void) -> Void)?) -> RemoveModuleConfig {
        let removeConfig = self.defaultRemoveConfig
        let prepareRemoveDestination = { (prepare: @escaping (Destination) ->Void) in
            removeConfig.prepareDestination = { d in
                if d is Destination {
                    prepare(d as! Destination)
                }
            }
        }
        let prepareRemoveModule = { (prepare: (RemoveModuleConfig) ->Void) in
            prepare(removeConfig)
        }
        configure?(removeConfig, prepareRemoveModule)
        return removeConfig
    }
}
