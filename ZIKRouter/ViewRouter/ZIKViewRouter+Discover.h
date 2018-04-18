//
//  ZIKViewRouter+Discover.h
//  ZIKRouter
//
//  Created by zuik on 2018/1/22.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRouter.h"
#import "ZIKViewRouterType.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_UNAVAILABLE("ZIKDestinationViewRouterType is a fake class")
///Fake class to use ZIKViewRouter class type to handle specific destination with compile time checking. The real object is ZIKViewRouterType. Don't check whether a type is kind of ZIKDestinationRouterType.
@interface ZIKDestinationViewRouterType<__covariant Destination: id<ZIKViewRoutable>, __covariant RouteConfig: ZIKViewRouteConfiguration *> : ZIKViewRouterType<Destination, RouteConfig>
@end

NS_SWIFT_UNAVAILABLE("ZIKModuleViewRouterType is a fake class")
///Fake class to use ZIKRouter class type to handle specific view module config with compile time checking. The real object is ZIKViewRouterType. Don't check whether a type is kind of ZIKModuleViewRouterType.
@interface ZIKModuleViewRouterType<__covariant Destination: id<ZIKRoutableView>, __covariant ModuleConfig: id<ZIKViewModuleRoutable>, __covariant RouteConfig: ZIKViewRouteConfiguration *> : ZIKViewRouterType<Destination, RouteConfig>
@end

///Get view router in a type safe way. There will be complie error if the view protocol is not ZIKViewRoutable.
#define ZIKRouterToView(ViewProtocol) (ZIKDestinationViewRouterType<id<ViewProtocol>,ZIKViewRouteConfiguration *> *)[ZIKViewRouter<id<ViewProtocol>,ZIKViewRouteConfiguration *> toView](@protocol(ViewProtocol))

///Get view router in a type safe way. There will be complie error if the module protocol is not ZIKViewModuleRoutable.
#define ZIKRouterToViewModule(ModuleProtocol) (ZIKModuleViewRouterType<id<ZIKRoutableView>,id<ModuleProtocol>,ZIKViewRouteConfiguration<ModuleProtocol> *> *)[ZIKViewRouter<id,ZIKViewRouteConfiguration<ModuleProtocol> *> toModule](@protocol(ModuleProtocol))

///Get view router in a type safe way. There will be complie error if the view protocol is not ZIKViewRoutable.
#define ZIKViewRouterToView(ViewProtocol) (ZIKDestinationViewRouterType<id<ViewProtocol>,ZIKViewRouteConfiguration *> *)[ZIKViewRouter<id<ViewProtocol>,ZIKViewRouteConfiguration *> toView](@protocol(ViewProtocol))

///Get view router in a type safe way. There will be complie error if the module protocol is not ZIKViewModuleRoutable.
#define ZIKViewRouterToModule(ModuleProtocol) (ZIKModuleViewRouterType<id<ZIKRoutableView>,id<ModuleProtocol>,ZIKViewRouteConfiguration<ModuleProtocol> *> *)[ZIKViewRouter<id,ZIKViewRouteConfiguration<ModuleProtocol> *> toModule](@protocol(ModuleProtocol))

@interface ZIKViewRouter<__covariant Destination: id, __covariant RouteConfig: ZIKViewRouteConfiguration *> (Discover)

/**
 Get the view router class registered with a view protocol. Always use macro `ZIKViewRouterToView`, don't use this method directly.
 
 The parameter viewProtocol of the block is the protocol conformed by the view. Should be a ZIKViewRoutable protocol when ZIKROUTER_CHECK is enabled.
 
 The return Class of the block is a router class matched with the view. Return nil if protocol is nil or not registered. There will be an assert failure when result is nil.
 @discussion
 This function is for decoupling route behavior with router class. If a view conforms to a protocol for configuring it's dependencies, and the protocol is only used by this view, you can use +registerViewProtocol: to register the protocol, then you don't need to import the router's header when performing route.
 @code
 //ZIKLoginViewProtocol
 @protocol ZIKLoginViewProtocol <ZIKViewRoutable>
 @property (nonatomic, copy) NSString *account;
 @end
 
 //ZIKLoginViewController.h
 @interface ZIKLoginViewController : UIViewController <ZIKLoginViewProtocol>
 @property (nonatomic, copy) NSString *account;
 @end
 
 //in ZIKLoginViewRouter.m
 //Mark ZIKLoginViewController routable
 @interface ZIKLoginViewController (ZIKLoginViewRouter) <ZIKRoutableView>
 @end
 @implementation ZIKLoginViewController (ZIKLoginViewRouter)
 @end
 
 @implementation ZIKLoginViewRouter
 + (void)registerRoutableDestination {
     [self registerView:[ZIKLoginViewController class]];
     [self registerViewProtocol:ZIKRoutableProtocol(ZIKLoginViewProtocol)];
 }
 @end
 
 //Get ZIKLoginViewRouter and perform route
 [ZIKRouterToView(ZIKLoginViewProtocol)
     performFromSource:self
     configuring:^(ZIKViewRouteConfiguration *config) {
         config.prepareDestination = ^(id<ZIKLoginViewProtocol> destination) {
         destination.account = @"my account";
     };
 }];
 @endcode
 See +registerViewProtocol: and ZIKViewRoutable for more info.
 */
@property (nonatomic, class, readonly) ZIKDestinationViewRouterType<id<ZIKViewRoutable>, ZIKViewRouteConfiguration *> * _Nullable (^toView)(Protocol *viewProtocol) NS_SWIFT_UNAVAILABLE("Use `Router.to(RoutableView<ViewProtocol>())` in ZRouter instead");

/**
 Get the view router class combined with a custom ZIKViewRouteConfiguration conforming to a module config protocol. Always use macro `ZIKViewRouterToModule`, don't use this method directly.
 
 The parameter configProtocol of the block is: The protocol conformed by defaultConfiguration of router. Should be a ZIKViewModuleRoutable protocol when ZIKROUTER_CHECK is enabled.
 
 The return Class of the block is a router class matched with the view. Return nil if protocol is nil or not registered. There will be an assert failure when result is nil.
 @discussion
 Similar to ZIKViewRouter.toView(), this function is for decoupling route behavior with router class. If configurations of a module can't be set directly with a protocol the view conforms, you can use a custom ZIKViewRouteConfiguration to config these configurations. Use +registerModuleProtocol: to register the protocol, then you don't need to import the router's header when performing route.
 @code
 //ZIKLoginViewProtocol
 @protocol ZIKLoginViewConfigProtocol <ZIKViewModuleRoutable>
 @property (nonatomic, copy) NSString *account;
 @end
 
 //ZIKLoginViewController.h
 @interface ZIKLoginViewController : UIViewController
 @property (nonatomic, copy) NSString *account;
 @end
 
 @interface ZIKLoginViewConfiguration : ZIKViewRouteConfiguration <NSCopying, ZIKLoginViewConfigProtocol>
 @property (nonatomic, copy) NSString *account;
 @end
 
 //in ZIKLoginViewRouter.m
 //Mark ZIKLoginViewController routable
 @interface ZIKLoginViewController (ZIKLoginViewRouter) <ZIKRoutableView>
 @end
 @implementation ZIKLoginViewController (ZIKLoginViewRouter)
 @end
 
 @interface ZIKLoginViewRouter : ZIKViewRouter<ZIKViewRouteConfiguration<ZIKLoginViewConfigProtocol> *, ZIKViewRemoveConfiguration *>
 @end
 @implementation ZIKLoginViewRouter
 + (void)registerRoutableDestination {
     [self registerView:[ZIKLoginViewController class]];
     [self registerModuleProtocol:ZIKRoutableProtocol(ZIKLoginViewConfigProtocol)];
 }
 - (id)destinationWithConfiguration:(ZIKLoginViewConfiguration *)configuration {
     ZIKLoginViewController *destination = [ZIKLoginViewController new];
     return destination;
 }
 - (void)prepareDestination:(ZIKLoginViewController *)destination configuration:(ZIKLoginViewConfiguration *)configuration {
     destination.account = configuration.account;
 }
 @end
 
 //Get ZIKLoginViewRouter and perform route
 [ZIKRouterToViewModule(ZIKLoginViewConfigProtocol)
     performFromSource:self
     configuring:^(ZIKViewRouteConfiguration<ZIKLoginViewConfigProtocol> *config) {
         config.account = @"my account";
     }];
 @endcode
 See +registerModuleProtocol: and ZIKViewModuleRoutable for more info.
 */
@property (nonatomic, class, readonly) ZIKModuleViewRouterType<id<ZIKRoutableView>, id<ZIKViewModuleRoutable>, RouteConfig> * _Nullable (^toModule)(Protocol *configProtocol) NS_SWIFT_UNAVAILABLE("Use `Router.to(RoutableViewModule<ModuleProtocol>())` in ZRouter instead");

@end

#pragma mark Router Type

@interface ZIKDestinationViewRouterType<__covariant Destination: id<ZIKViewRoutable>, __covariant RouteConfig: ZIKViewRouteConfiguration *> (Extension)

/**
 Perform route from source view to destination view, and prepare destination in a type safe way inferred by generic parameters.
 @discussion
 `prepareDest` and `prepareModule`'s type changes with the router's generic parameters.
 
 @param source Source UIViewController or UIView. See ZIKViewRouteConfiguration's source.
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @return The view router for this route.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performFromSource:(nullable id<ZIKViewRouteSource>)source
                                                      strictConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                                             void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                             void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                                             ))configBuilder;

/**
 Perform route from source view to destination view, and prepare destination in a type safe way inferred by generic parameters.
 @discussion
 `prepareDest` and `prepareModule`'s type changes with the router's generic parameters.
 
 @param source Source UIViewController or UIView. See ZIKViewRouteConfiguration's source.
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @param removeConfigBuilder Type safe builder to build remove configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it).
 @return The view router for this route.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performFromSource:(nullable id<ZIKViewRouteSource>)source
                                                      strictConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                                             void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                             void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                                             ))configBuilder
                                                         strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config,
                                                                                                       void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                                       ))removeConfigBuilder;

/**
 Perform route on destination and prepare destination in a type safe way inferred by generic parameters. If you get a prepared destination by ZIKViewRouteTypeGetDestination, you can use this method to perform route on the destination.
 
 @param destination The destination to perform route.
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination
                                                                fromSource:(nullable id<ZIKViewRouteSource>)source
                                                         strictConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                                                void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                                void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                                                ))configBuilder;

/**
 Perform route on destination and prepare destination in a type safe way inferred by generic parameters. If you get a prepared destination by ZIKViewRouteTypeGetDestination, you can use this method to perform route on the destination.
 
 @param destination The destination to perform route.
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @param removeConfigBuilder Type safe builder to build remove configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it).
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination
                                                                fromSource:(nullable id<ZIKViewRouteSource>)source
                                                         strictConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                                                void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                                void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                                                ))configBuilder
                                                            strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config,
                                                                                                          void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                                          ))removeConfigBuilder;

/**
 Prepare destination from external in a type safe way inferred by generic parameters, then you can use the router to perform route. You can also use this as a builder to prepare view created from external.
 
 @param destination The destination to prepare. Destination must be registered with this router class.
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)prepareDestination:(Destination)destination
                                                       strictConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                                              void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                              void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                                              ))configBuilder;

/**
 Prepare destination from external in a type safe way inferred by generic parameters, then you can use the router to perform route. You can also use this as a builder to prepare view created from external.
 
 @param destination The destination to prepare. Destination must be registered with this router class.
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @param removeConfigBuilder Type safe builder to build remove configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it).
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)prepareDestination:(Destination)destination
                                                       strictConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                                              void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                              void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                                              ))configBuilder
                                                          strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config,
                                                                                                        void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                                        ))removeConfigBuilder;

@end

@interface ZIKModuleViewRouterType<__covariant Destination: id<ZIKRoutableView>, __covariant ModuleConfig: id<ZIKViewModuleRoutable>, __covariant RouteConfig: ZIKViewRouteConfiguration *> (Extension)

/**
 Perform route from source view to destination view, and prepare destination in a type safe way inferred by generic parameters.
 @discussion
 `prepareDest` and `prepareModule`'s type changes with the router's generic parameters.
 
 @param source Source UIViewController or UIView. See ZIKViewRouteConfiguration's source.
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @return The view router for this route.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performFromSource:(nullable id<ZIKViewRouteSource>)source
                                                      strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                                             void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                             void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ModuleConfig module))
                                                                                             ))configBuilder;

/**
 Perform route from source view to destination view, and prepare destination in a type safe way inferred by generic parameters.
 @discussion
 `prepareDest` and `prepareModule`'s type changes with the router's generic parameters.
 
 @param source Source UIViewController or UIView. See ZIKViewRouteConfiguration's source.
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @param removeConfigBuilder Type safe builder to build remove configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it).
 @return The view router for this route.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performFromSource:(nullable id<ZIKViewRouteSource>)source
                                                      strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                                             void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                             void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ModuleConfig module))
                                                                                             ))configBuilder
                                                         strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config,
                                                                                                       void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                                       ))removeConfigBuilder;

/**
 Perform route on destination and prepare destination in a type safe way inferred by generic parameters. If you get a prepared destination by ZIKViewRouteTypeGetDestination, you can use this method to perform route on the destination.
 
 @param destination The destination to perform route.
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination
                                                                fromSource:(nullable id<ZIKViewRouteSource>)source
                                                        strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                                                void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                                void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ModuleConfig module))
                                                                                                ))configBuilder;

/**
 Perform route on destination and prepare destination in a type safe way inferred by generic parameters. If you get a prepared destination by ZIKViewRouteTypeGetDestination, you can use this method to perform route on the destination.
 
 @param destination The destination to perform route.
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @param removeConfigBuilder Type safe builder to build remove configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it).
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination
                                                                fromSource:(nullable id<ZIKViewRouteSource>)source
                                                         strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                                                void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                                void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ModuleConfig module))
                                                                                                ))configBuilder
                                                            strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config,
                                                                                                          void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                                          ))removeConfigBuilder;

/**
 Prepare destination from external in a type safe way inferred by generic parameters, then you can use the router to perform route. You can also use this as a builder to prepare view created from external.
 
 @param destination The destination to prepare. Destination must be registered with this router class.
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)prepareDestination:(Destination)destination
                                                       strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                                              void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                              void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ModuleConfig module))
                                                                                              ))configBuilder;

/**
 Prepare destination from external in a type safe way inferred by generic parameters, then you can use the router to perform route. You can also use this as a builder to prepare view created from external.
 
 @param destination The destination to prepare. Destination must be registered with this router class.
 @param configBuilder Type safe builder to build configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it), `prepareModule` is for setting custom route config.
 @param removeConfigBuilder Type safe builder to build remove configuration, `prepareDest` is for setting `prepareDestination` block for configuration (it's an escaping block so use weakSelf in it).
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
- (nullable ZIKViewRouter<Destination, RouteConfig> *)prepareDestination:(Destination)destination
                                                       strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                                              void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                              void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ModuleConfig module))
                                                                                              ))configBuilder
                                                          strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config,
                                                                                                        void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                                        ))removeConfigBuilder;

@end

@interface ZIKViewRouterType<__covariant Destination: id, __covariant RouteConfig: ZIKViewRouteConfiguration *> (Deprecated)
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performFromSource:(nullable id<ZIKViewRouteSource>)source
                                                       routeConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                                             void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                             void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                                             ))configBuilder API_DEPRECATED_WITH_REPLACEMENT("-performFromSource:strictConfiguring:", ios(7.0, 7.0));
@end

@interface ZIKDestinationViewRouterType<__covariant Destination: id<ZIKViewRoutable>, __covariant RouteConfig: ZIKViewRouteConfiguration *> (Deprecated)
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performFromSource:(nullable id<ZIKViewRouteSource>)source
                                                       routeConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                                             void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                             void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                                             ))configBuilder
                                                          routeRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config,
                                                                                                       void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                                       ))removeConfigBuilder API_DEPRECATED_WITH_REPLACEMENT("-performFromSource:strictConfiguring:strictRemoving:", ios(7.0, 7.0));
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination
                                                                fromSource:(nullable id<ZIKViewRouteSource>)source
                                                          routeConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                                                void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                                void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                                                ))configBuilder API_DEPRECATED_WITH_REPLACEMENT("-performOnDestination:fromSource:strictConfiguring:", ios(7.0, 7.0));
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination
                                                                fromSource:(nullable id<ZIKViewRouteSource>)source
                                                          routeConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                                                void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                                void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                                                ))configBuilder
                                                             routeRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config,
                                                                                                          void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                                          ))removeConfigBuilder API_DEPRECATED_WITH_REPLACEMENT("-performOnDestination:fromSource:strictConfiguring:strictRemoving:", ios(7.0, 7.0));
- (nullable ZIKViewRouter<Destination, RouteConfig> *)prepareDestination:(Destination)destination
                                                        routeConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                                              void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                              void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                                              ))configBuilder API_DEPRECATED_WITH_REPLACEMENT("-prepareDestination:strictConfiguring:", ios(7.0, 7.0));
- (nullable ZIKViewRouter<Destination, RouteConfig> *)prepareDestination:(Destination)destination
                                                        routeConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config,
                                                                                              void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                              void(^prepareModule)(void(NS_NOESCAPE ^prepare)(RouteConfig module))
                                                                                              ))configBuilder
                                                           routeRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config,
                                                                                                        void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                                        ))removeConfigBuilder API_DEPRECATED_WITH_REPLACEMENT("-prepareDestination:strictConfiguring:strictRemoving:", ios(7.0, 7.0));
@end

@interface ZIKModuleViewRouterType<__covariant Destination: id<ZIKRoutableView>, __covariant ModuleConfig: id<ZIKViewModuleRoutable>, __covariant RouteConfig: ZIKViewRouteConfiguration *> (Deprecated)
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performFromSource:(nullable id<ZIKViewRouteSource>)source
                                                       routeConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                                             void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                             void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ModuleConfig module))
                                                                                             ))configBuilder API_DEPRECATED_WITH_REPLACEMENT("-performFromSource:strictConfiguring:", ios(7.0, 7.0));
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performFromSource:(nullable id<ZIKViewRouteSource>)source
                                                       routeConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                                             void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                             void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ModuleConfig module))
                                                                                             ))configBuilder
                                                          routeRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config,
                                                                                                       void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                                       ))removeConfigBuilder API_DEPRECATED_WITH_REPLACEMENT("-performFromSource:strictConfiguring:strictRemoving:", ios(7.0, 7.0));
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination
                                                                fromSource:(nullable id<ZIKViewRouteSource>)source
                                                          routeConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                                                void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                                void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ModuleConfig module))
                                                                                                ))configBuilder API_DEPRECATED_WITH_REPLACEMENT("-performOnDestination:fromSource:strictConfiguring:", ios(7.0, 7.0));
- (nullable ZIKViewRouter<Destination, RouteConfig> *)performOnDestination:(Destination)destination
                                                                fromSource:(nullable id<ZIKViewRouteSource>)source
                                                          routeConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                                                void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                                void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ModuleConfig module))
                                                                                                ))configBuilder
                                                             routeRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config,
                                                                                                          void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                                          ))removeConfigBuilder API_DEPRECATED_WITH_REPLACEMENT("-performOnDestination:fromSource:strictConfiguring:strictRemoving:", ios(7.0, 7.0));
- (nullable ZIKViewRouter<Destination, RouteConfig> *)prepareDestination:(Destination)destination
                                                        routeConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                                              void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                              void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ModuleConfig module))
                                                                                              ))configBuilder API_DEPRECATED_WITH_REPLACEMENT("-prepareDestination:strictConfiguring:", ios(7.0, 7.0));
- (nullable ZIKViewRouter<Destination, RouteConfig> *)prepareDestination:(Destination)destination
                                                        routeConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteConfiguration *config,
                                                                                              void(^prepareDest)(void(^prepare)(Destination dest)),
                                                                                              void(^prepareModule)(void(NS_NOESCAPE ^prepare)(ModuleConfig module))
                                                                                              ))configBuilder
                                                           routeRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config,
                                                                                                        void(^prepareDest)(void(^prepare)(Destination dest))
                                                                                                        ))removeConfigBuilder API_DEPRECATED_WITH_REPLACEMENT("-prepareDestination:strictConfiguring:strictRemoving:", ios(7.0, 7.0));
@end

NS_ASSUME_NONNULL_END
