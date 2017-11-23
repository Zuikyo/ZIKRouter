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

public typealias ViewRouteType = ZIKViewRouteType
public typealias ViewRouteError = ZIKViewRouteError
public typealias ViewRouteConfig = ZIKViewRouteConfiguration
public typealias ViewRemoveConfig = ZIKViewRemoveConfiguration
public typealias ViewRouteSegueConfig = ZIKViewRouteSegueConfiguration
public typealias ViewRoutePopoverConfig = ZIKViewRoutePopoverConfiguration

public typealias AnyViewRouter = ViewRouter<ZIKRoutableView, ViewRouteConfig, ViewRemoveConfig>
public typealias ZIKAnyViewRouter = ZIKViewRouter<ZIKRoutableView, ViewRouteConfig, ViewRemoveConfig>
public typealias DestinationViewRouter<Destination> = ViewRouter<Destination, ViewRouteConfig, ViewRemoveConfig>
public typealias ModuleViewRouter<ModuleConfig: ViewRouteConfig> = ViewRouter<ZIKRoutableView, ModuleConfig, ViewRemoveConfig>
public typealias RemovableViewRouter<RemoveConfig: ViewRemoveConfig> = ViewRouter<ZIKRoutableView, ViewRouteConfig, RemoveConfig>

public typealias AnyServiceRouter = ServiceRouter<Any, PerformRouteConfig, RouteConfig>
public typealias ZIKAnyServiceRouter = ZIKServiceRouter<AnyObject, PerformRouteConfig, RouteConfig>
public typealias DestinationServiceRouter<Destination> = ServiceRouter<Destination, PerformRouteConfig, RouteConfig>
public typealias ModuleServiceRouter<ModuleConfig: PerformRouteConfig> = ServiceRouter<Any, ModuleConfig, RouteConfig>
public typealias RemovableServiceRouter<RemoveConfig: RouteConfig> = ServiceRouter<Any, PerformRouteConfig, RemoveConfig>
