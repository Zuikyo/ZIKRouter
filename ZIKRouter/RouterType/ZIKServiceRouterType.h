//
//  ZIKServiceRouterType.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/8.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKRouterType.h"
#import "ZIKServiceRouter.h"

NS_ASSUME_NONNULL_BEGIN

///Wrapper to use ZIKServiceRouter class type or ZIKServiceRoute with compile time checking. These instance methods are actually class methods in ZIKServiceRouter class.
@interface ZIKServiceRouterType<__covariant Destination: id, __covariant RouteConfig: ZIKPerformRouteConfiguration *> : ZIKRouterType<Destination, RouteConfig, ZIKRemoveRouteConfiguration *>

///If this route action doesn't need any arguments, just perform directly.
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performRoute;
///Set dependencies required by destination and perform route.
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;
///Set dependencies required by destination and perform route, and you can remove the route with remove configuration later.
- (nullable ZIKServiceRouter<Destination, RouteConfig> *)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKRemoveRouteConfiguration *config))removeConfigBuilder;

@end

typedef ZIKServiceRouterType<id, ZIKPerformRouteConfiguration *> ZIKAnyServiceRouterType;

NS_ASSUME_NONNULL_END
