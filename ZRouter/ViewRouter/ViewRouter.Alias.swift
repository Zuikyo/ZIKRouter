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

public typealias ViewRouteType = ZIKViewRouteType
public typealias ViewRouteError = ZIKViewRouteError
public typealias ViewRouteConfig = ZIKViewRouteConfiguration
public typealias ViewRemoveConfig = ZIKViewRemoveConfiguration
public typealias ViewRouteSegueConfig = ZIKViewRouteSegueConfiguration
public typealias ViewRoutePopoverConfig = ZIKViewRoutePopoverConfiguration

public typealias AnyViewRouter = ViewRouter<Any, ViewRouteConfig>
public typealias ZIKAnyViewRoute = ZIKViewRoute<AnyObject, ViewRouteConfig>
public typealias ZIKAnyViewRouter = ZIKViewRouter<AnyObject, ViewRouteConfig>
public typealias ZIKAnyViewRouterType = ZIKViewRouterType<AnyObject, ViewRouteConfig>
public typealias ModuleViewRouter<ModuleConfig> = ViewRouter<Any, ModuleConfig>
public typealias ZIKModuleViewRouter<ModuleConfig: ViewRouteConfig> = ZIKViewRouter<AnyObject, ModuleConfig>
public typealias DestinationViewRouter<Destination> = ViewRouter<Destination, ViewRouteConfig>
public typealias ZIKDestinationViewRouter<Destination: AnyObject> = ZIKViewRouter<Destination, ViewRouteConfig>
