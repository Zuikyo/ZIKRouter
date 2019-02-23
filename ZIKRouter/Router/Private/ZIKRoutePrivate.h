//
//  ZIKRoutePrivate.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRoute.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZIKRoute<__covariant Destination, __covariant RouteConfig: ZIKPerformRouteConfiguration *, __covariant RemoveConfig: ZIKRemoveRouteConfiguration *> ()
@property (nonatomic, copy, readonly) _Nullable Destination(^makeDestinationBlock)(RouteConfig config, ZIKRouter *router);
@property (nonatomic, copy, readonly, nullable) RouteConfig(^makeDefaultConfigurationBlock)(void);
@property (nonatomic, copy, readonly, nullable) RemoveConfig(^makeDefaultRemoveConfigurationBlock)(void);
@property (nonatomic, copy, readonly, nullable) void(^prepareDestinationBlock)(Destination destination, RouteConfig config, ZIKRouter *router);
@property (nonatomic, copy, readonly, nullable) void(^didFinishPrepareDestinationBlock)(Destination destination, RouteConfig config, ZIKRouter *router);

+ (Class)registryClass;

@end

NS_ASSUME_NONNULL_END
