//
//  ZIKViewRouter.h
//  ZIKRouter
//
//  Created by zuik on 2017/3/2.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouter.h"
#import "ZIKViewRouteConfiguration.h"
#import "ZIKViewRoutable.h"
#import "ZIKViewModuleRoutable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Abstract superclass for view router.
 Subclass it and override those methods in `ZIKRouterInternal` and `ZIKViewRouterInternal` to make router of your view.
 */
@interface ZIKViewRouter<__covariant Destination, __covariant RouteConfig: ZIKViewRouteConfiguration *> : ZIKRouter<Destination, RouteConfig, ZIKViewRemoveConfiguration *>

///If this router's view is an UIViewController routed from storyboard, or an UIView added as subview from xib or code, a router will be auto created to prepare the view, and the router's autoCreated is YES; But when an UIViewController is routed from code manually, router won't be auto created because we can't find the performer to prepare the destination.
@property (nonatomic, readonly, assign) BOOL autoCreated;
///Whether current routing action is from router, or from external
@property (nonatomic, readonly, assign) BOOL routingFromInternal;
///Real route type performed for those adaptative types in ZIKViewRouteType
@property (nonatomic, readonly, assign) ZIKViewRouteRealType realRouteType;

@end

@interface ZIKViewRouter<__covariant Destination: id, __covariant RouteConfig: ZIKViewRouteConfiguration *> (Perform)

/**
 Whether the router can perform a view route now
 @discusstion
 Situations when return NO:
 
 1. State is routing, routed or removing
 
 2. Source was dealloced
 
 3. Source can't perform the route type: source is not in any navigation stack for push type, or source has presented a view controller for present type

 @return YES if source can perform route now, otherwise NO
 */
- (BOOL)canPerform;

///Check whether the router support a route type.
+ (BOOL)supportRouteType:(ZIKViewRouteType)type;

#pragma mark Perform

/**
 Perform route from source view to destination view.

 @param path The route path with source and route type.
 @param configBuilder Build the configuration in the block.
 @return The view router for this route.
 */
+ (nullable instancetype)performPath:(ZIKViewRoutePath *)path configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;

/**
 Perform route from source view to destination view, and config the remove route.

 @param path The route path with source and route type.
 @param configBuilder Build the configuration in the block.
 @param removeConfigBuilder Build the remove configuration in the block.
 @return The view router for this route.
 */
+ (nullable instancetype)performPath:(ZIKViewRoutePath *)path
                         configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                            removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder;

///If this destination doesn't need any variable to initialize, just pass source and perform route.
+ (nullable instancetype)performPath:(ZIKViewRoutePath *)path;

///If this destination doesn't need any variable to initialize, just pass source and perform route. The successHandler and errorHandler are for current performing.
+ (nullable instancetype)performPath:(ZIKViewRoutePath *)path
                      successHandler:(void(^ _Nullable)(Destination destination))performerSuccessHandler
                        errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler;

///If this destination doesn't need any variable to initialize, just pass source and perform route. The escaping completion is for current performing.
+ (nullable instancetype)performPath:(ZIKViewRoutePath *)path
                          completion:(void(^)(BOOL success, Destination _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion;

/**
 Perform route from source view to destination view, and prepare destination in a type safe way inferred by generic parameters.
 
 @param path The route path with source and route type.
 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @return The view router for this route.
 */
+ (nullable instancetype)performPath:(ZIKViewRoutePath *)path
                   strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder;

/**
 Perform route from source view to destination view, and prepare destination in a type safe way inferred by generic parameters.
 
 @param path The route path with source and route type.
 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @param removeConfigBuilder Type safe builder to build remove configuration, type of `config`'s properties are inferred by generic parameters.
 @return The view router for this route.
 */
+ (nullable instancetype)performPath:(ZIKViewRoutePath *)path
                   strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder
                      strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveStrictConfiguration<Destination> *config))removeConfigBuilder;
@end

@interface ZIKViewRouter<__covariant Destination: id, __covariant RouteConfig: ZIKViewRouteConfiguration *> (PerformOnDestination)

/**
 Perform route on destination. If you get a prepared destination by ZIKViewRouteTypeMakeDestination, you can use this method to perform route on the destination.
 
 @param destination The destination to perform route, the destination class should be registered with this router class.
 @param path The route path with source and route type.
 @param configBuilder Builder for config when perform route.
 @return A router for the destination. If the destination is not registered with this router class, return nil.
 */
+ (nullable instancetype)performOnDestination:(Destination)destination
                                         path:(ZIKViewRoutePath *)path
                                  configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;

/**
 Perform route on destination. If you get a prepared destination by ZIKViewRouteTypeMakeDestination, you can use this method to perform route on the destination.

 @param destination The destination to perform route, the destination class should be registered with this router class.
 @param path The route path with source and route type.
 @param configBuilder Builder for config when perform route.
 @param removeConfigBuilder Builder for config when remove route.
 @return A router for the destination. If the destination is not registered with this router class, return nil.
 */
+ (nullable instancetype)performOnDestination:(Destination)destination
                                         path:(ZIKViewRoutePath *)path
                                  configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                     removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder;

/**
 Perform route on destination. If you get a prepared destination by ZIKViewRouteTypeMakeDestination, you can use this method to perform route on the destination.

 @param destination The destination to perform route, the destination class should be registered with this router class.
 @param path The route path with source and route type.
 @return A router for the destination. If the destination is not registered with this router class, return nil.
 */
+ (nullable instancetype)performOnDestination:(Destination)destination path:(ZIKViewRoutePath *)path;

/**
 Perform route on destination and prepare destination in a type safe way inferred by generic parameters. If you get a prepared destination by ZIKViewRouteTypeMakeDestination, you can use this method to perform route on the destination.
 
 @param destination The destination to perform route, the destination class should be registered with this router class.
 @param path The route path with source and route type.
 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @return A router for the destination. If the destination is not registered with this router class, return nil.
 */
+ (nullable instancetype)performOnDestination:(Destination)destination
                                         path:(ZIKViewRoutePath *)path
                            strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder;

/**
 Perform route on destination and prepare destination in a type safe way inferred by generic parameters. If you get a prepared destination by ZIKViewRouteTypeMakeDestination, you can use this method to perform route on the destination.
 
 @param destination The destination to perform route, the destination class should be registered with this router class.
 @param path The route path with source and route type.
 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @param removeConfigBuilder Type safe builder to build remove configuration, type of `config`'s properties are inferred by generic parameters.
 @return A router for the destination. If the destination is not registered with this router class, return nil.
 */
+ (nullable instancetype)performOnDestination:(Destination)destination
                                         path:(ZIKViewRoutePath *)path
                            strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder
                               strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveStrictConfiguration<Destination> *config))removeConfigBuilder;
@end

@interface ZIKViewRouter<__covariant Destination: id, __covariant RouteConfig: ZIKViewRouteConfiguration *> (Prepare)

/**
 Prepare destination from external, then you can use the router to perform route. You can also use this as a builder to prepare view created from external.
 
 @param destination The destination to prepare. Destination must be registered with this router class.
 @param configBuilder Builder for config when perform route.
 @return A router for the destination. If the destination is not registered with this router class, return nil.
 */
+ (nullable instancetype)prepareDestination:(Destination)destination
                                configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;

/**
 Prepare destination from external, then you can use the router to perform route. You can also use this as a builder to prepare view created from external.

 @param destination The destination to prepare. Destination must be registered with this router class.
 @param configBuilder Builder for config when perform route.
 @param removeConfigBuilder Builder for config when remove route.
 @return A router for the destination. If the destination is not registered with this router class, return nil.
 */
+ (nullable instancetype)prepareDestination:(Destination)destination
                                configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                   removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder;

/**
 Prepare destination from external in a type safe way inferred by generic parameters, then you can use the router to perform route. You can also use this as a builder to prepare view created from external.
 
 @param destination The destination to prepare. Destination must be registered with this router class.
 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @return A router for the destination. If the destination is not registered with this router class, return nil.
 */
+ (nullable instancetype)prepareDestination:(Destination)destination
                          strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder;

/**
 Prepare destination from external in a type safe way inferred by generic parameters, then you can use the router to perform route. You can also use this as a builder to prepare view created from external.
 
 @param destination The destination to prepare. Destination must be registered with this router class.
 @param configBuilder Type safe builder to build configuration, type of `config`'s properties are inferred by generic parameters.
 @param removeConfigBuilder Type safe builder to build remove configuration, type of `config`'s properties are inferred by generic parameters.
 @return A router for the destination. If the destination is not registered with this router class, return nil.
 */
+ (nullable instancetype)prepareDestination:(Destination)destination
                          strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder
                             strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveStrictConfiguration<Destination> *config))removeConfigBuilder;
@end

@interface ZIKViewRouter (Remove)

/**
 Whether can remove a performed view route. Always use it in main thread, bacause state may be changed in main thread after you check the state in child thread.
 @discussion
 Situations when return NO:
 
 1. Router is not performed yet.
 
 2. Destination was already poped/dismissed/removed/dealloced.
 
 3. Use ZIKViewRouteTypeCustom and the router didn't provide removeRoute, or -canRemoveCustomRoute return NO.
 
 4. If route type is adaptative type, it will choose different presentation for different situation (ZIKViewRouteTypePerformSegue, ZIKViewRouteTypeShow, ZIKViewRouteTypeShowDetail). Then if its real route type is not Push/PresentModally/PresentAsPopover/AddAsChildViewController/PresentAsSheet/PresentWithAnimator/ShowWindow, destination can't be removed.
 
 5. Router was auto created when a destination is displayed and not from storyboard, so router don't know destination's state before route, and can't analyze its real route type to do corresponding remove action.
 
 6. Destination's route type is complicated and is considered as custom route type. Such as destination is added to an UITabBarController, then pushed into an UINavigationController, and finally presented modally. We don't know the remove action should do dismiss or pop or remove from its UITabBarController.
 
 @note Router should be removed by the performer, but not inside the destination. Only the performer knows how the destination was displayed (situation 6).

 @return return YES if can do removeRoute.
 */
- (BOOL)canRemove;

///Remove a routed destination. Auto choose proper remove action in pop/dismiss/removeFromParentViewController/removeFromSuperview/custom. If -canRemove return NO, this will fail, use -removeRouteWithSuccessHandler:errorHandler: to get error info. Main thread only.
- (void)removeRoute;

@end

/**
 Error handler for all view router, for debugging and log.
 
 @param router The router where error happens.
 @param routeAction The action where error happens.
 @param error Error in ZIKViewRouteErrorDomain or domain from subclass router, see ZIKViewRouteError for detail.
 */
typedef void(^ZIKViewRouteGlobalErrorHandler)(__kindof ZIKViewRouter * _Nullable router, ZIKRouteAction routeAction, NSError *error);


@interface ZIKViewRouter (ErrorHandle)

//Set error handler for all router instance. Use this to debug and log.
@property (class, copy, nullable) void(^globalErrorHandler)(__kindof ZIKViewRouter *_Nullable router, ZIKRouteAction action, NSError *error);

@end

@interface ZIKViewRouter (Register)
/**
 Register an UIViewController or UIView class with this router class, then we can find the view's router class when we need to auto create router for a view.
 @note
 One view may be registered with multi routers, when view is routed from storyboard or -addSubview:, a router will be auto created from one of the registered router classes randomly. If you want to use a certain router, see +registerExclusiveView:.
 One router may manage multi views. You can register multi view classes to a same router class.
 
 @param viewClass The view class registered with this router class.
 */
+ (void)registerView:(Class)viewClass;

/**
 Register an UIViewController or UIView class with this router class, then no other router class can be registered for this view class.
 @discussion
 If the view will hold and use its router, or you inject dependencies in the router, that means the view is coupled with the router. Then use this method to register. If another router class try to register with the view class, there will be an assert failure.
 
 @param viewClass The view class uniquely registered with this router class.
 */
+ (void)registerExclusiveView:(Class)viewClass;

/**
 Register a view protocol that all views registered with the router conforming to, then use ZIKRouterToView() to get the router class. In Swift, use `register(RoutableView<ViewProtocol>())` in ZRouter instead.
 
 @param viewProtocol The protocol conformed by the view. Should inherit from ZIKViewRoutable. Use macro `ZIKRoutable` to wrap the parameter.
 */
+ (void)registerViewProtocol:(Protocol<ZIKViewRoutable> *)viewProtocol;

/**
 Register a module config protocol conformed by the router's default route configuration, then use ZIKRouterToModule() to get the router class. In Swift, use `register(RoutableViewModule<ModuleProtocol>())` in ZRouter instead.
 
 @param configProtocol The protocol conformed by default route configuration of this router class. Should inherit from ZIKViewModuleRoutable. Use macro `ZIKRoutable` to wrap the parameter.
 */
+ (void)registerModuleProtocol:(Protocol<ZIKViewModuleRoutable> *)configProtocol;

///Register a unique identifier for this router class.
+ (void)registerIdentifier:(NSString *)identifier;

///Is registration all finished. Can't register any router after registration is finished.
+ (BOOL)isRegistrationFinished;
@end

///If an UIViewController or UIView conforms to ZIKRoutableView, there must be a router for it and its subclass, then we can auto create its router. Don't use it in other place.
@protocol ZIKRoutableView <NSObject>

@end

///Convenient macro to let UIViewController or UIView conform to ZIKRoutableView, and declare that it's routable.
#define DeclareRoutableView(RoutableView, ExtensionName)    \
@interface RoutableView (ExtensionName) <ZIKRoutableView>    \
@end    \
@implementation RoutableView (ExtensionName) \
@end    \

#pragma mark Alias

typedef ZIKViewRouteConfiguration ZIKViewRouteConfig;
typedef ZIKViewRemoveConfiguration ZIKViewRemoveConfig;
typedef ZIKViewRouteSegueConfiguration ZIKViewRouteSegueConfig;
typedef ZIKViewRoutePopoverConfiguration ZIKViewRoutePopoverConfig;

typedef ZIKViewRouter<id, ZIKViewRouteConfig *> ZIKAnyViewRouter;
#define ZIKDestinationViewRouter(Destination) ZIKViewRouter<Destination, ZIKViewRouteConfig *>
#define ZIKModuleViewRouter(ModuleConfigProtocol) ZIKViewRouter<id, ZIKViewRouteConfig<ModuleConfigProtocol> *>

@interface ZIKViewRouter<__covariant Destination: id, __covariant RouteConfig: ZIKViewRouteConfiguration *> (Unavailable)

+ (nullable instancetype)performRoute NS_UNAVAILABLE;
+ (nullable instancetype)performWithSuccessHandler:(void(^ _Nullable)(Destination destination))performerSuccessHandler
                                      errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler NS_UNAVAILABLE;
+ (nullable instancetype)performWithCompletion:(void(^)(BOOL success, Destination _Nullable destination, ZIKRouteAction routeAction, NSError *_Nullable error))performerCompletion NS_UNAVAILABLE;
+ (nullable instancetype)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                       removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
+ (nullable instancetype)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder NS_UNAVAILABLE;
+ (nullable instancetype)performWithStrictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder NS_UNAVAILABLE;
+ (nullable instancetype)performWithStrictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder
                                       strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveStrictConfiguration<Destination> *config))removeConfigBuilder NS_UNAVAILABLE;

@end

@interface ZIKViewRouter<__covariant Destination: id, __covariant RouteConfig: ZIKViewRouteConfiguration *> (Deprecated)
+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder API_DEPRECATED_WITH_REPLACEMENT("performPath:configuring:", ios(7.0, 7.0));
+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source
                               configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                  removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder API_DEPRECATED_WITH_REPLACEMENT("performPath:configuring:removing:", ios(7.0, 7.0));
+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source routeType:(ZIKViewRouteType)routeType API_DEPRECATED_WITH_REPLACEMENT("performPath:", ios(7.0, 7.0));
+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source
                                 routeType:(ZIKViewRouteType)routeType
                            successHandler:(void(^ _Nullable)(Destination destination))performerSuccessHandler
                              errorHandler:(void(^ _Nullable)(ZIKRouteAction routeAction, NSError *error))performerErrorHandler API_DEPRECATED_WITH_REPLACEMENT("performPath:successHandler:errorHandler:" ,ios(7.0, 7.0));
+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source
                         strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder API_DEPRECATED_WITH_REPLACEMENT("performPath:strictConfiguring:", ios(7.0, 7.0));
+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source
                         strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder
                            strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveStrictConfiguration<Destination> *config))removeConfigBuilder API_DEPRECATED_WITH_REPLACEMENT("performPath:strictConfiguring:strictRemoving:", ios(7.0, 8.0));
+ (nullable instancetype)performOnDestination:(Destination)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                                  configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder API_DEPRECATED_WITH_REPLACEMENT("performOnDestination:path:configuring:", ios(7.0, 7.0));
+ (nullable instancetype)performOnDestination:(Destination)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                                  configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                     removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder API_DEPRECATED_WITH_REPLACEMENT("performOnDestination:path:configuring:removing:", ios(7.0, 7.0));
+ (nullable instancetype)performOnDestination:(Destination)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                                    routeType:(ZIKViewRouteType)routeType API_DEPRECATED_WITH_REPLACEMENT("performOnDestination:path:", ios(7.0, 7.0));
+ (nullable instancetype)performOnDestination:(Destination)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                            strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder API_DEPRECATED_WITH_REPLACEMENT("performOnDestination:path:strictConfiguring:", ios(7.0, 7.0));
+ (nullable instancetype)performOnDestination:(Destination)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                            strictConfiguring:(void(NS_NOESCAPE ^)(ZIKViewRouteStrictConfiguration<Destination> *config, RouteConfig module))configBuilder
                               strictRemoving:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveStrictConfiguration<Destination> *config))removeConfigBuilder API_DEPRECATED_WITH_REPLACEMENT("performOnDestination:path:strictConfiguring:strictRemoving:", ios(7.0, 7.0));

@end
NS_ASSUME_NONNULL_END
