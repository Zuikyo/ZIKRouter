//
//  ZIKRouterInternal.h
//  ZIKRouter
//
//  Created by zuik on 2017/5/24.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouter.h"

NS_ASSUME_NONNULL_BEGIN

///Internal methods for subclass.
@interface ZIKRouter<__covariant Destination: id, __covariant RouteConfig: ZIKPerformRouteConfiguration *, __covariant RemoveConfig: ZIKRemoveRouteConfiguration *> ()
///Previous state.
@property (nonatomic, readonly, assign) ZIKRouterState preState;
///Subclass can get the real configuration to avoid unnecessary copy.
@property (nonatomic, readonly, copy) RouteConfig original_configuration;
@property (nonatomic, readonly, copy) RemoveConfig original_removeConfiguration;
@property (nonatomic, readonly, weak) Destination destination;

#pragma mark Required Override
///Methods for ZIKRouter subclass.

///Create destination and initilize it with configuration. If the configuration is invalid, return nil to make this route failed.
- (nullable Destination)destinationWithConfiguration:(RouteConfig)configuration;

#pragma mark Optional Override

///If a router need to perform on a specific thread, override -performWithConfiguration: and call [super performWithConfiguration:configuration] in that thread.
- (void)performWithConfiguration:(RouteConfig)configuration;

///Perform your custom route action.
- (void)performRouteOnDestination:(nullable Destination)destination configuration:(RouteConfig)configuration;

///If the router use a custom configuration, override this and return the configuration.
+ (RouteConfig)defaultRouteConfiguration;

///If you can undo your route action, such as dismiss a routed view, do remove in this. The destination was hold as weak in router, so you should check whether the destination still exists.
- (void)removeDestination:(nullable Destination)destination removeConfiguration:(RemoveConfig)removeConfiguration;

///If the router use a custom configuration, override this and return the configuration.
+ (RemoveConfig)defaultRemoveConfiguration;

- (NSString *)errorDomain;

///Whether this router is an abstract router.
+ (BOOL)isAbstractRouter;

///Whether this router is an adapter for another router.
+ (BOOL)isAdapter;

#pragma mark Internal Methods

///Attach a destination not created from router.
- (void)attachDestination:(Destination)destination;

///Change state.
- (void)notifyRouteState:(ZIKRouterState)state;

///Call sucessHandler and performerSuccessHandler.
- (void)notifySuccessWithAction:(ZIKRouteAction)routeAction;

///Call errorHandler and performerErrorHandler.
- (void)notifyError:(NSError *)error routeAction:(ZIKRouteAction)routeAction;

+ (NSError *)errorWithCode:(NSInteger)code userInfo:(nullable NSDictionary *)userInfo;
+ (NSError *)errorWithCode:(NSInteger)code localizedDescription:(NSString *)description;
+ (NSError *)errorWithCode:(NSInteger)code localizedDescriptionFormat:(NSString *)format ,...;
@end

NS_ASSUME_NONNULL_END
