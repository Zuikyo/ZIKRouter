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

/// Proxy and wrapper to use ZIKServiceRouter class type or ZIKServiceRoute with compile time checking. These instance methods are actually class methods in ZIKServiceRouter class.
@interface ZIKServiceRouterType<__covariant Destination, __covariant RouteConfig: ZIKPerformRouteConfiguration *> : ZIKRouterType<Destination, RouteConfig, ZIKRemoveRouteConfiguration *>
@end
@interface ZIKServiceRouterType<__covariant Destination, __covariant RouteConfig: ZIKPerformRouteConfiguration *>(Proxy)

/// If this route action doesn't need any arguments, just perform directly.
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performRoute;
/// If this route action doesn't need any arguments, perform directly with successHandler and errorHandler for current performing.
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performWithSuccessHandler:(void(^ _Nullable)(Destination destination))performerSuccessHandler
                                                                      errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler;
/// If this route action doesn't need any arguments, perform directly with completion for current performing.
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performWithCompletion:(void(^)(BOOL success, Destination _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion;

/// If this route action doesn't need any arguments, perform directly with preparation. The block is an escaping block, use weak self in it.
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performWithPreparation:(void(^)(Destination destination))prepare;

/// Set dependencies required by destination and perform route.
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;
/// Set dependencies required by destination and perform route, and you can remove the route with remove configuration later.
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKRemoveRouteConfiguration *config))removeConfigBuilder;

/**
 Perform and prepare destination in a type safe way inferred by generic parameters.
 
 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @return The router.
 */
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performWithStrictConfiguring:(void (NS_NOESCAPE ^)(ZIKPerformRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder;

/**
 Perform and prepare destination in a type safe way inferred by generic parameters, and you can remove the route with remove configuration later.
 
 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @param removeConfigBuilder Type safe builder to build remove configuration, type of `config`'s properties are inferred by generic parameters.
 @return The router.
 */
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performWithStrictConfiguring:(void (NS_NOESCAPE ^)(ZIKPerformRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder
                                                                       strictRemoving:(void (NS_NOESCAPE ^ _Nullable)(ZIKRemoveRouteStrictConfiguration<Destination> *strictConfig))removeConfigBuilder;

@end

typedef ZIKServiceRouterType<id, ZIKPerformRouteConfiguration *> ZIKAnyServiceRouterType;

NS_ASSUME_NONNULL_END
