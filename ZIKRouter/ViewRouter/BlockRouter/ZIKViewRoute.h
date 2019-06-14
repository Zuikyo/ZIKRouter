//
//  ZIKViewRoute.h
//  ZIKRouter
//
//  Created by zuik on 2018/4/7.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#if __has_include("ZIKViewRouter.h")

#import "ZIKRoute.h"
#import "ZIKViewRouter.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSInteger, ZIKBlockViewRouteTypeMask) {
    ZIKBlockViewRouteTypeMaskViewControllerDefault = ZIKViewRouteTypeMaskViewControllerDefault,
    ZIKBlockViewRouteTypeMaskViewDefault = ZIKViewRouteTypeMaskViewDefault,
    ZIKBlockViewRouteTypeMaskCustom = ZIKViewRouteTypeMaskCustom
};

/**
 Use ZIKViewRoute to add view route with blocks, rather than creating subclass of ZIKViewRouter.
 
 @code
 [ZIKDestinationViewRoute(id<LoginViewInput>)
    makeRouteWithDestination:[LoginViewController class]
    makeDestination:^id<LoginViewInput> _Nullable(ZIKViewRouteConfig *config, __kindof ZIKRouter *router) {
        LoginViewController *destination = [[LoginViewController alloc] init];
        return destination;
 }]
 .prepareDestination(^(id<LoginViewInput> destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
    // Prepare the destination
 })
 .registerDestinationProtocol(ZIKRoutable(LoginViewInput));
 @endcode
 */
@interface ZIKViewRoute<__covariant Destination, __covariant RouteConfig: ZIKViewRouteConfiguration *> : ZIKRoute<Destination, RouteConfig, ZIKViewRemoveConfiguration *>

//Set name of this route.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^nameAs)(NSString *name);

/// Register view class with this route. See +registerView:.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^registerDestination)(Class destinationClass);

/// Register an UIViewController or UIView class with this route, then no other router can be registered for this view class. See +registerExclusiveView:.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^registerExclusiveDestination)(Class destinationClass);

/// Register a view protocol that all views registered with the router conforming to, then use ZIKRouterToView() to get the router class. In Swift, use `register(RoutableView<ViewProtocol>())` in ZRouter instead. See +registerViewProtocol:.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^registerDestinationProtocol)(Protocol<ZIKViewRoutable> *destinationProtocol);

/// Register a module config protocol conformed by the router's default route configuration, then use ZIKRouterToViewModule() to get the router class. In Swift, use `register(RoutableViewModule<ModuleProtocol>())` in ZRouter instead. See +registerModuleProtocol:.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^registerModuleProtocol)(Protocol<ZIKViewModuleRoutable> *moduleConfigProtocol);

/// Register a identifier with this route.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^registerIdentifier)(NSString *identifier);

/// If the router use a custom configuration, override this and return the configuration. See +defaultRouteConfiguration.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^makeDefaultConfiguration)(RouteConfig(^)(void));

/// If the router use a custom configuration, override this and return the configuration. See +defaultRemoveConfiguration.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^makeDefaultRemoveConfiguration)(ZIKViewRemoveConfiguration *(^)(void));

/// Prepare the destination with the configuration when view first appears. See +prepareDestination:configuration:.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^prepareDestination)(void(^)(Destination destination, RouteConfig config, ZIKViewRouter *router));

/// Called when view first appears and its preparation is finished. You can check whether destination is prepared correctly. See +didFinishPrepareDestination:configuration:.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^didFinishPrepareDestination)(void(^)(Destination destination, RouteConfig config, ZIKViewRouter *router));

/// Whether the router should be auto created for destination from storyboard segue or from external addSubview:. See +shouldAutoCreateForDestination:fromSource:.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^shouldAutoCreateForDestination)(BOOL(^)(Destination destination, _Nullable id source));

/// Whether the destination is all prepared, if not, it requires the performer to prepare it. This method is for destination from storyboard and UIView from -addSubview:. See -destinationFromExternalPrepared:.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^destinationFromExternalPrepared)(BOOL(^)(Destination destination, ZIKViewRouter *router));

/// Supported route types of this router. Default is ZIKViewRouteTypeMaskViewControllerDefault for UIViewController type destination, if your destination is an UIView, override this and return ZIKViewRouteTypeMaskViewDefault. Router can limit the route type.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^makeSupportedRouteTypes)(ZIKBlockViewRouteTypeMask(^)(void));

/// Whether the router can perform custom route now. Default is NO.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^canPerformCustomRoute)(BOOL(^)(ZIKViewRouter *router));

/// Whether the router can remove custom route now. Default is NO. Check the states of destination and source, return NO if they can't be removed.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^canRemoveCustomRoute)(BOOL(^)(ZIKViewRouter *router));

/// Perform your custom route. You must maintain the router's state with methods in ZIKViewRouterInternal.h.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^performCustomRoute)(void(^)(Destination destination, _Nullable id source, RouteConfig config, ZIKViewRouter *router));

/// Remove your custom route. You must maintain the router's state with methods in ZIKViewRouterInternal.h.
@property (nonatomic, readonly) ZIKViewRoute<Destination, RouteConfig> *(^removeCustomRoute)(void(^)(Destination destination, _Nullable id source, ZIKViewRemoveConfiguration *removeConfig, RouteConfig config, ZIKViewRouter *router));

@end

typedef ZIKViewRoute<id, ZIKViewRouteConfiguration *> ZIKAnyViewRoute;
#define ZIKDestinationViewRoute(Destination) ZIKViewRoute<Destination, ZIKViewRouteConfig *>
#define ZIKModuleViewRoute(ModuleConfigProtocol) ZIKViewRoute<id, ZIKViewRouteConfig<ModuleConfigProtocol> *>

NS_ASSUME_NONNULL_END

#endif
