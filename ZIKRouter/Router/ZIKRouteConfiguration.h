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
    ZIKRouterStateNotRoute  NS_ENUM_DEPRECATED_IOS(7.0, 7.0, "Use ZIKRouterStateUnrouted instead") = 0,
    ///Didn't perform any route yet.
    ZIKRouterStateUnrouted = 0,
    ///Performing a route.
    ZIKRouterStateRouting,
    ///Successfully performing a route.
    ZIKRouterStateRouted,
    ///Removing a performed route.
    ZIKRouterStateRemoving,
    ///The router was performed and removed, now it can perform again.
    ZIKRouterStateRemoved
};

///Route action.
typedef NSString *ZIKRouteAction NS_EXTENSIBLE_STRING_ENUM;

///Initialize router with configuration. See ZIKRouteErrorInvalidConfiguration, ZIKViewRouteErrorUnsupportType, ZIKViewRouteErrorInvalidSource, ZIKViewRouteErrorInvalidContainer.
extern ZIKRouteAction const ZIKRouteActionInit;

///Perform route. See ZIKRouteErrorActionFailed, ZIKRouteErrorOverRoute, ZIKViewRouteErrorUnbalancedTransition, ZIKViewRouteErrorSegueNotPerformed, ZIKRouteErrorInfiniteRecursion, ZIKRouteErrorInfiniteRecursion, ZIKRouteErrorDestinationUnavailable.
extern ZIKRouteAction const ZIKRouteActionPerformRoute;

///Remove route. See ZIKRouteErrorActionFailed.
extern ZIKRouteAction const ZIKRouteActionRemoveRoute;

typedef void(^ZIKRouteErrorHandler)(ZIKRouteAction routeAction, NSError *error);
typedef void(^ZIKRouteStateNotifier)(ZIKRouterState oldState, ZIKRouterState newState);

///Configuration for destination module. You can use a subclass to add complex dependencies for destination. The subclass must conform to NSCopying, because the configuration will be copied.
@interface ZIKRouteConfiguration : NSObject <NSCopying>

/**
 Error handler for router's provider. Each time the router was performed or removed, error handler will be called when the operation fails.
 @note
 Use weakSelf in errorHandler to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKRouteErrorHandler errorHandler;

///Error handler for current performing, will reset to nil after performed.
@property (nonatomic, copy, nullable) ZIKRouteErrorHandler performerErrorHandler;

/**
 Monitor state.
 @note
 Use weakSelf in stateNotifier to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKRouteStateNotifier stateNotifier;

///Initialize properties in current configuration class from another configuration, the other configuration must be same class or subclass of self. This is a convenient method to initialize a copy from an existing configuration in -copyWithZone:.
- (BOOL)setPropertiesFromConfiguration:(ZIKRouteConfiguration *)configuration NS_SWIFT_UNAVAILABLE("Can't get properties for Swift");

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

///Success handler for current performing, will reset to nil after performed.
@property (nonatomic, copy, nullable) void(^performerSuccessHandler)(id destination);

@property (nonatomic, copy, nullable) void(^routeCompletion)(id destination) API_DEPRECATED_WITH_REPLACEMENT("successHandler", ios(7.0, 7.0));

/**
 Completion handler for performRoute.
 
 @note
 Use weakSelf in completion to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKPerformRouteCompletion completionHandler;

///User info when handle route action from URL Scheme.
@property (nonatomic, strong, readonly) NSDictionary<NSString *, id> *userInfo;

/**
 Add user info.
 @note
 You should only use user info when handle route action from URL Scheme, because it's not recommanded to passing parameters in dictionary. The compiler can't check parameters' type.
 */
- (void)addUserInfoForKey:(NSString *)key object:(id)object;
/**
 Add user info.
 @note
 You should only use user info when handle route action from URL Scheme, because it's not recommanded to passing parameters in dictionary. The compiler can't check parameters' type.
 */
- (void)addUserInfo:(NSDictionary<NSString *, id> *)userInfo;

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

///Success handler for current removing, will reset to nil after removed.
@property (nonatomic, copy, nullable) void(^performerSuccessHandler)(void);

@end

#pragma mark Strict Configuration

///Proxy of ZIKRouteConfiguration to handle configuration in a type safe way.
@interface ZIKRouteStrictConfiguration<__covariant Destination> : NSObject
@property (nonatomic, strong, readonly) ZIKRouteConfiguration *configuration;

- (instancetype)initWithConfiguration:(ZIKRouteConfiguration *)configuration NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
/**
 Error handler for router's provider. Each time the router was performed or removed, error handler will be called when the operation fails.
 @note
 Use weakSelf in errorHandler to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKRouteErrorHandler errorHandler;

///Error handler for current performing, will reset to nil after performed.
@property (nonatomic, copy, nullable) ZIKRouteErrorHandler performerErrorHandler;

/**
 Monitor state.
 @note
 Use weakSelf in stateNotifier to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKRouteStateNotifier stateNotifier;

@end

///Proxy of ZIKPerformRouteConfiguration to handle configuration in a type safe way.
@interface ZIKPerformRouteStrictConfiguration<__covariant Destination> : ZIKRouteStrictConfiguration<Destination>
@property (nonatomic, strong, readonly) ZIKPerformRouteConfiguration *configuration;
- (instancetype)initWithConfiguration:(ZIKPerformRouteConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

/**
 Prepare for performRoute, and config other dependency for destination here. Subclass can offer more specific info.
 
 @note
 Use weakSelf in prepareDestination to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^prepareDestination)(Destination destination);

/**
 Success handler for router's provider. Each time the router was performed, success handler will be called when the operation succeed.
 @note
 Use weakSelf in successHandler to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^successHandler)(Destination destination);

///Success handler for current performing, will reset to nil after performed.
@property (nonatomic, copy, nullable) void(^performerSuccessHandler)(Destination destination);

/**
 Completion handler for performRoute.
 
 @note
 Use weakSelf in completion to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^completionHandler)(BOOL success, Destination _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error);

///User info when handle route action from URL Scheme.
@property (nonatomic, strong, readonly) NSDictionary<NSString *, id> *userInfo;

/**
 Add user info.
 @note
 You should only use user info when handle route action from URL Scheme, because it's not recommanded to passing parameters in dictionary. The compiler can't check parameters' type.
 */
- (void)addUserInfoForKey:(NSString *)key object:(id)object;
/**
 Add user info.
 @note
 You should only use user info when handle route action from URL Scheme, because it's not recommanded to passing parameters in dictionary. The compiler can't check parameters' type.
 */
- (void)addUserInfo:(NSDictionary<NSString *, id> *)userInfo;

@end

///Proxy of ZIKRemoveRouteConfiguration to handle configuration in a type safe way.
@interface ZIKRemoveRouteStrictConfiguration<__covariant Destination> : ZIKRouteStrictConfiguration<Destination>
@property (nonatomic, strong, readonly) ZIKRemoveRouteConfiguration *configuration;
- (instancetype)initWithConfiguration:(ZIKRemoveRouteConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

/**
 Prepare for removeRoute. Subclass can offer more specific info.
 
 @note
 Use weakSelf in prepareDestination to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^prepareDestination)(Destination destination);

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

///Success handler for current removing, will reset to nil after removed.
@property (nonatomic, copy, nullable) void(^performerSuccessHandler)(void);

@end

NS_ASSUME_NONNULL_END
