//
//  ZIKServiceRouteAdapter.h
//  ZIKRouter
//
//  Created by zuik on 2017/8/21.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKServiceRouter.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Adapter for adapting provided protocol to required protocol. It's only for register protocols for other ZIKServiceRouter, don't use its instance. Subclass it and register protocols for other ZIKServiceRouter in the subclass's +registerRoutableDestination with +registerServiceProtocol: or +registerModuleProtocol:, and let the service conforms to the required protocol with category, extension or proxy.
 @discussion
 About module adapter, read https://github.com/Zuikyo/ZIKRouter/blob/master/Documentation/English/ModuleAdapter.md
 
 Why you need an adapter to decouple? There is a situation: module A need to use a file log module inside it, and A use the log module with a required interface (ModuleALogProtocol). The app context provides the log module as module B, and module B use a provided interface (ModuleBLogProtocol). So in the app context, you need to adapt required interface(ModuleALogProtocol) and provided interface(ModuleBLogProtocol). Use category, swift extension, NSProxy or custom mediator to forward ModuleALogProtocol to ModuleBLogProtocol. Then module A is totally decoupled with module B.
 */
@interface ZIKServiceRouteAdapter : ZIKServiceRouter

/**
 Register adapter and adaptee protocols conformed by the destination. Then if you try to find router with the adapter, there will return the adaptee's router. In Swift, use `register(adapter:forAdaptee:)` in ZRouter instead.
 
 @param adapterProtocol The required protocol used in the user. The protocol should not be directly registered with any router yet.
 @param adapteeProtocol The provided protocol.
 */
+ (void)registerDestinationAdapter:(Protocol<ZIKServiceRoutable> *)adapterProtocol forAdaptee:(Protocol<ZIKServiceRoutable> *)adapteeProtocol;

/**
 Register adapter and adaptee protocols conformed by the default configuration of the adaptee's router. Then if you try to find router with the adapter, there will return the adaptee's router. In Swift, use `register(adapter:forAdaptee:)` in ZRouter instead.
 
 @param adapterProtocol The required protocol used in the user. The protocol should not be directly registered with any router yet.
 @param adapteeProtocol The provided protocol.
 */
+ (void)registerModuleAdapter:(Protocol<ZIKServiceModuleRoutable> *)adapterProtocol forAdaptee:(Protocol<ZIKServiceModuleRoutable> *)adapteeProtocol;

#pragma mark Unavailable

- (nullable instancetype)initWithConfiguration:(__kindof ZIKPerformRouteConfiguration *)configuration
                           removeConfiguration:(nullable __kindof ZIKRouteConfiguration *)removeConfiguration NS_UNAVAILABLE;
- (nullable instancetype)initWithConfiguring:(void(NS_NOESCAPE ^)(__kindof ZIKPerformRouteConfiguration *config))configBuilder
                           removing:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKRouteConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
- (nullable instancetype)initWithStrictConfiguring:(void(NS_NOESCAPE ^)(ZIKPerformRouteStrictConfiguration *config, ZIKPerformRouteConfiguration *module))configBuilder
                                    strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKRemoveRouteStrictConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
- (BOOL)canPerform NS_UNAVAILABLE;
- (void)performRoute NS_UNAVAILABLE;
- (void)performRouteWithSuccessHandler:(void(^ __nullable)(void))performerSuccessHandler
                          errorHandler:(void(^ __nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler NS_UNAVAILABLE;
- (void)performRouteWithCompletion:(void(^)(BOOL success, id _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion NS_UNAVAILABLE;
- (BOOL)canRemove NS_UNAVAILABLE;
- (void)removeRoute NS_UNAVAILABLE;
- (void)removeRouteWithSuccessHandler:(void(^ __nullable)(void))performerSuccessHandler
                         errorHandler:(void(^ __nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler NS_UNAVAILABLE;
- (void)removeRouteWithCompletion:(void(^)(BOOL success, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion NS_UNAVAILABLE;
+ (nullable instancetype)performRoute NS_UNAVAILABLE;
+ (nullable instancetype)performWithSuccessHandler:(void(^ _Nullable)(id destination))performerSuccessHandler
                                      errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler NS_UNAVAILABLE;
+ (nullable instancetype)performWithCompletion:(void(^)(BOOL success, id _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion NS_UNAVAILABLE;
+ (nullable instancetype)performWithPreparation:(void(^)(id destination))prepare NS_UNAVAILABLE;
+ (nullable __kindof ZIKServiceRouter *)performWithConfiguring:(void(NS_NOESCAPE ^)(__kindof ZIKPerformRouteConfiguration *config))configBuilder
                                             removing:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKRouteConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
+ (nullable __kindof ZIKServiceRouter *)performWithConfiguring:(void(NS_NOESCAPE ^)(__kindof ZIKPerformRouteConfiguration *config))configBuilder NS_UNAVAILABLE;
+ (nullable instancetype)performWithStrictConfiguring:(void(NS_NOESCAPE ^)(ZIKPerformRouteConfiguration *config,
                                                                           ZIKPerformRouteStrictConfiguration<id> *strictConfig
                                                                           ))configBuilder NS_UNAVAILABLE;
+ (nullable instancetype)performWithStrictConfiguring:(void(NS_NOESCAPE ^)(ZIKPerformRouteConfiguration *config,
                                                                           ZIKPerformRouteStrictConfiguration<id> *strictConfig
                                                                           ))configBuilder
                                       strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKPerformRouteConfiguration *config,
                                                                                     ZIKRemoveRouteStrictConfiguration<id> *strictConfig
                                                                                     ))removeConfigBuilder NS_UNAVAILABLE;
+ (BOOL)canMakeDestinationSynchronously NS_UNAVAILABLE;
+ (BOOL)canMakeDestination NS_UNAVAILABLE;
+ (nullable id)makeDestination NS_UNAVAILABLE;
+ (nullable id)makeDestinationWithPreparation:(void(^ _Nullable)(id destination))prepare NS_UNAVAILABLE;
+ (nullable id)makeDestinationWithConfiguring:(void(NS_NOESCAPE ^ _Nullable)(ZIKPerformRouteConfiguration *config))configBuilder NS_UNAVAILABLE;
+ (nullable id)makeDestinationWithStrictConfiguring:(void(NS_NOESCAPE ^ _Nullable)(ZIKPerformRouteStrictConfiguration *config, ZIKPerformRouteConfiguration *module))configBuilder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
