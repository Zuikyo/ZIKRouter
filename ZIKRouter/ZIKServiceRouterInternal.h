//
//  ZIKServiceRouterInternal.h
//  ZIKRouter
//
//  Created by zuik on 2017/8/9.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKServiceRouter.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZIKServiceRouter ()
@property (nonatomic, readonly, copy) __kindof ZIKServiceRouteConfiguration *_nocopy_configuration;

///Maintain the route state when you implement custom route or remove route
///Call it when route will perform.
- (void)beginPerformRoute;
///Call it when route is successfully performed.
- (void)endPerformRouteWithSuccess;
///Call it when route performancer failed.
- (void)endPerformRouteWithError:(NSError *)error;

///Call it when route will remove.
- (void)beginRemoveRoute;
///Call it when route is successfully removed.
- (void)endRemoveRouteWithSuccessOnDestination:(id)destination;
///Call it when route remove failed.
- (void)endRemoveRouteWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
