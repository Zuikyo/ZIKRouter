//
//  Routable.swift
//  ZRouter
//
//  Created by zuik on 2017/11/6.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import ZIKRouter

/**
 Entry for routable view protocol, only available for explicitly declared protocol.
 
 Declare that protocol `TestViewInput` is routable as a view protocol:
 ```
 extension RoutableView where Protocol == TestViewInput {
     init() { }
 }
 ```
 Now we can access to the initializer method when the generic parameter `Protocol` is `TestViewInput`, and use `TestViewInput` in router:
 ```
 Router.perform(
 for: RoutableView<TestViewInput>(),
 routeConfig: { config in
     config.source = self
     config.routeType = ViewRouteType.presentModally
 },
 preparation: { destination in
     //destination is inferred as TestViewInput
 })
 ```
 
 - Warning
 Never add extension for RoutableView without generic constraint and expose it's initializer.
 - Note
 When there is only one declared protocol, swift complier will use that protocol as default generic parameter.
 */
public struct RoutableView<Protocol> {
    internal init() { }
}

/**
 Entry for routable view module protocol, only available for explicitly declared protocol.
 
 Declare that protocol `TestViewModuleInput` is routable as a view module protocol:
 ```
 extension RoutableViewModule where Protocol == TestViewModuleInput {
     init() { }
 }
 ```
 - Warning
 Never add extension for RoutableViewModule without generic constraint and expose it's initializer.
 */
public struct RoutableViewModule<Protocol> {
    internal init() { }
}

/**
 Entry for routable service protocol, only available for explicitly declared protocol.
 
 Declare that protocol `TestServiceInput` is routable as a service protocol:
 ```
 extension RoutableServiceModule where Protocol == TestServiceInput {
     init() { }
 }
 ```
 - Warning
 Never add extension for RoutableServiceModule without generic constraint and expose it's initializer.
 */
public struct RoutableService<Protocol> {
    internal init() { }
}

/**
 Entry for routable service module protocol, only available for explicitly declared protocol.
 
 Declare that protocol `TestServiceInput` is routable as a service protocol:
 ```
 extension RoutableServiceModule where Protocol == TestServiceModuleInput {
     init() { }
 }
 ```
 - Warning
 Never add extension for RoutableServiceModule without generic constraint and expose it's initializer.
 */
public struct RoutableServiceModule<Protocol> {
    internal init() { }
}

///All protocols inherited from ZIKViewRoutable are routable as view protocol.
public extension RoutableView where Protocol: ZIKViewRoutable {
    init() { }
}

///All protocols inherited from ZIKViewModuleRoutable are routable as view module protocol.
public extension RoutableViewModule where Protocol: ZIKViewModuleRoutable {
    init() { }
}

///All protocols inherited from ZIKServiceRoutable are routable as service protocol.
public extension RoutableService where Protocol: ZIKServiceRoutable {
    init() { }
}

///All protocols inherited from ZIKViewRoutable are routable as service module protocol.
public extension RoutableServiceModule where Protocol: ZIKServiceModuleRoutable {
    init() { }
}
