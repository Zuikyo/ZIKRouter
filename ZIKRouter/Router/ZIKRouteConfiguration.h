//
//  ZIKRouteConfiguration.h
//  ZIKRouter
//
//  Created by zuik on 2017/10/13.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
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

typedef NSString *ZIKRouteAction NS_EXTENSIBLE_STRING_ENUM;

extern ZIKRouteAction const ZIKRouteActionInit;
extern ZIKRouteAction const ZIKRouteActionPerformRoute;
extern ZIKRouteAction const ZIKRouteActionRemoveRoute;

typedef void(^ZIKRouteErrorHandler)(ZIKRouteAction routeAction, NSError *error);
typedef void(^ZIKRouteStateNotifier)(ZIKRouterState oldState, ZIKRouterState newState);

///Configuration for destination module. You can use a subclass to add complex dependencies for destination. The subclass must conforms to NSCopying, because the configuration will be copied.
@interface ZIKRouteConfiguration : NSObject <NSCopying>

/**
 Error handler for router's provider.
 @note
 Use weakSelf in errorHandler to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKRouteErrorHandler errorHandler NS_SWIFT_NAME(oc_errorHandler);

/**
 Success handler for router's provider.
 @note
 Use weakSelf in successHandler to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^successHandler)(void) NS_SWIFT_NAME(oc_successHandler);

/**
 Monitor state
 @note
 Use weakSelf in stateNotifier to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKRouteStateNotifier stateNotifier;
@end

@interface ZIKPerformRouteConfiguration : ZIKRouteConfiguration <NSCopying>

/**
 Prepare for performRoute, and config other dependency for destination here. Subclass can offer more specific info.
 
 @note
 Use weakSelf in prepareDestination to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^prepareDestination)(id destination) NS_SWIFT_NAME(oc_prepareDestination);

/**
 Completion for performRoute. Default implemenation will call routeCompletion synchronously.
 
 @note
 Use weakSelf in routeCompletion to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^routeCompletion)(id destination) NS_SWIFT_NAME(oc_routeCompletion);
@end

@interface ZIKRemoveRouteConfiguration : ZIKRouteConfiguration <NSCopying>

/**
 Prepare for removeRoute. Subclass can offer more specific info.
 
 @note
 Use weakSelf in prepareDestination to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^prepareDestination)(id destination) NS_SWIFT_NAME(oc_prepareDestination);

@end

NS_ASSUME_NONNULL_END
