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
    ZIKRouterStateRemoving,
    ZIKRouterStateRemoved
};

///Route action.
typedef NSString *ZIKRouteAction NS_EXTENSIBLE_STRING_ENUM;

///Initialize router with configuration. See ZIKViewRouteErrorInvalidConfiguration, ZIKViewRouteErrorUnsupportType, ZIKViewRouteErrorInvalidSource, ZIKViewRouteErrorInvalidContainer.
extern ZIKRouteAction const ZIKRouteActionInit;

///Perform route. See ZIKViewRouteErrorActionFailed, ZIKServiceRouteErrorActionFailed, ZIKViewRouteErrorOverRoute, ZIKViewRouteErrorUnbalancedTransition, ZIKViewRouteErrorSegueNotPerformed, ZIKViewRouteErrorInfiniteRecursion, ZIKServiceRouteErrorInfiniteRecursion, ZIKServiceRouteErrorServiceUnavailable.
extern ZIKRouteAction const ZIKRouteActionPerformRoute;

///Remove route. See ZIKViewRouteErrorActionFailed, ZIKServiceRouteErrorActionFailed.
extern ZIKRouteAction const ZIKRouteActionRemoveRoute;

typedef void(^ZIKRouteErrorHandler)(ZIKRouteAction routeAction, NSError *error);
typedef void(^ZIKRouteStateNotifier)(ZIKRouterState oldState, ZIKRouterState newState);

///Configuration for destination module. You can use a subclass to add complex dependencies for destination. The subclass must conforms to NSCopying, because the configuration will be copied.
@interface ZIKRouteConfiguration : NSObject <NSCopying>

/**
 Error handler for router's provider. Each time the router was performed or removed, error handler will be called when the operation fails.
 @note
 Use weakSelf in errorHandler to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKRouteErrorHandler errorHandler;

/**
 Monitor state.
 @note
 Use weakSelf in stateNotifier to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKRouteStateNotifier stateNotifier;

///Initialize properties in currrent configuration class from another configuration, the other configuration must be same class or subclass of self. This is a convenient method to initialize a copy from an existing configuration in -copyWithZone:.
- (BOOL)setPropertiesFromConfiguration:(ZIKRouteConfiguration *)configuration;

@end

typedef void(^ZIKPerformRouteCompletion)(BOOL success, id _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error);
@interface ZIKPerformRouteConfiguration : ZIKRouteConfiguration <NSCopying>

/**
 Prepare for performRoute, and config other dependency for destination here. Subclass can offer more specific info.
 
 @note
 Use weakSelf in prepareDestination to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^prepareDestination)(id destination);

/**
 Success handler for router's provider. Each time the router was performed, success handler will be called when the operation succeed.
 @note
 Use weakSelf in successHandler to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^successHandler)(id destination);

@property (nonatomic, copy, nullable) void(^routeCompletion)(id destination) API_DEPRECATED_WITH_REPLACEMENT("successHandler", ios(7.0, 7.0));

/**
 Completion handler for performRoute.
 
 @note
 Use weakSelf in completion to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKPerformRouteCompletion completionHandler;
@end

typedef void(^ZIKRemoveRouteCompletion)(BOOL success, ZIKRouteAction routeAction, NSError *_Nullable error);
@interface ZIKRemoveRouteConfiguration : ZIKRouteConfiguration <NSCopying>

/**
 Prepare for removeRoute. Subclass can offer more specific info.
 
 @note
 Use weakSelf in prepareDestination to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^prepareDestination)(id destination);

/**
 Success handler for router's provider. Each time the router was removed, success handler will be called when the operation succeed.
 @note
 Use weakSelf in successHandler to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^successHandler)(void);

/**
 Completion handler for removeRoute.
 
 @note
 Use weakSelf in completion to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKRemoveRouteCompletion completionHandler;

@end

NS_ASSUME_NONNULL_END
