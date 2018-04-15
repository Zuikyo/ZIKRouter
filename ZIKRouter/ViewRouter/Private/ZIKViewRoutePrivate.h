//
//  ZIKViewRoutePrivate.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "ZIKViewRoute.h"

@interface ZIKViewRoute<__covariant Destination, __covariant RouteConfig: ZIKViewRouteConfiguration *> ()
@property (nonatomic, copy, nullable) BOOL(^destinationFromExternalPreparedBlock)(Destination destination, ZIKViewRouter *router);
@property (nonatomic, copy, readonly, nullable) BOOL(^canPerformCustomRouteBlock)(ZIKViewRouter *router);
@property (nonatomic, copy, readonly, nullable) BOOL(^canRemoveCustomRouteBlock)(ZIKViewRouter *router);
@property (nonatomic, copy, readonly, nullable) void(^performCustomRouteBlock)(Destination destination, _Nullable id source, RouteConfig config, ZIKViewRouter *router);
@property (nonatomic, copy, readonly, nullable) void(^removeCustomRouteBlock)(Destination destination, _Nullable id source, ZIKViewRemoveConfiguration *removeConfig, RouteConfig config, ZIKViewRouter *router);
@end
