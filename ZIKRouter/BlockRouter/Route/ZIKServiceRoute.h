//
//  ZIKServiceRoute.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/8.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKRoute.h"
#import "ZIKServiceRouter.h"

@interface ZIKServiceRoute<__covariant Destination, __covariant RouteConfig: ZIKPerformRouteConfiguration *> : ZIKRoute<Destination, RouteConfig, ZIKRemoveRouteConfiguration *>

@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^registerDestination)(Class destinationClass);
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^registerDestinationProtocol)(Protocol *destinationProtocol);
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^registerModuleProtocol)(Protocol *moduleConfigProtocol);

@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^makeDefaultConfiguration)(RouteConfig(^)(void));
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^makeDefaultRemoveConfiguration)(ZIKRemoveRouteConfiguration *(^)(void));

@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^prepareDestination)(void(^)(Destination destination, RouteConfig config, ZIKServiceRouter *router));
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^didFinishPrepareDestination)(void(^)(Destination destination, RouteConfig config, ZIKServiceRouter *router));

@end

typedef ZIKServiceRoute<id, ZIKPerformRouteConfiguration *> ZIKDefaultServiceRoute;
