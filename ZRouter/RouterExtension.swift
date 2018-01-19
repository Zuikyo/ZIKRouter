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

///Add Swift methods for ZIKViewRouter
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

///Add Swift methods for ZIKServiceRouter
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
