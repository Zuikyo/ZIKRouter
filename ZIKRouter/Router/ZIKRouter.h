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

- (nullable instancetype)initWithConfiguration:(RouteConfig)configuration
                           removeConfiguration:(nullable RemoveConfig)removeConfiguration NS_DESIGNATED_INITIALIZER;
///Convenient method to create configuration in a builder block.
- (nullable instancetype)initWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                    removing:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfig config))removeConfigBuilder;
/**
 Convenient method to create configuration in a builder block and prepare destination or module in block.
 @discussion
 `prepareDest` and `prepareModule`'s type changes with the router's generic parameters.

 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escapting block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @param removeConfigBuilder Type safe builder to build remove configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escapting block so use weakSelf in it).
 @return The router.
 */
- (nullable instancetype)initWithRouteConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                       void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                       void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                       ))configBuilder
                                    routeRemoving:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfig config,
                                                                                 void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                 ))removeConfigBuilder;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

#pragma mark Perform

///Whether the router can perform route now.
- (BOOL)canPerform;
///Perform route directly.
- (void)performRoute;
///Perform with success handler and error handler.
- (void)performRouteWithSuccessHandler:(void(^ __nullable)(void))performerSuccessHandler
                          errorHandler:(void(^ __nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler;

///If this route action doesn't need any arguments, just perform directly.
+ (nullable instancetype)performRoute;
///Convenient method to prepare destination and perform route.
+ (nullable instancetype)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;
///Convenient method to prepare destination and perform route, and you can remove the route with remove configuration later.
+ (nullable instancetype)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                       removing:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfig config))removeConfigBuilder;

/**
 Convenient method to prepare destination in a type safe way inferred by generic parameters and perform route.

 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escapting block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @return The router.
 */
+ (nullable instancetype)performWithRouteConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                          void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                          void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                          ))configBuilder;

/**
 Convenient method to prepare destination in a type safe way inferred by generic parameters and perform route, and you can remove the route with remove configuration later.

 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escapting block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @param removeConfigBuilder Type safe builder to build remove configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escapting block so use weakSelf in it).
 @return The router.
 */
+ (nullable instancetype)performWithRouteConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                          void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                          void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                          ))configBuilder
                                       routeRemoving:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfig config,
                                                                                    void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                    ))removeConfigBuilder;

#pragma mark Remove

///Whether the router can remove route now.
- (BOOL)canRemove;
///Remove route directly. If -canRemove return NO, this will failed.
- (void)removeRoute;
///Remove with success handler and error handler.
- (void)removeRouteWithSuccessHandler:(void(^ __nullable)(void))performerSuccessHandler
                         errorHandler:(void(^ __nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler;
///Remove route and prepare before removing.
- (void)removeRouteWithConfiguring:(void(NS_NOESCAPE ^)(RemoveConfig config))removeConfigBuilder;

///Remove route and prepare before removing.
- (void)removeRouteWithRouteConfiguring:(void(NS_NOESCAPE ^)(RemoveConfig config,
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
+ (nullable Destination)makeDestinationWithConfiguring:(void(^ _Nullable)(RouteConfig config))configBuilder;

/**
 Synchronously get destination, and prepare the destination in a type safe way inferred by generic parameters.

 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escapting block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @return The prepared destination.
 */
+ (nullable Destination)makeDestinationWithRouteConfiguring:(void(^ _Nullable)(RouteConfig config,
                                                                               void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                               void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                               ))configBuilder;

#pragma mark Debug

+ (NSString *)descriptionOfState:(ZIKRouterState)state;
@end

NS_ASSUME_NONNULL_END
