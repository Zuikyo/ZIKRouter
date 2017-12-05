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
 Subclass it and override those methods in `ZIKRouterInternal` and `ZIKViewRouterInternal` to make router of your view. Then use generic with protocol or those dynamic discovering functions to reduce couple with subclasses.
 
 @discussion
 Features:
 
 1. Find destination with registered protocol, decoupling the source with the destination class.
 
 2. Support all route types in UIKit, and can remove the destination without using -popViewControllerAnimated:/-dismissViewControllerAnimated:completion:/removeFromParentViewController/removeFromSuperview in different sistuation. Router can choose the proper method. You can alse add custom route type.
 
 3. Support storyboard. UIViewController and UIView from a segue can auto create it's registered router.
 
 4. Enough error checking for route action.
 
 5. AOP support for destination's route action.
 
 Method swizzle declaration:
 
 What did ZIKViewRouter hooked: -willMoveToParentViewController:, -didMoveToParentViewController:, -viewWillAppear:, -viewDidAppear:, -viewWillDisappear:, -viewDidDisappear:, -viewDidLoad, -willMoveToSuperview:, -didMoveToSuperview, -willMoveToWindow:, -didMoveToWindow, all UIViewControllers' -prepareForSegue:sender:, all UIStoryboardSegues' -perform.
 
 ZIKViewRouter hooks these methods for AOP. In -willMoveToSuperview, -willMoveToWindow:, -prepareForSegue:sender:, it detects if the view is registered with a router, and auto create a router if it's not routed from it's router.
 
 About auto create:
 
 When a UIViewController conforms to ZIKRoutableView, and is routing from storyboard segue or from -instantiateInitialViewController, a router will be auto created to prepare the UIViewController. If the destination needs preparing, the segue's performer is responsible for preparing in delegate method -prepareDestinationFromExternal:configuration:. But if a UIViewController is routed from code manually, ZIKViewRouter won't auto create router, only get AOP notify, because we can't find the performer to prepare the destination. So you should avoid route the UIViewController instance from code manually, if you use a router as a dependency injector for preparing the UIViewController. You can check whether the destination is prepared properly in those AOP delegate methods.
 
 When Adding a registered UIView by code or xib, a router will be auto created. We search the view controller with custom class (not system class like native UINavigationController, or any container view controller) in it's responder hierarchy as the performer. If the registered UIView needs preparing, you have to add the view to a superview in a view controller before it removed from superview. There will be an assert failure if there is no view controller to prepare it (such as: 1. add it to a superview, and the superview is never added to a view controller; 2. add it to a UIWindow). If your custom class view use a routable view as it's subview, the custom view should use a router to add and prepare the routable view, then the routable view don't need to search performer because it's already prepared.
 */
@interface ZIKViewRouter<__covariant Destination: id, __covariant RouteConfig: ZIKViewRouteConfiguration *> : ZIKRouter<Destination, RouteConfig, ZIKViewRemoveConfiguration *>

///If this router's view is a UIViewController routed from storyboard, or a UIView added as subview from xib or code, a router will be auto created to prepare the view, and the router's autoCreated is YES; But when a UIViewController is routed from code manually, router won't be auto created because we can't find the performer to prepare the destination.
@property (nonatomic, readonly, assign) BOOL autoCreated;
///Whether current routing action is from router, or from external
@property (nonatomic, readonly, assign) BOOL routingFromInternal;
///Real route type performed for those adaptative types in ZIKViewRouteType
@property (nonatomic, readonly, assign) ZIKViewRouteRealType realRouteType;

///Default is ZIKViewRouteTypeMaskUIViewControllerDefault for UIViewController type destination, if your destination is a UIView, override this and return ZIKViewRouteTypeMaskUIViewDefault. Router subclass can also limit the route type.
+ (ZIKViewRouteTypeMask)supportedRouteTypes;

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

///Router doesn't support all routeTypes, for example, router for a UIView destination can't support those UIViewController's routeTypes
+ (BOOL)supportRouteType:(ZIKViewRouteType)type;

+ (nullable instancetype)performRoute NS_UNAVAILABLE;
+ (nullable instancetype)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                       removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
+ (nullable instancetype)performWithConfiguring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder NS_UNAVAILABLE;


/**
 Perform route from source view to destination view.

 @param source Source UIViewController or UIView. See ZIKViewRouteConfiguration's source.
 @param configBuilder Build the configuration in the block.
 @return The view router for this route.
 */
+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;

/**
 Perform route from source view to destination view, and config the remove route.

 @param source Source UIViewController or UIView. See ZIKViewRouteConfiguration's source.
 @param configBuilder Build the configuration in the block.
 @param removeConfigBuilder Build the remove configuration in the block.
 @return The view router for this route.
 */
+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source
                               configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                  removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder;

///If this destination doesn't need any variable to initialize, just pass source and perform route.
+ (nullable instancetype)performFromSource:(nullable id<ZIKViewRouteSource>)source routeType:(ZIKViewRouteType)routeType;
@end

@interface ZIKViewRouter<__covariant Destination: id, __covariant RouteConfig: ZIKViewRouteConfiguration *> (PerformOnDestination)

/**
 Perform route on destination. If you get a prepared destination by ZIKViewRouteTypeGetDestination, you can use this method to perform route on the destination.

 @param destination The destination to perform route
 @param configBuilder Builder for config when perform route
 @param removeConfigBuilder Builder for config when remove route
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
+ (nullable instancetype)performOnDestination:(Destination)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                                  configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                     removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder;
+ (nullable instancetype)performOnDestination:(Destination)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                                  configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;
+ (nullable instancetype)performOnDestination:(Destination)destination
                                   fromSource:(nullable id<ZIKViewRouteSource>)source
                                    routeType:(ZIKViewRouteType)routeType;

@end

@interface ZIKViewRouter<__covariant Destination: id, __covariant RouteConfig: ZIKViewRouteConfiguration *> (Prepare)
/**
 Prepare destination from external, then you can use the router to perform route. You can also use this as a builder to prepare view created from external.

 @param destination The destination to prepare. Destination must be registered with this router class.
 @param configBuilder Builder for config when perform route.
 @param removeConfigBuilder Builder for config when remove route.
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
+ (nullable instancetype)prepareDestination:(Destination)destination
                                configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                   removing:(void(NS_NOESCAPE ^ _Nullable)(ZIKViewRemoveConfiguration *config))removeConfigBuilder;

+ (nullable instancetype)prepareDestination:(Destination)destination
                                configuring:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;
@end

@interface ZIKViewRouter (Remove)
/**
 Whether can remove a performed view route. Always use it in main thread, bacause state may be changed in main thread after you check the state in child thread.
 @discussion
 Situations when return NO:
 
 1. Router is not performed yet.
 
 2. Destination was already poped/dismissed/removed/dealloced.
 
 3. Use ZIKViewRouteTypeCustom and the router didn't provide removeRoute, or -canRemoveCustomRoute return NO.
 
 4. If route type is adaptative type, it will choose different presentation for different situation (ZIKViewRouteTypePerformSegue, ZIKViewRouteTypeShow, ZIKViewRouteTypeShowDetail). Then if it's real route type is not Push/PresentModally/PresentAsPopover/AddAsChildViewController, destination can't be removed.
 
 5. Router was auto created when a destination is displayed and not from storyboard, so router don't know destination's state before route, and can't analyze it's real route type to do corresponding remove action.
 
 6. Destination's route type is complicated and is considered as custom route type. Such as destination is added to a UITabBarController, then added to a UINavigationController, and finally presented modally. We don't know the remove action should do dismiss or pop or remove from it's UITabBarController.
 
 @note Router should be removed be the performer, but not inside the destination. Only the performer knows how the destination was displayed (situation 6).

 @return return YES if can do removeRoute.
 */
//- (BOOL)canRemove;

///Remove a routed destination. Auto choose proper remove action in pop/dismiss/removeFromParentViewController/removeFromSuperview/custom. If -canRemove return NO, this will failed, use -removeRouteWithSuccessHandler:errorHandler: to get error info. Main thread only.
//- (void)removeRoute;

@end

/**
 Error handler for all view router, for debugging and log.
 @discussion
 Actions: init, performRoute, removeRoute, toView, toModule, configureSegue, performOnDestination:fromSource:configuring:removing:, prepareDestination:configuring:removing:.
 
 @param router The router where error happens.
 @param routeAction The action where error happens.
 @param error Error in kZIKViewRouteErrorDomain or domain from subclass router, see ZIKViewRouteError for detail.
 */
typedef void(^ZIKViewRouteGlobalErrorHandler)(__kindof ZIKViewRouter * _Nullable router, ZIKRouteAction routeAction, NSError *error);


@interface ZIKViewRouter (ErrorHandle)

///Set error callback for all view router instance. Use this to debug and log
+ (void)setGlobalErrorHandler:(ZIKViewRouteGlobalErrorHandler)globalErrorHandler;

@end

@interface ZIKViewRouter (Register)
/**
 Register a viewClass with it's router's class, so we can create the router of a view and it's subclass when view is not created from router(UIViewController from storyboard or UIView added with -addSubview:, can't detect UIViewController displayed from code because we can't get the performer vc), and require the performer to config the view, and get AOP notified for some route actions.
 @note
 One view may be registered with multi routers, when view is routed from storyboard or -addSubview:, a router will be auto created from one of the registered router classes randomly. If you want to use a certain router, see +registerExclusiveView:.
 One router may manage multi views. You can register multi view classes to a same router class.
 
 @param viewClass The view class managed by router.
 */
+ (void)registerView:(Class)viewClass;

/**
 If the view will hold and use it's router, or you inject dependencies in the router, that means the view is coupled with the router. In this situation, you can use this function to combine viewClass with a unique routerClass, then no other routerClass can be used for this viewClass. If another routerClass try to register with the viewClass, there will be an assert failure.
 
 @param viewClass The view class requiring a unique router class.
 */
+ (void)registerExclusiveView:(Class)viewClass;

/**
 Register a view protocol that all views registered with the router conform to, then use ZIKViewRouter.toView() to get the router class.
 @discussion
 If there're multi router classes for same view, and those routers is designed for preparing different part of the view when perform route (for example, a router is for presenting actionsheet style for UIAlertController, another router is for presenting alert style for UIAlertController), then each router has to register a unique protocol for the view and get the right router class with their protocol, or just import the router class your want to use directly.
 
 You can register your protocol and let the view conforms to the protocol in category in your interface adapter.
 
 @param viewProtocol The protocol conformed by view to identify the routerClass. Should inherit from ZIKViewRoutable when ZIKROUTER_CHECK is enabled. When ZIKROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKViewRoutable.
 */
+ (void)registerViewProtocol:(Protocol *)viewProtocol;

/**
 Register a module config protocol the router's default configuration conforms, then use ZIKViewRouter.toModule() to get the router class.
 
 When the view module contains not only a single UIViewController, but also other internal services, and you can't prepare the module with a simple view protocol, then you need a moudle config protocol.
 @discussion
 If there're multi router classes for same view, and those routers provide different functions and use their subclass of ZIKViewRouteConfiguration (for example, your add a third-party library to your project, the library has a router for quickly presenting a UIAlertController, and in your project, there's a router for integrating UIAlertView and UIAlertController), then each router has to register a unique protocol for their configurations and get the right router class with this protocol, or just import the router class your want to use directly.
 
 You can register your protocol and let the configuration conforms to the protocol in category in your interface adapter.
 
 @param configProtocol The protocol conformed by default configuration of the routerClass. Should inherit from ZIKViewModuleRoutable when ZIKROUTER_CHECK is enabled. When ZIKROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKViewModuleRoutable.
 */
+ (void)registerModuleProtocol:(Protocol *)configProtocol;
@end

@interface ZIKViewRouter (Discover)

/**
 Get the view router class registered with a view protocol.
 
 The parameter viewProtocol of the block is: the protocol conformed by the view. Should be a ZIKViewRoutable protocol when ZIKROUTER_CHECK is enabled. When ZIKROUTER_CHECK is disabled, the protocol doesn't need to inherit from ZIKViewRoutable.
 
 The return Class of the block is: a router class matched with the view. Return nil if protocol is nil or not registered. There will be an assert failure when result is nil.
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
     [self registerViewProtocol:@protocol(ZIKLoginViewProtocol)];
 }
 @end
 
 //Get ZIKLoginViewRouter and perform route
 [ZIKViewRouter.toView(@protocol(ZIKLoginViewProtocol))
     performWithConfiguring:^(ZIKViewRouteConfiguration *config) {
         config.source = self;
         config.prepareDestination = ^(id<ZIKLoginViewProtocol> destination) {
             destination.account = @"my account";
         };
 }];
 @endcode
 See +registerViewProtocol: and ZIKViewRoutable for more info.
 */
@property (nonatomic,class,readonly) Class _Nullable (^toView)(Protocol *viewProtocol) NS_SWIFT_UNAVAILABLE("Use Registry.router(to:) function in ZRouter instead.");

/**
 Get the view router class combined with a custom ZIKViewRouteConfiguration conforming to a module config protocol.
 
 The parameter configProtocol of the block is: The protocol conformed by defaultConfiguration of router. Should be a ZIKViewModuleRoutable protocol when ZIKROUTER_CHECK is enabled. When ZIKROUTER_CHECK is disabled, the protocol doesn't need to inherit from ZIKViewModuleRoutable.
 
 The return Class of the block is: a router class matched with the view. Return nil if protocol is nil or not registered. There will be an assert failure when result is nil.
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
     [self registerModuleProtocol:@protocol(ZIKLoginViewConfigProtocol)];
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
 [ZIKViewRouter.toModule(@protocol(ZIKLoginViewConfigProtocol))
     performWithConfiguring:^(ZIKViewRouteConfiguration<ZIKLoginViewConfigProtocol> *config) {
         config.source = self;
         config.account = @"my account";
 }];
 @endcode
 See +registerModuleProtocol: and ZIKViewModuleRoutable for more info.
 */
@property (nonatomic,class,readonly) Class _Nullable (^toModule)(Protocol *configProtocol) NS_SWIFT_UNAVAILABLE("Use Registry.router(to:) function in ZRouter instead.");

@end

///If a UIViewController or UIView conforms to ZIKRoutableView, there must be a router for it and it's subclass. Don't use it in other place.
@protocol ZIKRoutableView <NSObject>

@end

NS_ASSUME_NONNULL_END
