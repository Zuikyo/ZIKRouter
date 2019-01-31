//
//  Alias.swift
//  ZRouter
//
//  Created by zuik on 2017/11/5.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import ZIKRouter

public typealias RouterState = ZIKRouterState
public typealias RouteConfig = ZIKRouteConfiguration
public typealias PerformRouteConfig = ZIKPerformRouteConfiguration
public typealias RemoveRouteConfig = ZIKRemoveRouteConfiguration

public typealias AnyServiceRouter = ServiceRouter<Any, PerformRouteConfig>
public typealias ZIKAnyServiceRoute = ZIKServiceRoute<AnyObject, PerformRouteConfig>
public typealias ZIKAnyServiceRouter = ZIKServiceRouter<AnyObject, PerformRouteConfig>
public typealias ZIKAnyServiceRouterType = ZIKServiceRouterType<AnyObject, PerformRouteConfig>
public typealias ModuleServiceRouter<ModuleConfig> = ServiceRouter<Any, ModuleConfig>
public typealias ZIKModuleServiceRouter<ModuleConfig: PerformRouteConfig> = ZIKServiceRouter<AnyObject, ModuleConfig>
public typealias DestinationServiceRouter<Destination> = ServiceRouter<Destination, PerformRouteConfig>
public typealias ZIKDestinationServiceRouter<Destination: AnyObject> = ZIKServiceRouter<Destination, PerformRouteConfig>
