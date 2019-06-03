//
//  ZIKRouter.h
//  ZIKRouter
//
//  Created by zuik on 2017/3/2.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import "ZIKRouteConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

/// Enable this to check whether all routers and routable protocols are properly implemented. If you want to disable this checking, add ZIKROUTER_CHECK=0 in Build Settings -> Preprocessor Macros of ZIKRouter target.
#ifdef DEBUG
#ifndef ZIKROUTER_CHECK
#define ZIKROUTER_CHECK 1
#endif
#else
#define ZIKROUTER_CHECK 0
#endif

/**
 Abstract superclass for router that can perform route and remove route.
 @note
 The router only keeps weak reference to the destination, the performer is responsible for holding it if needed.
 */
@interface ZIKRouter<__covariant Destination, __covariant RouteConfig: ZIKPerformRouteConfiguration *, __covariant RemoveConfig: ZIKRemoveRouteConfiguration *> : NSObject
/// State of route. View router's state will be auto changed when the destination's state is changed.
@property (nonatomic, readonly, assign) ZIKRouterState state;
/// Configuration for performRoute. This should not be modified after perform.
@property (nonatomic, readonly, copy) RouteConfig configuration;
/// Configuration for removeRoute.
@property (nonatomic, readonly, copy, nullable) RemoveConfig removeConfiguration;
/// Latest error when route action failed.
@property (nonatomic, readonly, strong, nullable) NSError *error;
//Set error handler for all router instance. Use this to debug and log.
@property (class, copy, nullable) void(^globalErrorHandler)(__kindof ZIKRouter *_Nullable router, ZIKRouteAction action, NSError *error);

- (nullable instancetype)initWithConfiguration:(RouteConfig)configuration
                           removeConfiguration:(nullable RemoveConfig)removeConfiguration NS_DESIGNATED_INITIALIZER;
/// Convenient method to create configuration in a builder block.
- (nullable instancetype)initWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                    removing:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfig config))removeConfigBuilder;
/**
 Convenient method to create configuration in a type safe builder block.

 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @param removeConfigBuilder Type safe builder to build remove configuration, type of `config`'s properties are inferred by generic parameters.
 @return The router.
 */
- (nullable instancetype)initWithStrictConfiguring:(void(NS_NOESCAPE ^)(ZIKPerformRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder
                                    strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKRemoveRouteStrictConfiguration<Destination> *config))removeConfigBuilder;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

#pragma mark Perform

/// Whether the router can perform route now.
- (BOOL)canPerform;

/// Perform route directly.
- (void)performRoute;
/// Perform with success handler and error handler. Blocks are only for current performing.
- (void)performRouteWithSuccessHandler:(void(^ _Nullable)(Destination destination))performerSuccessHandler
                          errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler;
/// Perform with completion. The completion is only for current performing.
- (void)performRouteWithCompletion:(void(^)(BOOL success, Destination _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion;

/// If this route action doesn't need any arguments, just perform directly.
+ (nullable instancetype)performRoute;
/// If this route action doesn't need any arguments, perform directly with successHandler and errorHandler for current performing.
+ (nullable instancetype)performWithSuccessHandler:(void(^ _Nullable)(Destination destination))performerSuccessHandler
                                      errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler;
/// If this route action doesn't need any arguments, perform directly with completion for current performing.
+ (nullable instancetype)performWithCompletion:(void(^)(BOOL success, Destination _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion;

/// If this route action doesn't need any arguments, perform directly with preparation. The block is an escaping block, use weak self in it.
+ (nullable instancetype)performWithPreparation:(void(^)(Destination destination))prepare;

/// Convenient method to prepare destination and perform route.
+ (nullable instancetype)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;
/// Convenient method to prepare destination and perform route, and you can remove the route with remove configuration later.
+ (nullable instancetype)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                       removing:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfig config))removeConfigBuilder;

/**
 Perform and prepare destination in a type safe way inferred by generic parameters.
 
 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @return The router.
 */
+ (nullable instancetype)performWithStrictConfiguring:(void (NS_NOESCAPE ^)(ZIKPerformRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder;

/**
 Perform and prepare destination in a type safe way inferred by generic parameters, and you can remove the route with remove configuration later.
 
 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @param removeConfigBuilder Type safe builder to build remove configuration, type of `config`'s properties are inferred by generic parameters.
 @return The router.
 */
+ (nullable instancetype)performWithStrictConfiguring:(void (NS_NOESCAPE ^)(ZIKPerformRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder
                                       strictRemoving:(void (NS_NOESCAPE ^ _Nullable)(ZIKRemoveRouteStrictConfiguration<Destination> *config))removeConfigBuilder;

#pragma mark Remove

/// Whether the router should be removed before another performing, when the router is performed already and the destination still exists.
- (BOOL)shouldRemoveBeforePerform;

/// Whether the router can remove route now.
- (BOOL)canRemove;
/// Remove route directly. If -canRemove return NO, this will fail.
- (void)removeRoute;
/// Remove with success handler and error handler for current removing.
- (void)removeRouteWithSuccessHandler:(void(^ _Nullable)(void))performerSuccessHandler
                         errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler;
/// Remove route with completion for current removing.
- (void)removeRouteWithCompletion:(void(^)(BOOL success, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion;
/// Remove route and prepare before removing.
- (void)removeRouteWithConfiguring:(void(NS_NOESCAPE ^)(RemoveConfig config))removeConfigBuilder;
/// Remove route and prepare before removing.
- (void)removeRouteWithStrictConfiguring:(void(NS_NOESCAPE ^)(ZIKRemoveRouteStrictConfiguration<Destination> *config))removeConfigBuilder;

#pragma mark Factory

/// Whether the destination is instantiated synchronously.
+ (BOOL)canMakeDestinationSynchronously;

/// The router may can't make destination synchronously, or it's not for providing a destination but only for performing some actions.
+ (BOOL)canMakeDestination;

/// Synchronously get destination.
+ (nullable Destination)makeDestination;

/// Synchronously get destination, and prepare the destination with destination protocol. The block is an escaping block, use weak self in it.
+ (nullable Destination)makeDestinationWithPreparation:(void(^ _Nullable)(Destination destination))prepare;

/// Synchronously get destination, and prepare the destination.
+ (nullable Destination)makeDestinationWithConfiguring:(void(NS_NOESCAPE ^ _Nullable)(RouteConfig config))configBuilder;

/**
 Synchronously get destination, and prepare the destination in a type safe way inferred by generic parameters.

 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @return The prepared destination.
 */
+ (nullable Destination)makeDestinationWithStrictConfiguring:(void(NS_NOESCAPE ^ _Nullable)(ZIKPerformRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder;

#pragma mark Debug

+ (NSString *)descriptionOfState:(ZIKRouterState)state;

@end

#pragma mark Alias

typedef ZIKRouteConfiguration ZIKRouteConfig;
typedef ZIKPerformRouteConfiguration ZIKPerformRouteConfig;
typedef ZIKRemoveRouteConfiguration ZIKRemoveRouteConfig;

/// Check whether the protocol is routable at compile time when passing protocols to `+registerViewProtocol:`, `+registerServiceProtocol:`, `+registerModuleProtocol:`, `toView:`, `toService:`, `toModule:`.
#define ZIKRoutable(RoutableProtocol) (Protocol<RoutableProtocol>*)@protocol(RoutableProtocol)

#pragma mark Error

FOUNDATION_EXTERN NSErrorDomain const ZIKRouteErrorDomain;

/// Error code for ZIKRouter.
#ifdef NS_ERROR_ENUM
typedef NS_ERROR_ENUM(ZIKRouteErrorDomain, ZIKRouteError) {
#else
typedef NS_ENUM(NSInteger, ZIKRouteError) {
#endif
    /// The protocol to fetch the router is not registered. Fix this error in the development phase.
    ZIKRouteErrorInvalidProtocol        = 0,
    /// Configuration missed some required values, or some values were conflict, or the external destination to prepare/perform is invalid. Fix this error in the development phase.
    ZIKRouteErrorInvalidConfiguration   = 1,
    /// Router returns nil for destination, you can't use this service now. Maybe your configuration is invalid, or there is a bug in the router.
    ZIKRouteErrorDestinationUnavailable = 2,
    /*
     Perform or remove route action failed.
     @discussion
     1. Do performRoute when router state is removing, or is routed and should be removed first before another performing.
     
     2. Do removeRoute but the destination was already dealloced.
     
     3. Do removeRoute when a router is not performed yet.
     */
    ZIKRouteErrorActionFailed           = 3,
    /// Do performRoute when router state is routing.
    ZIKRouteErrorOverRoute              = 4,
    /// Infinite recursion for performing route detected. See -prepareDestination:configuration: for more detail. Fix this error in the development phase.
    ZIKRouteErrorInfiniteRecursion      = 5
};

NS_ASSUME_NONNULL_END
