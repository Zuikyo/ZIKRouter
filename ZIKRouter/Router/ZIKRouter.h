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

///Enble this to check whether all routers and routable protocols are properly implemented.
#ifdef DEBUG
#define ZIKROUTER_CHECK 1
#else
#define ZIKROUTER_CHECK 0
#endif

/**
 Abstract superclass for router that can perform route and remove route.
 @discussion
 ## Features:
 
 1. Prepare module with protocol in block, instead of directly configuring the destination or in delegate method (in -prepareForSegue:sender: you have to distinguish different destinations).
 
 2. Specify a router with generic and protocol, then you can hide subclass but still can get routers with different functions.
 
 See sample code in ZIKServiceRouter and ZIKViewRouter for more detail.
 
 @note
 The router only keep weak reference to the destination, the performer is responsible for holding it.
 */
@interface ZIKRouter<__covariant Destination: id, __covariant RouteConfig: ZIKPerformRouteConfiguration *, __covariant RemoveConfig: ZIKRemoveRouteConfiguration *> : NSObject
///State of route. View router's state will be auto changed when the destination's state is changed.
@property (nonatomic, readonly, assign) ZIKRouterState state;
///Configuration for performRoute; Return copy of configuration, so modify this won't change the real configuration inside router.
@property (nonatomic, readonly, copy) RouteConfig configuration;
///Configuration for removeRoute; return copy of configuration, so modify this won't change the real configuration inside router.
@property (nonatomic, readonly, copy ,nullable) RemoveConfig removeConfiguration;
///Latest error when route action failed.
@property (nonatomic, readonly, strong, nullable) NSError *error;
//Set error handler for all router instance. Use this to debug and log.
@property (class, copy, nullable) void(^globalErrorHandler)(__kindof ZIKRouter *_Nullable router, ZIKRouteAction action, NSError *error);

- (nullable instancetype)initWithConfiguration:(RouteConfig)configuration
                           removeConfiguration:(nullable RemoveConfig)removeConfiguration NS_DESIGNATED_INITIALIZER;
///Convenient method to create configuration in a builder block.
- (nullable instancetype)initWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                    removing:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfig config))removeConfigBuilder;
/**
 Convenient method to create configuration in a builder block and prepare destination or module in block.
 @discussion
 `prepareDest` and `prepareModule`'s type changes with the router's generic parameters.

 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @param removeConfigBuilder Type safe builder to build remove configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it).
 @return The router.
 */
- (nullable instancetype)initWithStrictConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                        void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                        void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                        ))configBuilder
                                    strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfig config,
                                                                                  void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                  ))removeConfigBuilder;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

#pragma mark Perform

///Whether the router can perform route now.
- (BOOL)canPerform;

///Perform route directly.
- (void)performRoute;
///Perform with success handler and error handler. Blocks are only for currrent performing.
- (void)performRouteWithSuccessHandler:(void(^ _Nullable)(Destination destination))performerSuccessHandler
                          errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler;
///Perform with completion. The completion is only for currrent performing.
- (void)performRouteWithCompletion:(void(^)(BOOL success, Destination _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion;

///If this route action doesn't need any arguments, just perform directly.
+ (nullable instancetype)performRoute;
///If this route action doesn't need any arguments, perform directly with successHandler and errorHandler for current performing.
+ (nullable instancetype)performWithSuccessHandler:(void(^ _Nullable)(Destination destination))performerSuccessHandler
                                      errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler;
///If this route action doesn't need any arguments, perform directly with completion for current performing.
+ (nullable instancetype)performWithCompletion:(void(^)(BOOL success, Destination _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion;

///Convenient method to prepare destination and perform route.
+ (nullable instancetype)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;
///Convenient method to prepare destination and perform route, and you can remove the route with remove configuration later.
+ (nullable instancetype)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                       removing:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfig config))removeConfigBuilder;

/**
 Convenient method to prepare destination in a type safe way inferred by generic parameters and perform route.

 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @return The router.
 */
+ (nullable instancetype)performWithStrictConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                           void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                           void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                           ))configBuilder;

/**
 Convenient method to prepare destination in a type safe way inferred by generic parameters and perform route, and you can remove the route with remove configuration later.

 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @param removeConfigBuilder Type safe builder to build remove configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it).
 @return The router.
 */
+ (nullable instancetype)performWithStrictConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                           void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                           void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                           ))configBuilder
                                       strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfig config,
                                                                                     void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                     ))removeConfigBuilder;

#pragma mark Remove

///Whether the router should be removed before another performing, when the router was performed already.
- (BOOL)shouldRemoveBeforePerform;

///Whether the router can remove route now.
- (BOOL)canRemove;
///Remove route directly. If -canRemove return NO, this will failed.
- (void)removeRoute;
///Remove with success handler and error handler for current removing.
- (void)removeRouteWithSuccessHandler:(void(^ _Nullable)(void))performerSuccessHandler
                         errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler;
///Remove route with completion for current removing.
- (void)removeRouteWithCompletion:(void(^)(BOOL success, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion;
///Remove route and prepare before removing.
- (void)removeRouteWithConfiguring:(void(NS_NOESCAPE ^)(RemoveConfig config))removeConfigBuilder;

///Remove route and prepare before removing.
- (void)removeRouteWithStrictConfiguring:(void(NS_NOESCAPE ^)(RemoveConfig config,
                                                              void(^prepareDest)(void(^prepare)(Destination dest))
                                                              ))removeConfigBuilder;

#pragma mark Factory

///Whether the destination is instantiated synchronously.
+ (BOOL)canMakeDestinationSynchronously;

///The router may can't make destination synchronously, or it's not for providing a destination but only for performing some actions.
+ (BOOL)canMakeDestination;

///Synchronously get destination.
+ (nullable Destination)makeDestination;

///Synchronously get destination, and prepare the destination with destination protocol.
+ (nullable Destination)makeDestinationWithPreparation:(void(^ _Nullable)(Destination destination))prepare;

///Synchronously get destination, and prepare the destination.
+ (nullable Destination)makeDestinationWithConfiguring:(void(NS_NOESCAPE ^ _Nullable)(RouteConfig config))configBuilder;

/**
 Synchronously get destination, and prepare the destination in a type safe way inferred by generic parameters.

 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @return The prepared destination.
 */
+ (nullable Destination)makeDestinationWithStrictConfiguring:(void(NS_NOESCAPE ^ _Nullable)(RouteConfig config,
                                                                                            void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                            void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                                            ))configBuilder;

#pragma mark Debug

+ (NSString *)descriptionOfState:(ZIKRouterState)state;

#pragma mark Deprecated

- (nullable instancetype)initWithRouteConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                       void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                       void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                       ))configBuilder
                                    routeRemoving:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfig config,
                                                                                 void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                 ))removeConfigBuilder API_DEPRECATED_WITH_REPLACEMENT("initWithStrictConfiguring:strictRemoving:", ios(7.0, 7.0));
+ (nullable instancetype)performWithRouteConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                          void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                          void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                          ))configBuilder API_DEPRECATED_WITH_REPLACEMENT("+performWithStrictConfiguring:", ios(7.0, 7.0));
+ (nullable instancetype)performWithRouteConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                          void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                          void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                          ))configBuilder
                                       routeRemoving:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfig config,
                                                                                    void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                    ))removeConfigBuilder API_DEPRECATED_WITH_REPLACEMENT("+performWithStrictConfiguring:strictRemoving:", ios(7.0, 7.0));
- (void)removeRouteWithRouteConfiguring:(void(NS_NOESCAPE ^)(RemoveConfig config,
                                                             void(^prepareDest)(void(^prepare)(Destination dest))
                                                             ))removeConfigBuilder API_DEPRECATED_WITH_REPLACEMENT("removeRouteWithStrictConfiguring:", ios(7.0, 7.0));
+ (nullable Destination)makeDestinationWithRouteConfiguring:(void(^ _Nullable)(RouteConfig config,
                                                                               void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                               void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                               ))configBuilder API_DEPRECATED_WITH_REPLACEMENT("+makeDestinationWithStrictConfiguring:", ios(7.0, 7.0));
@end

extern NSErrorDomain const ZIKRouteErrorDomain;

typedef NS_ERROR_ENUM(ZIKRouteErrorDomain, ZIKRouteError) {
    ///The protocol to fetch the router is not registered. Fix this error in the development phase.
    ZIKRouteErrorInvalidProtocol        = 0,
    ///Configuration missed some required values, or some values were conflict, or the external destination to prepare/perform is invalid. Fix this error in the development phase.
    ZIKRouteErrorInvalidConfiguration   = 1,
    ///Router returns nil for destination, you can't use this service now. Maybe your configuration is invalid, or there is a bug in the router.
    ZIKRouteErrorDestinationUnavailable = 2,
    /*
     Perform or remove route action failed.
     @discussion
     1. Do performRoute when router state is removing, or is routed and should be removed first before another performing.
     
     2. Do removeRoute but the destination was already dealloced.
     
     3. Do removeRoute when a router is not performed yet.
     */
    ZIKRouteErrorActionFailed           = 3,
    ///Do performRoute when router state is routing.
    ZIKRouteErrorOverRoute              = 4,
    ///Infinite recursion for performing route detected. See -prepareDestination:configuration: for more detail. Fix this error in the development phase.
    ZIKRouteErrorInfiniteRecursion      = 5
};

NS_ASSUME_NONNULL_END
