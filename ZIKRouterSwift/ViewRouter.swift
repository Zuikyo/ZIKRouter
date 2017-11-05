//
//  ViewRouter.swift
//  ZIKRouterSwift
//
//  Created by zuik on 2017/11/5.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import ZIKRouter

///Type safety view router for declared view protocol. See `ViewRoute` to learn how to declare a routable protocol.
open class ViewRouter<Destination> {
    
}

public protocol ViewRoutable {
    associatedtype Destination
}

public extension ViewRoutable {
    
    /// Perform route with view protocol and prepare the destination with the protocol.
    ///
    /// - Parameters:
    ///   - configure: Configure the configuration for view route.
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The view router.
    public static func perform(
        routeConfig configure: (ViewRouteConfig) -> Swift.Void,
        preparation prepare: ((Destination) -> Swift.Void)? = nil
        ) -> DefaultViewRouter? {
        return Router.perform(forViewProtocol: Destination.self, routeConfig: configure, preparation: prepare)
    }
    
    /// Get view destination conforming the view protocol.
    ///
    /// - Parameters:
    ///   - prepare: Prepare the destination with the protocol.
    /// - Returns: The view destination.
    public static func makeDestination(preparation prepare: ((Destination) -> Swift.Void)? = nil) -> Destination? {
        return Router.makeDestination(forViewProtocol: Destination.self, preparation: prepare)
    }
}

///All objc protocols inherited from ZIKViewRoutable are routable.
public extension ViewRouter where Destination: ZIKViewRoutable {
    public static var route: ViewRoute<Destination>.Type {
        return ViewRoute<Destination>.self
    }
}

/// Wrapper router for routable protocol. Only declared protocol can be used with ViewRouter:
/// ```
///protocol MyViewInput {
///}
///class MyViewController: UIViewController, MyViewInput {
///}
///
/////Declare `MyViewInput` is routable in MyViewController's view router
///extension ViewRouter where Destination == MyViewInput {
///    //Be careful, don't use a wrong struct
///    static var route: ViewRoute<MyViewInput>.Type {
///        return ViewRoute<MyViewInput>.self
///    }
///}
///
/////Use `MyViewInput` to perform route to MyViewController
///class TestViewController: UIViewController {
///    func presentMyView() {
///        ViewRouter<MyViewInput>.route
///            .perform(routeConfig: { config in
///                config.source = self
///                config.routeType = ViewRouteType.presentModally
///            }, preparation: { (destination) in
///                //destination is inferred as MyViewInput
///            })
///    }
///}
///```
///Then if you pass an undeclared protocol to ViewRouter, there will be compiler error.
///
///We have to use a wrapper just because Swift extension doesn't support inheritance clause with constraints:
///```
//////When someday Swift support this, we can declare in a simpler way.
///extension ViewRouter: ViewRoutable where Destination == MyViewInput {
///}
///```
public struct ViewRoute<View>: ViewRoutable {
    public typealias Destination = View
}
