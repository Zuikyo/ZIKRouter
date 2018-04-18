//
//  ZIKViewRoute.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKRoute.h"
#import "ZIKViewRouter.h"

NS_ASSUME_NONNULL_BEGIN

///Use ZIKViewRoute to add view route with blocks, rather than creating subclass of ZIKViewRouter.
@interface ZIKViewRoute<__covariant Destination, __covariant RouteConfig: ZIKViewRouteConfiguration *> : ZIKRoute<Destination, RouteConfig, ZIKViewRemoveConfiguration *>

///Register view class with this route. See +registerView:.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^registerDestination)(Class destinationClass);

///Register view protocol with this route. See +registerViewProtocol:.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^registerDestinationProtocol)(Protocol<ZIKViewRoutable> *destinationProtocol);
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^registerModuleProtocol)(Protocol<ZIKViewModuleRoutable> *moduleConfigProtocol);

@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^makeDefaultConfiguration)(RouteConfig(^)(void));
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^makeDefaultRemoveConfiguration)(ZIKViewRemoveConfiguration *(^)(void));

@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^prepareDestination)(void(^)(Destination destination, RouteConfig config, ZIKViewRouter *router));
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^didFinishPrepareDestination)(void(^)(Destination destination, RouteConfig config, ZIKViewRouter *router));

@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^destinationFromExternalPrepared)(BOOL(^)(Destination destination, ZIKViewRouter *router));

@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^canPerformCustomRoute)(BOOL(^)(ZIKViewRouter *router));

///Whether the router can remove custom route now. Default is NO.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^canRemoveCustomRoute)(BOOL(^)(ZIKViewRouter *router));

///Perform your custom route. You must maintain the router's state with methods in ZIKViewRouterInternal.h.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^performCustomRoute)(void(^)(Destination destination, _Nullable id source, RouteConfig config, ZIKViewRouter *router));

///Remove your custom route. You must maintain the router's state with methods in ZIKViewRouterInternal.h.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^removeCustomRoute)(void(^)(Destination destination, _Nullable id source, ZIKViewRemoveConfiguration *removeConfig, RouteConfig config, ZIKViewRouter *router));

@end

typedef ZIKViewRoute<id, ZIKViewRouteConfiguration *> ZIKAnyViewRoute;
#define ZIKDestinationViewRoute(Destination) ZIKViewRoute<Destination, ZIKViewRouteConfig *>
#define ZIKModuleViewRoute(ModuleConfigProtocol) ZIKViewRoute<id, ZIKViewRouteConfig<ModuleConfigProtocol> *>

NS_ASSUME_NONNULL_END
