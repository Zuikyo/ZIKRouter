//
//  ZIKRouteConfiguration.h
//  ZIKRouter
//
//  Created by zuik on 2017/10/13.
//  Copyright © 2017 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZIKRouterState) {
    ZIKRouterStateNotRoute,
    ZIKRouterStateRouting,
    ZIKRouterStateRouted,
    ZIKRouterStateRouteFailed,
    ZIKRouterStateRemoving,
    ZIKRouterStateRemoved,
    ZIKRouterStateRemoveFailed
};

typedef void(^ZIKRouteErrorHandler)(SEL routeAction, NSError *error);
typedef void(^ZIKRouteStateNotifier)(ZIKRouterState oldState, ZIKRouterState newState);

///Configuration for destination module. You can use a subclass to add complex dependencies for destination. The subclass must conforms to NSCopying, because the configuration need to be copied when routing.
@interface ZIKRouteConfiguration : NSObject <NSCopying>

/**
 Error handler for router's creater.
 @note
 Use weakSelf in providerErrorHandler to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKRouteErrorHandler providerErrorHandler;

/**
 Success handler for router's creater.
 @note
 Use weakSelf in providerSuccessHandler to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^providerSuccessHandler)(void);

///Error handler for router's performer, will reset to nil after perform.
@property (nonatomic, copy, nullable) ZIKRouteErrorHandler performerErrorHandler;
///Success handler for router's performer, will reset to nil after perform.
@property (nonatomic, copy, nullable) void(^performerSuccessHandler)(void);

/**
 Monitor state
 @note
 Use weakSelf in stateNotifier to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKRouteStateNotifier stateNotifier;
@end

NS_ASSUME_NONNULL_END
