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

///Methods for ZIKRouter subclass
@protocol ZIKRouterProtocol <NSObject>
@required
///Create destination and initilize it with configuration
- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration;
///Perform your custom route action
- (void)performRouteOnDestination:(nullable id)destination configuration:(__kindof ZIKRouteConfiguration *)configuration;
///If the router use a custom configuration, override this and return the configuration
+ (__kindof ZIKRouteConfiguration *)defaultRouteConfiguration;

///Whether the router can perform route now
- (BOOL)canPerform;
///Whether the router can remove route now
- (BOOL)canRemove;
///If you can undo your route action, such as dismiss a routed view, do remove in this
- (void)removeDestination:(id)destination removeConfiguration:(__kindof ZIKRouteConfiguration *)removeConfiguration;
///If the router use a custom configuration, override this and return the configuration
+ (__kindof ZIKRouteConfiguration *)defaultRemoveConfiguration;

@optional
///Whether the route action is synchronously
+ (BOOL)completeSynchronously;
- (NSString *)errorDomain;

@end

/**
 Abstract superclass for router that can perform route and remove route.
 @discussion
 Features:
 
 1. Prepare the route with protocol in block, instead of directly configuring the destination (the source is coupled with the destination if you do this) or in delegate method (in -prepareForSegue:sender: you have to distinguish different destinations, and they're alse coupled with source).
 
 2. Specify a router with generic and protocol, then you can hide subclass but still can get routers with different functions.
 
 See sample code in ZIKServiceRouter and ZIKViewRouter for more detail.
 */
@interface ZIKRouter<__covariant RouteConfig: ZIKRouteConfiguration *, __covariant RemoveConfig: ZIKRouteConfiguration *, __covariant RouterType> : NSObject <ZIKRouterProtocol>
///State of route.
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
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (BOOL)canPerform;
///Perform route directly.
- (void)performRoute;
///Perform with success handler and error handler.
- (void)performRouteWithSuccessHandler:(void(^ __nullable)(void))performerSuccessHandler
                          errorHandler:(void(^ __nullable)(SEL routeAction, NSError *error))performerErrorHandler;

- (BOOL)canRemove;
///Remove route directly.
- (void)removeRoute;
///Remove with success handler and error handler.
- (void)removeRouteWithSuccessHandler:(void(^ __nullable)(void))performerSuccessHandler
                         errorHandler:(void(^ __nullable)(SEL routeAction, NSError *error))performerErrorHandler;

///If this route action doesn't need any arguments, just perform directly.
+ (nullable RouterType)performRoute;
///Set dependencies required by destination and perform route.
+ (nullable RouterType)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;
///Set dependencies required by destination and perform route, and you can remove the route with remove configuration later.
+ (nullable RouterType)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                     removing:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfig config))removeConfigBuilder;

///Whether the route action is synchronously.
+ (BOOL)completeSynchronously;
+ (NSString *)descriptionOfState:(ZIKRouterState)state;
@end

NS_ASSUME_NONNULL_END
