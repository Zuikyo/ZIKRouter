//
//  ZIKRouterAlias.h
//  ZIKRouter
//
//  Created by zuik on 2017/11/6.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRouter.h"
#import "ZIKServiceRouter.h"

typedef ZIKRouteConfiguration ZIKRouteConfig;
typedef ZIKPerformRouteConfiguration ZIKPerformRouteConfig;
typedef ZIKRemoveRouteConfiguration ZIKRemoveRouteConfig;

typedef ZIKViewRouteConfiguration ZIKViewRouteConfig;
typedef ZIKViewRemoveConfiguration ZIKViewRemoveConfig;
typedef ZIKViewRouteSegueConfiguration ZIKViewRouteSegueConfig;
typedef ZIKViewRoutePopoverConfiguration ZIKViewRoutePopoverConfig;

typedef ZIKViewRouter<id<ZIKRoutableView>, ZIKViewRouteConfig *> ZIKAnyViewRouter;
#define ZIKDestinationViewRouter(Destination) ZIKViewRouter<Destination, ZIKViewRouteConfig *>
#define ZIKModuleViewRouter(ModuleConfigProtocol) ZIKViewRouter<id<ZIKRoutableView>, ZIKViewRouteConfig<ModuleConfigProtocol> *>

typedef ZIKServiceRouter<id, ZIKPerformRouteConfig *> ZIKAnyServiceRouter;
#define ZIKDestinationServiceRouter(Destination) ZIKServiceRouter<Destination, ZIKPerformRouteConfig *>
#define ZIKModuleServiceRouter(ModuleConfigProtocol) ZIKServiceRouter<id, ZIKPerformRouteConfig<ModuleConfigProtocol> *>
