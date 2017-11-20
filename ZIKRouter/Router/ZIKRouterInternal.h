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
@interface ZIKRouter<__covariant RouteConfig: id, __covariant RemoveConfig: id> ()
///Previous state.
@property (nonatomic, readonly, assign) ZIKRouterState preState;
///Subclass can get the real configuration to avoid unnecessary copy.
@property (nonatomic, readonly, copy) RouteConfig original_configuration;
@property (nonatomic, readonly, copy) RemoveConfig original_removeConfiguration;
@property (nonatomic, readonly, weak) id destination;

#pragma mark Override
///Methods for ZIKRouter subclass.

///Create destination and initilize it with configuration.
- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration;

///If a router need to perform on a specific thread, override -performWithConfiguration: and call [super performWithConfiguration:configuration] in that thread.
- (void)performWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration;

///Perform your custom route action.
- (void)performRouteOnDestination:(nullable id)destination configuration:(__kindof ZIKRouteConfiguration *)configuration;
///If the router use a custom configuration, override this and return the configuration.
//+ (__kindof ZIKRouteConfiguration *)defaultRouteConfiguration;

///If the router use a custom configuration, override this and return the configuration.
+ (RouteConfig)defaultRouteConfiguration;

///If you can undo your route action, such as dismiss a routed view, do remove in this.
- (void)removeDestination:(id)destination removeConfiguration:(__kindof ZIKRouteConfiguration *)removeConfiguration;

///If the router use a custom configuration, override this and return the configuration.
+ (__kindof ZIKRouteConfiguration *)defaultRemoveConfiguration;

- (NSString *)errorDomain;

#pragma mark Internal Methods

//Attach a destination not created from router.
- (void)attachDestination:(id)destination;

///Change state.
- (void)notifyRouteState:(ZIKRouterState)state;

///Call sucessHandler and performerSuccessHandler.
- (void)notifySuccessWithAction:(SEL)routeAction;

///Call errorHandler and performerErrorHandler.
- (void)notifyError:(NSError *)error routeAction:(SEL)routeAction;

+ (NSError *)errorWithCode:(NSInteger)code userInfo:(nullable NSDictionary *)userInfo;
+ (NSError *)errorWithCode:(NSInteger)code localizedDescription:(NSString *)description;
+ (NSError *)errorWithCode:(NSInteger)code localizedDescriptionFormat:(NSString *)format ,...;
@end

NS_ASSUME_NONNULL_END
