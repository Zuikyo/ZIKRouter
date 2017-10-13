//
//  ZIKServiceRouteConfiguration.h
//  ZIKRouter
//
//  Created by zuik on 2017/10/13.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKRouteConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

///Configuration for service. You can use a subclass to add complex dependencies for destination. The subclass must conforms to NSCopying, because the configuration need to be copied when routing.
@interface ZIKServiceRouteConfiguration : ZIKRouteConfiguration <NSCopying>

/**
 Prepare for performRoute, and config other dependency for destination here. Subclass can offer more specific info.
 
 @note
 Use weakSelf in prepareForRoute to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^prepareForRoute)(id destination);

/**
 Completion for performRoute. Default implemenation will call routeCompletion synchronously.
 
 @note
 Use weakSelf in routeCompletion to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^routeCompletion)(id destination);
@end

NS_ASSUME_NONNULL_END
