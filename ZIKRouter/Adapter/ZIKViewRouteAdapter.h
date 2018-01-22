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
 Subclass it and register protocols for other ZIKViewRouter in the subclass's +registerRoutableDestination with +registerViewProtocol: or +registerModuleProtocol:. It's only for register protocols for other ZIKViewRouter, don't use it's instance.
 @discussion
 Why you need an adapter to decouple? There is a situation: module A need to use a file log module inside it, and A use the log module with a required interface (ModuleALogProtocol). The app context provides the log module as module B, and module B uses a provided interface (ModuleBLogProtocol). So in the app context, you need to adapte required interface(ModuleALogProtocol) and provided interface(ModuleBLogProtocol). Use category, swift extension, NSProxy or custom mediator to forward ModuleALogProtocol to ModuleBLogProtocol. Then module A is totally decoupled with module B.
 */
@interface ZIKViewRouteAdapter : ZIKViewRouter

- (nullable instancetype)initWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration
                           removeConfiguration:(nullable __kindof ZIKViewRemoveConfiguration *)removeConfiguration NS_UNAVAILABLE;
- (nullable instancetype)initWithConfiguring:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder
                                    removing:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
- (nullable instancetype)initWithRouteConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                       void(^prepareDest)(void(^prepare)(id dest)),
                                                                       void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ZIKViewRouteConfiguration *module))
                                                                       ))configBuilder
                                    routeRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config,
                                                                                 void(^prepareDest)(void(^prepare)(id dest))
                                                                                 ))removeConfigBuilder NS_UNAVAILABLE;
- (BOOL)canPerform NS_UNAVAILABLE;
- (void)performRoute NS_UNAVAILABLE;
- (void)performRouteWithSuccessHandler:(void(^ __nullable)(void))performerSuccessHandler
                          errorHandler:(void(^ __nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler NS_UNAVAILABLE;
- (BOOL)canRemove NS_UNAVAILABLE;
- (void)removeRoute NS_UNAVAILABLE;
- (void)removeRouteWithSuccessHandler:(void(^ __nullable)(void))performerSuccessHandler
                         errorHandler:(void(^ __nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler NS_UNAVAILABLE;
+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source configuring:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder NS_UNAVAILABLE;
+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source
                               configuring:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder
                                  removing:(void(NS_NOESCAPE ^ _Nullable)(__kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source routeType:(ZIKViewRouteType)routeType NS_UNAVAILABLE;
+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source
                          routeConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                void(^prepareDest)(void(^prepare)(id dest)),
                                                                void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ZIKViewRouteConfiguration *module))
                                                                ))configBuilder NS_UNAVAILABLE;
+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source
                          routeConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                void(^prepareDest)(void(^prepare)(id dest)),
                                                                void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ZIKViewRouteConfiguration *module))
                                                                ))configBuilder
                             routeRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config,
                                                                          void(^prepareDest)(void(^prepare)(id dest))
                                                                          ))removeConfigBuilder NS_UNAVAILABLE;
+ (nullable instancetype)performOnDestination:(id)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                                  configuring:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder NS_UNAVAILABLE;
+ (nullable instancetype)performOnDestination:(id)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                                  configuring:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder
                                     removing:(void(NS_NOESCAPE ^ _Nullable)(__kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
+ (nullable instancetype)performOnDestination:(id)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                                    routeType:(ZIKViewRouteType)routeType NS_UNAVAILABLE;
+ (nullable instancetype)performOnDestination:(id)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                             routeConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                   void(^prepareDest)(void(^prepare)(id dest)),
                                                                   void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ZIKViewRouteConfiguration *module))
                                                                   ))configBuilder NS_UNAVAILABLE;
+ (nullable instancetype)performOnDestination:(id)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                             routeConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                   void(^prepareDest)(void(^prepare)(id dest)),
                                                                   void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ZIKViewRouteConfiguration *module))
                                                                   ))configBuilder
                                routeRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config,
                                                                             void(^prepareDest)(void(^prepare)(id dest))
                                                                             ))removeConfigBuilder NS_UNAVAILABLE;
+ (nullable instancetype)prepareDestination:(id)destination
                                configuring:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder
                                   removing:(void(NS_NOESCAPE ^ _Nullable)(__kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
+ (nullable instancetype)prepareDestination:(id)destination
                                configuring:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder NS_UNAVAILABLE;
+ (nullable instancetype)prepareDestination:(id)destination
                           routeConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                 void(^prepareDest)(void(^prepare)(id dest)),
                                                                 void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ZIKViewRouteConfiguration *module))
                                                                 ))configBuilder NS_UNAVAILABLE;
+ (nullable instancetype)prepareDestination:(id)destination
                           routeConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                 void(^prepareDest)(void(^prepare)(id dest)),
                                                                 void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ZIKViewRouteConfiguration *module))
                                                                 ))configBuilder
                              routeRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config,
                                                                           void(^prepareDest)(void(^prepare)(id dest))
                                                                           ))removeConfigBuilder NS_UNAVAILABLE;
+ (BOOL)makeDestinationSynchronously NS_UNAVAILABLE;
+ (BOOL)canMakeDestination NS_UNAVAILABLE;
+ (nullable id)makeDestination NS_UNAVAILABLE;
+ (nullable id)makeDestinationWithPreparation:(void(^ _Nullable)(id destination))prepare NS_UNAVAILABLE;
+ (nullable id)makeDestinationWithConfiguring:(void(^ _Nullable)(ZIKViewRouteConfiguration *config))configBuilder NS_UNAVAILABLE;
+ (nullable id)makeDestinationWithRouteConfiguring:(void(^ _Nullable)(ZIKViewRouteConfiguration *config,
                                                                      void(^prepareDest)(void(^prepare)(id dest)),
                                                                      void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ZIKViewRouteConfiguration *module))
                                                                      ))configBuilder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
