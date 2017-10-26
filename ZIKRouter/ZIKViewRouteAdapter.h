//
//  ZIKViewRouteAdapter.h
//  ZIKRouter
//
//  Created by zuik on 2017/8/21.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRouter.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Subclass it and register protocols for other ZIKViewRouter in the subclass's +registerRoutableDestination with +registerViewProtocol: or +registerConfigProtocol:. It's only for register protocol for other ZIKViewRouter in it's +registerRoutableDestination, don't use it's instance.
 @discussion
 When you need a adapter ? Module A need to use a file log module inside it, and A use the log module with a require interface (ModuleALogProtocol). The app context provides the log module with module B, and Module B use a provide interface (ModuleBLogProtocol). So in the app context, you need to adapte require interface(ModuleALogProtocol) and provide interface(ModuleBLogProtocol). Then Module A is totally decoupled with Module B.
 */
@interface ZIKViewRouteAdapter : ZIKViewRouter <ZIKViewRouterProtocol>

- (nullable instancetype)initWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration
                           removeConfiguration:(nullable __kindof ZIKViewRemoveConfiguration *)removeConfiguration NS_UNAVAILABLE;
- (nullable instancetype)initWithConfigure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder
                           removeConfigure:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (BOOL)canPerform NS_UNAVAILABLE;
- (void)performRoute NS_UNAVAILABLE;
- (void)performRouteWithSuccessHandler:(void(^ __nullable)(void))performerSuccessHandler
                          errorHandler:(void(^ __nullable)(SEL routeAction, NSError *error))performerErrorHandler NS_UNAVAILABLE;
- (BOOL)canRemove NS_UNAVAILABLE;
- (void)removeRoute NS_UNAVAILABLE;
- (void)removeRouteWithSuccessHandler:(void(^ __nullable)(void))performerSuccessHandler
                         errorHandler:(void(^ __nullable)(SEL routeAction, NSError *error))performerErrorHandler NS_UNAVAILABLE;
+ (nullable __kindof ZIKViewRouter *)performWithConfigure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder
                                          removeConfigure:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
+ (nullable __kindof ZIKViewRouter *)performWithConfigure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder NS_UNAVAILABLE;
+ (__kindof ZIKViewRouter *)performWithSource:(nullable id<ZIKViewRouteSource>)source routeType:(ZIKViewRouteType)routeType NS_UNAVAILABLE;
+ (nullable __kindof ZIKViewRouter *)performOnDestination:(id)destination
                                                configure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder
                                          removeConfigure:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
+ (nullable __kindof ZIKViewRouter *)performOnDestination:(id)destination
                                                configure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder NS_UNAVAILABLE;
+ (__kindof ZIKViewRouter *)performOnDestination:(id)destination source:(nullable id<ZIKViewRouteSource>)source routeType:(ZIKViewRouteType)routeType NS_UNAVAILABLE;
+ (nullable __kindof ZIKViewRouter *)prepareDestination:(id)destination
                                              configure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder
                                        removeConfigure:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
+ (nullable __kindof ZIKViewRouter *)prepareDestination:(id)destination
                                              configure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
