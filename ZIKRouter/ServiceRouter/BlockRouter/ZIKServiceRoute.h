//
//  ZIKServiceRoute.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/8.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKRoute.h"
#import "ZIKServiceRouter.h"

NS_ASSUME_NONNULL_BEGIN

///Use ZIKServiceRoute to add service route with blocks, rather than creating subclass of ZIKServiceRouter.
@interface ZIKServiceRoute<__covariant Destination, __covariant RouteConfig: ZIKPerformRouteConfiguration *> : ZIKRoute<Destination, RouteConfig, ZIKRemoveRouteConfiguration *>

@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^registerDestination)(Class destinationClass);
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^registerDestinationProtocol)(Protocol<ZIKServiceRoutable> *destinationProtocol);
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^registerModuleProtocol)(Protocol<ZIKServiceModuleRoutable> *moduleConfigProtocol);

@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^makeDefaultConfiguration)(RouteConfig(^)(void));
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^makeDefaultRemoveConfiguration)(ZIKRemoveRouteConfiguration *(^)(void));

@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^prepareDestination)(void(^)(Destination destination, RouteConfig config, ZIKServiceRouter *router));
@property (nonatomic, readonly) ZIKServiceRoute<Destination, RouteConfig> *(^didFinishPrepareDestination)(void(^)(Destination destination, RouteConfig config, ZIKServiceRouter *router));

@end

typedef ZIKServiceRoute<id, ZIKPerformRouteConfiguration *> ZIKAnyServiceRoute;
#define ZIKDestinationServiceRoute(Destination) ZIKServiceRoute<Destination, ZIKPerformRouteConfig *>
#define ZIKModuleServiceRoute(ModuleConfigProtocol) ZIKServiceRoute<id, ZIKPerformRouteConfig<ModuleConfigProtocol> *>

NS_ASSUME_NONNULL_END
