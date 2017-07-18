//
//  ZIKViewRouter_Private.h
//  ZIKViperDemo
//
//  Created by zuik on 2017/5/25.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKViewRouter.h"

///Use these methods when implementing your custom route
@interface ZIKViewRouter ()
@property (nonatomic, readonly, copy) __kindof ZIKViewRouteConfiguration *_nocopy_configuration;
@property (nonatomic, readonly, copy) __kindof ZIKViewRemoveConfiguration *_nocopy_removeConfiguration;

///Maintain the route state for custom route
///Call it when route will perform.
- (void)beginPerformRoute;
///Call it when route is successfully performed.
- (void)endPerformRouteWithSuccess;
///Call it when route performancer failed.
- (void)endPerformRouteWithError:(NSError *)error;

///Call it when route will remove.
- (void)beginRemoveRouteFromSource:(id)source;
///Call it when route is successfully removed.
- (void)endRemoveRouteWithSuccessOnDestination:(id)destination fromSource:(id)source;
///Call it when route remove failed.
- (void)endRemoveRouteWithError:(NSError *)error;

@end
