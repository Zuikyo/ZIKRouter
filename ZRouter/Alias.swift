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

public typealias RouteConfig = ZIKRouteConfiguration
public typealias PerformRouteConfig = ZIKPerformRouteConfiguration

public typealias ViewRouteType = ZIKViewRouteType
public typealias ViewRouteError = ZIKViewRouteError
public typealias ViewRouteConfig = ZIKViewRouteConfiguration
public typealias ViewRemoveConfig = ZIKViewRemoveConfiguration

public typealias DefaultViewRouter = ZIKViewRouter<ZIKRoutableView, ViewRouteConfig, ViewRemoveConfig>
public typealias DestinationViewRouter<Destination> = ZIKViewRouter<Destination, ViewRouteConfig, ViewRemoveConfig>
public typealias ModuleViewRouter<ModuleConfig: ViewRouteConfig> = ZIKViewRouter<ZIKRoutableView, ModuleConfig, ViewRemoveConfig>
public typealias RemovableViewRouter<RemoveConfig: ViewRemoveConfig> = ZIKViewRouter<ZIKRoutableView, ViewRouteConfig, RemoveConfig>

public typealias DefaultServiceRouter = ZIKServiceRouter<AnyObject, PerformRouteConfig, RouteConfig>
public typealias DestinationServiceRouter<Destination> = ZIKServiceRouter<Destination, PerformRouteConfig, RouteConfig>
public typealias ModuleServiceRouter<ModuleConfig: PerformRouteConfig> = ZIKServiceRouter<AnyObject, ModuleConfig, RouteConfig>
public typealias RemovableServiceRouter<RemoveConfig: RouteConfig> = ZIKServiceRouter<AnyObject, PerformRouteConfig, RemoveConfig>
