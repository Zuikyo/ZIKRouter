//
//  ZIKViewRoutePrivate.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRoute.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZIKViewRoute<__covariant Destination, __covariant RouteConfig: ZIKViewRouteConfiguration *> ()
@property (nonatomic, copy, nullable) BOOL(^shouldAutoCreateForDestinationBlock)(Destination destination, id source);
@property (nonatomic, copy, nullable) BOOL(^destinationFromExternalPreparedBlock)(Destination destination, ZIKViewRouter *router);
@property (nonatomic, copy, readonly, nullable) ZIKViewRouteTypeMask(^makeSupportedRouteTypesBlock)(void);
@property (nonatomic, copy, readonly, nullable) BOOL(^canPerformCustomRouteBlock)(ZIKViewRouter *router);
@property (nonatomic, copy, readonly, nullable) BOOL(^canRemoveCustomRouteBlock)(ZIKViewRouter *router);
@property (nonatomic, copy, readonly, nullable) void(^performCustomRouteBlock)(Destination destination, _Nullable id source, RouteConfig config, ZIKViewRouter *router);
@property (nonatomic, copy, readonly, nullable) void(^removeCustomRouteBlock)(Destination destination, _Nullable id source, ZIKViewRemoveConfiguration *removeConfig, RouteConfig config, ZIKViewRouter *router);

- (BOOL)supportRouteType:(ZIKViewRouteType)type;

@end

NS_ASSUME_NONNULL_END
