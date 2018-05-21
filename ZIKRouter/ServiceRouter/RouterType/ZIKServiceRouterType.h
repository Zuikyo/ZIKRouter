//
//  ZIKServiceRouterType.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/8.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouterType.h"
#import "ZIKServiceRouter.h"

NS_ASSUME_NONNULL_BEGIN

///Proxy and wrapper to use ZIKServiceRouter class type or ZIKServiceRoute with compile time checking. These instance methods are actually class methods in ZIKServiceRouter class.
@interface ZIKServiceRouterType<__covariant Destination, __covariant RouteConfig: ZIKPerformRouteConfiguration *> : ZIKRouterType<Destination, RouteConfig, ZIKRemoveRouteConfiguration *>

///If this route action doesn't need any arguments, just perform directly.
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performRoute;
///If this route action doesn't need any arguments, perform directly with successHandler and errorHandler for current performing.
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performWithSuccessHandler:(void(^ _Nullable)(Destination destination))performerSuccessHandler
                                                                      errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler;
///If this route action doesn't need any arguments, perform directly with completion for current performing.
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performWithCompletion:(void(^)(BOOL success, Destination _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion;

///Set dependencies required by destination and perform route.
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;
///Set dependencies required by destination and perform route, and you can remove the route with remove configuration later.
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKRemoveRouteConfiguration *config))removeConfigBuilder;

@end

typedef ZIKServiceRouterType<id, ZIKPerformRouteConfiguration *> ZIKAnyServiceRouterType;

NS_ASSUME_NONNULL_END
