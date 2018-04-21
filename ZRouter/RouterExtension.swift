//
//  RouterExtension.swift
//  ZRouter
//
//  Created by zuik on 2018/1/20.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import ZIKRouter

// MARK: View Router Extension

///Add Swift methods for ZIKViewRouter. Unavailable for any other classes.
public protocol ViewRouterExtension: class {
    static func register<Protocol>(_ routableView: RoutableView<Protocol>)
    static func register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>)
}

public extension ViewRouterExtension {
    static func register<Protocol>(_ routableView: RoutableView<Protocol>) {
        Registry.register(routableView, forRouter: self)
    }
    static func register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>) {
        Registry.register(routableViewModule, forRouter: self)
    }
}

extension ZIKViewRouter: ViewRouterExtension {
    
}

// MARK: Service Router Extension

///Add Swift methods for ZIKServiceRouter. Unavailable for any other classes.
public protocol ServiceRouterExtension: class {
    static func register<Protocol>(_ routableService: RoutableService<Protocol>)
    static func register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>)
}

public extension ServiceRouterExtension {
    static func register<Protocol>(_ routableService: RoutableService<Protocol>) {
        Registry.register(routableService, forRouter: self)
    }
    static func register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>) {
        Registry.register(routableServiceModule, forRouter: self)
    }
}

extension ZIKServiceRouter: ServiceRouterExtension {
    
}

// MARK: View Route Extension

///Add Swift methods for ZIKViewRoute. Unavailable for any other classes.
public protocol ViewRouteExtension: class {
    func register<Protocol>(_ routableView: RoutableView<Protocol>) -> Self
    func register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>) -> Self
}

public extension ViewRouteExtension {
    func register<Protocol>(_ routableView: RoutableView<Protocol>) -> Self {
        Registry.register(routableView, forRoute: self)
        return self
    }
    func register<Protocol>(_ routableViewModule: RoutableViewModule<Protocol>) -> Self {
        Registry.register(routableViewModule, forRoute: self)
        return self
    }
}

extension ZIKViewRoute: ViewRouteExtension {
    
}

// MARK: Service Route Extension

///Add Swift methods for ZIKServiceRoute. Unavailable for any other classes.
public protocol ServiceRouteExtension: class {
    func register<Protocol>(_ routableService: RoutableService<Protocol>) -> Self
    func register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>) -> Self
}

public extension ServiceRouteExtension {
    
    /// Register pure Swift protocol or objc protocol for your service with this ZIKServiceRoute. Router will check whether the registered service protocol is conformed by the registered service.
    ///
    /// - Parameter routableService: A routabe entry carrying a protocol conformed by the custom configuration of the router. Can be pure Swift protocol or objc protocol.
    /// - Returns: Self
    func register<Protocol>(_ routableService: RoutableService<Protocol>) -> Self {
        Registry.register(routableService, forRoute: self)
        return self
    }
    
    /// Register pure Swift protocol or objc protocol for your custom configuration with a ZIKServiceRoute. You must add `makeDefaultConfiguration` for this route before registering, because router will check whether the registered config protocol is conformed by the defaultRouteConfiguration.
    ///
    /// - Parameter routableServiceModule: A routabe entry carrying a module config protocol conformed by the custom configuration of the router. Can be pure Swift protocol or objc protocol.
    /// - Returns: Self
    func register<Protocol>(_ routableServiceModule: RoutableServiceModule<Protocol>) -> Self {
        Registry.register(routableServiceModule, forRoute: self)
        return self
    }
}

extension ZIKServiceRoute: ServiceRouteExtension {
    
}
