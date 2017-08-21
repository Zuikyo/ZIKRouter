//
//  ZIKViewRouteAdapter.h
//  ZIKRouter
//
//  Created by zuik on 2017/8/21.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKViewRouter.h"

NS_ASSUME_NONNULL_BEGIN


///Subclass it and register protocols for other ZIKViewRouter in the subclass's +registerRoutableDestination with ZIKViewRouter_registerViewProtocol() or ZIKViewRouter_registerConfigProtocol().
@interface ZIKViewRouteAdapter : ZIKViewRouter <ZIKViewRouterProtocol>

- (nullable instancetype)initWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration
                           removeConfiguration:(nullable __kindof ZIKViewRemoveConfiguration *)removeConfiguration NS_UNAVAILABLE;
- (nullable instancetype)initWithConfigure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder
                           removeConfigure:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (BOOL)canPerform NS_UNAVAILABLE;
- (void)performRoute NS_UNAVAILABLE;
- (void)performRouteWithSuccessHandler:(void(^ __nullable)(void))performerSuccessHandler
                 performerErrorHandler:(void(^ __nullable)(SEL routeAction, NSError *error))performerErrorHandler NS_UNAVAILABLE;
- (BOOL)canRemove NS_UNAVAILABLE;
- (void)removeRoute NS_UNAVAILABLE;
- (void)removeRouteWithSuccessHandler:(void(^ __nullable)(void))performerSuccessHandler
                performerErrorHandler:(void(^ __nullable)(SEL routeAction, NSError *error))performerErrorHandler NS_UNAVAILABLE;
+ (nullable __kindof ZIKViewRouter *)performWithConfigure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder
                                          removeConfigure:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
+ (nullable __kindof ZIKViewRouter *)performWithConfigure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder NS_UNAVAILABLE;
+ (__kindof ZIKViewRouter *)performWithSource:(id<ZIKViewRouteSource>)source routeType:(ZIKViewRouteType)routeType NS_UNAVAILABLE;
+ (nullable __kindof ZIKViewRouter *)performOnDestination:(id)destination
                                                configure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder
                                          removeConfigure:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
+ (nullable __kindof ZIKViewRouter *)performOnDestination:(id)destination
                                                configure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder NS_UNAVAILABLE;
+ (__kindof ZIKViewRouter *)performOnDestination:(id)destination source:(id<ZIKViewRouteSource>)source routeType:(ZIKViewRouteType)routeType NS_UNAVAILABLE;
+ (nullable __kindof ZIKViewRouter *)prepareDestination:(id)destination
                                              configure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder
                                        removeConfigure:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
+ (nullable __kindof ZIKViewRouter *)prepareDestination:(id)destination
                                              configure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
