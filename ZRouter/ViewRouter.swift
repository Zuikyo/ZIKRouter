//
//  ViewRouter.swift
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

///Type safe view router for declared view protocol. Generic parameter `Destination` is the protocol conformed by the destination. See `ViewRoute` to learn how to declare a routable protocol.
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

/** Wrapper router for routable protocol. Only declared protocol can be used with ViewRouter:
```
protocol AlertViewInput {
    var alertTitle: String {get set}
}
class AlertViewController: UIViewController, AlertViewInput {
}

//Declare `AlertViewInput` is routable in AlertViewController's view router
extension ViewRouter where Destination == AlertViewInput {
    //Be careful, don't declare a wrong type
    static var route: ViewRoute<AlertViewInput>.Type {
    return ViewRoute<AlertViewInput>.self
    }
}

//Use `AlertViewInput` to perform route to AlertViewController
class TestViewController: UIViewController {
    func presentAlertView() {
        ViewRouter<AlertViewInput>.route
            .perform(routeConfig: { config in
                config.source = self
                config.routeType = ViewRouteType.presentModally
            }, preparation: { (destination) in
                //destination is inferred as AlertViewInput
                destination.alertTitle = "test alert"
            })
    }
}
```
Then if you pass an undeclared protocol to ViewRouter, there will be compiler error.

We have to use a wrapper just because Swift extension doesn't support inheritance clause with constraints:
```
When someday Swift support this, we can declare in a simpler and safer way.
extension ViewRouter: ViewRoutable where Destination == AlertViewInput {
}
```
 */
public struct ViewRoute<View>: ViewRoutable {
    public typealias Destination = View
}
