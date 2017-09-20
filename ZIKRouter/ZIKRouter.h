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

NS_ASSUME_NONNULL_BEGIN

@class ZIKRouteConfiguration;

///ZIKRouter subclass
@protocol ZIKRouterProtocol <NSObject>
@required
///Generate destination and initilize it with configuration
- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration;
///Perform your custom route action
- (void)performRouteOnDestination:(nullable id)destination configuration:(__kindof ZIKRouteConfiguration *)configuration;
+ (__kindof ZIKRouteConfiguration *)defaultRouteConfiguration;

- (BOOL)canPerform;
- (BOOL)canRemove;
//If you can undo your route action, such as dismiss a routed view, do remove in this
- (void)removeDestination:(id)destination removeConfiguration:(__kindof ZIKRouteConfiguration *)removeConfiguration;
+ (__kindof ZIKRouteConfiguration *)defaultRemoveConfiguration;

@optional
+ (BOOL)completeSynchronously;
- (NSString *)errorDomain;

@end

typedef NS_ENUM(NSInteger, ZIKRouterState) {
    ZIKRouterStateNotRoute,
    ZIKRouterStateRouting,
    ZIKRouterStateRouted,
    ZIKRouterStateRouteFailed,
    ZIKRouterStateRemoving,
    ZIKRouterStateRemoved,
    ZIKRouterStateRemoveFailed
};

///Abstract class for router. A router for decoupling between modules, and injecting dependencies with protocol.
@interface ZIKRouter<__covariant RouteConfiguration: ZIKRouteConfiguration *, __covariant RemoveConfiguration: ZIKRouteConfiguration *> : NSObject <ZIKRouterProtocol>
///State of route
@property (nonatomic, readonly, assign) ZIKRouterState state;
///Configuration for performRoute; return copy of configuration, so modify this won't change the real configuration inside router
@property (nonatomic, readonly, copy) RouteConfiguration configuration;
///Configuration for removeRoute; return copy of configuration, so modify this won't change the real configuration inside router
@property (nonatomic, readonly, copy ,nullable) RemoveConfiguration removeConfiguration;
//Latest error when route action failed
@property (nonatomic, readonly, strong, nullable) NSError *error;

- (nullable instancetype)initWithConfiguration:(RouteConfiguration)configuration
                           removeConfiguration:(nullable RemoveConfiguration)removeConfiguration NS_DESIGNATED_INITIALIZER;
///Convenient method to create configuration in a builder block
- (nullable instancetype)initWithConfigure:(void(NS_NOESCAPE ^)(RouteConfiguration config))configBuilder
                           removeConfigure:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfiguration config))removeConfigBuilder;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (BOOL)canPerform;
///Not thread safe
- (void)performRoute;
///Not thread safe
- (void)performRouteWithSuccessHandler:(void(^ __nullable)(void))performerSuccessHandler
                    performerErrorHandler:(void(^ __nullable)(SEL routeAction, NSError *error))performerErrorHandler;

- (BOOL)canRemove;
///Not thread safe
- (void)removeRoute;
///Not thread safe
- (void)removeRouteWithSuccessHandler:(void(^ __nullable)(void))performerSuccessHandler
                   performerErrorHandler:(void(^ __nullable)(SEL routeAction, NSError *error))performerErrorHandler;

///If this route action doesn't need any argument, just perform directly
+ (nullable __kindof ZIKRouter *)performRoute;
///Set dependencies required by destination and perform route
+ (nullable __kindof ZIKRouter *)performWithConfigure:(void(NS_NOESCAPE ^)(RouteConfiguration config))configBuilder;
+ (nullable __kindof ZIKRouter *)performWithConfigure:(void(NS_NOESCAPE ^)(RouteConfiguration config))configBuilder
                                      removeConfigure:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfiguration config))removeConfigBuilder;

+ (BOOL)completeSynchronously;
+ (NSString *)descriptionOfState:(ZIKRouterState)state;
@end

typedef void(^ZIKRouteErrorHandler)(SEL routeAction, NSError *error);
typedef void(^ZIKRouteStateNotifier)(ZIKRouterState oldState, ZIKRouterState newState);

///For config destination
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
 Monitor state change
 @note
 Use weakSelf in stateNotifier to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) ZIKRouteStateNotifier stateNotifier;
@end

NS_ASSUME_NONNULL_END
