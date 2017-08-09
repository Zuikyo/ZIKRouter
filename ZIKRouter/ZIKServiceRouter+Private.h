//
//  ZIKServiceRouter_Private.h
//  ZIKRouter
//
//  Created by zuik on 2017/8/9.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKServiceRouter.h"

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
