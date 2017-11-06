//
//  ViewModuleRouter.swift
//  ZRouter
//
//  Created by zuik on 2017/11/5.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import ZIKRouter

///Type safe view module router for declared view module config protocol. Generic parameter `Module` is the config protocol of the module. See `ViewRoute` to learn how to declare a routable protocol.
///
///When the view module contains not only a single UIViewController, but also other internal services, and you can't prepare the module with a simple view protocol, then you need a moudle config protocol.
open class ViewModuleRouter<Module> {
    
}

public protocol ViewModuleRoutePerformer {
    associatedtype Module
}

public extension ViewModuleRoutePerformer {
    
    /// Perform route with view module config protocol and prepare the module with the protocol.
    ///
    /// - Parameters:
    ///   - configure: Configure the configuration for view route.
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The view router.
    public static func perform(
        routeConfig configure: (ViewRouteConfig) -> Swift.Void,
        preparation prepare: ((Module) -> Swift.Void)? = nil
        ) -> DefaultViewRouter? {
        return Router.perform(forViewModule: Module.self, routeConfig: configure, preparation: prepare)
    }
    
    /// Get view destination with view module config protocol.
    ///
    /// - Parameters:
    ///   - prepare: Prepare the module with the protocol.
    /// - Returns: The view destination.
    public static func makeDestination<Module>(preparation prepare: ((Module) -> Swift.Void)? = nil) -> Any? {
        return Router.makeDestination(forViewModule: Module.self, preparation: prepare)
    }
}

///All objc protocols inherited from ZIKViewModuleRoutable are routable.
public extension ViewModuleRouter where Module: ZIKViewModuleRoutable {
    public static var route: ViewModuleRoute<Module>.Type {
        return ViewModuleRoute<Module>.self
    }
}

///Wrapper router for routable view module protocol.
///SeeAlso: `ViewRoute`.
public struct ViewModuleRoute<ViewModule>: ViewModuleRoutePerformer {
    public typealias Module = ViewModule
}
