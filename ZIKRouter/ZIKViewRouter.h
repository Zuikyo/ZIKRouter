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
#import "ZIKViewRouterProtocol.h"
#import "ZIKViewRouteConfiguration.h"
#import "ZIKViewRoutable.h"
#import "ZIKViewConfigRoutable.h"

NS_ASSUME_NONNULL_BEGIN

#ifdef DEBUG
#define ZIKVIEWROUTER_CHECK 1
#else
#define ZIKVIEWROUTER_CHECK 0
#endif

/**
 Error handler for all view router, for debugging and log.
 @discussion
 Actions: init, performRoute, removeRoute, configureSegue

 @param router The router where error happens
 @param routeAction The action where error happens
 @param error Error in kZIKViewRouteErrorDomain or domain from subclass router, see ZIKViewRouteError for detail
 */
typedef void(^ZIKViewRouteGlobalErrorHandler)(__kindof ZIKViewRouter * _Nullable router, SEL routeAction, NSError *error);

/**
 Abstract superclass for view router.
 The view router can perform all navigation types in UIKit through one method. Subclass it and implement ZIKViewRouterProtocol to make router of your view. Then use generic with protocol or those dynamic discovering functions to reduce couple with subclasses.
 @discussion
 Features:
 
 1. Support all route types in UIKit, and can remove the destination without using -popViewControllerAnimated:/-dismissViewControllerAnimated:completion:/removeFromParentViewController/removeFromSuperview in different sistuation. Router can choose the proper method. You can alse add custom route type.
 
 2. Support storyboard. UIViewController and UIView from a segue can auto create it's registered router.
 
 3. Enough error checking for route action.
 
 4. AOP support for destination's route action.
 
 Method swizzle declaration:
 
 What did ZIKViewRouter hooked: -willMoveToParentViewController:, -didMoveToParentViewController:, -viewWillAppear:, -viewDidAppear:, -viewWillDisappear:, -viewDidDisappear:, -viewDidLoad, -willMoveToSuperview:, -didMoveToSuperview, -willMoveToWindow:, -didMoveToWindow, all UIViewControllers' -prepareForSegue:sender:, all UIStoryboardSegues' -perform.
 
 ZIKViewRouter hooks these methods for AOP. -willMoveToSuperview, -willMoveToWindow:, -prepareForSegue:sender: will detect if the view is registered with a router, and auto create a router if it's not routed from it's router.
 
 About auto create:
 
 When a UIViewController conforms to ZIKRoutableView, and is routing from storyboard segue or from -instantiateInitialViewController, a router will be auto created to prepare the UIViewController. If the destination needs preparing, the segue's performer is responsible for preparing in delegate method -prepareDestinationFromExternal:configuration:. But if a UIViewController is routed from code manually, ZIKViewRouter won't auto create router, only get AOP notify, because we can't find the performer to prepare the destination. So you should avoid route the UIViewController instance from code manually, if you use a router as a dependency injector for preparing the UIViewController. You can check whether the destination is prepared properly in those AOP delegate methods.
 
 When Adding a registered UIView by code or xib, a router will be auto created. We search the view controller with custom class (not system class like native UINavigationController, or any container view controller) in it's responder hierarchy as the performer. If the registered UIView needs preparing, you have to add the view to a superview in a view controller before it removed from superview. There will be an assert failure if there is no view controller to prepare it (such as: 1. add it to a superview, and the superview is never added to a view controller; 2. add it to a UIWindow). If your custom class view use a routable view as it's subview, the custom view should use a router to add and prepare the routable view, then the routable view don't need to search performer because it's already prepared.
 */
@interface ZIKViewRouter<__covariant RouteConfig: ZIKViewRouteConfiguration *, __covariant RemoveConfig: ZIKViewRemoveConfiguration *> : ZIKRouter<RouteConfig, RemoveConfig, ZIKViewRouter *> <ZIKViewRouterProtocol>

///If this router's view is a UIViewController routed from storyboard, or a UIView added as subview from xib or code, a router will be auto created to prepare the view, and the router's autoCreated is YES; But when a UIViewController is routed from code manually, router won't be auto created because we can't find the performer to prepare the destination.
@property (nonatomic, readonly, assign) BOOL autoCreated;
///Whether current routing action is from router, or from external
@property (nonatomic, readonly, assign) BOOL routingFromInternal;
///Real route type performed for those adaptative types in ZIKViewRouteType
@property (nonatomic, readonly, assign) ZIKViewRouteRealType realRouteType;

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

+ (nullable ZIKViewRouter<RouteConfig,RemoveConfig> *)performRoute NS_UNAVAILABLE;

///Convenient method to perform route
+ (nullable ZIKViewRouter<RouteConfig,RemoveConfig> *)performWithConfigure:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                                           removeConfigure:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfig config))removeConfigBuilder;
+ (nullable ZIKViewRouter<RouteConfig,RemoveConfig> *)performWithConfigure:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;
///If this destination doesn't need any variable to initialize, just pass source and perform route.
+ (nullable ZIKViewRouter<RouteConfig,RemoveConfig> *)performWithSource:(nullable id<ZIKViewRouteSource>)source routeType:(ZIKViewRouteType)routeType;

///Asynchronous get destination with ZIKViewRouteTypeGetDestination.
+ (nullable id)makeDestinationWithPreparation:(void(^ _Nullable)(id destination))prepare;
///Asynchronous get destination with ZIKViewRouteTypeGetDestination.
+ (nullable id)makeDestination;

/**
 Perform route on destination. If you get a prepared destination by ZIKViewRouteTypeGetDestination, you can use this method to perform route on the destination.

 @param destination The destination to perform route
 @param configBuilder Builder for config when perform route
 @param removeConfigBuilder Builder for config when remove route
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
+ (nullable ZIKViewRouter<RouteConfig,RemoveConfig> *)performOnDestination:(id)destination
                                                                 configure:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
                                                           removeConfigure:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfig config))removeConfigBuilder;
+ (nullable ZIKViewRouter<RouteConfig,RemoveConfig> *)performOnDestination:(id)destination
                                                                 configure:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder;
+ (nullable ZIKViewRouter<RouteConfig,RemoveConfig> *)performOnDestination:(id)destination source:(nullable id<ZIKViewRouteSource>)source routeType:(ZIKViewRouteType)routeType;

/**
 Prepare destination from external, then you can use the router to perform route. You can also use this to prepare view created from external, use it like a builder.

 @param destination The destination to prepare. Destination must be registered with this router class.
 @param configBuilder Builder for config when perform route.
 @param removeConfigBuilder Builder for config when remove route.
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
+ (nullable ZIKViewRouter<RouteConfig,RemoveConfig> *)prepareDestination:(id)destination
                                                               configure:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder
removeConfigure:(void(NS_NOESCAPE ^ _Nullable)(RemoveConfig config))removeConfigBuilder NS_SWIFT_NAME(prepare(destination:configure:removeConfigure:));
+ (nullable ZIKViewRouter<RouteConfig,RemoveConfig> *)prepareDestination:(id)destination
                                                               configure:(void(NS_NOESCAPE ^)(RouteConfig config))configBuilder NS_SWIFT_NAME(prepare(destination:configure:));
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
- (BOOL)canRemove;

///Remove a routed destination. Auto choose proper remove action in pop/dismiss/removeFromParentViewController/removeFromSuperview/custom. If -canRemove return NO, this will failed, use -removeRouteWithSuccessHandler:errorHandler: to get error info. Main thread only.
- (void)removeRoute;

///Router doesn't support all routeTypes, for example, router for a UIView destination can't support those UIViewController's routeTypes
+ (BOOL)supportRouteType:(ZIKViewRouteType)type;

///Set error callback for all view router instance. Use this to debug and log
+ (void)setGlobalErrorHandler:(ZIKViewRouteGlobalErrorHandler)globalErrorHandler;

#pragma mark Router Register

/**
 Register a viewClass with it's router's class, so we can create the router of a view when view is not created from router(UIViewController from storyboard or UIView added with -addSubview:, can't detect UIViewController displayed from code because we can't get the performer vc), and require the performer to config the view, and get AOP notified for some route actions.
 @note
 One view may be registered with multi routers, when view is routed from storyboard or -addSubview:, a router will be auto created from one of the registered router classes randomly. If you want to use a certain router, see +registerExclusiveView:.
 One router may manage multi views. You can register multi view classes to a same router class.
 
 @param viewClass The view class managed by router
 */
+ (void)registerView:(Class)viewClass;

/**
 If the view will hold and use it's router, or you inject dependencies in the router, that means the view is coupled with the router. In this situation, you can use this function to combine viewClass with a specific routerClass, then no other routerClass can be used for this viewClass. If another routerClass try to register with the viewClass, there will be an assert failure.
 
 @param viewClass The view class requiring a specific router class
 */
+ (void)registerExclusiveView:(Class)viewClass;

/**
 Register a view protocol that all views registered with the router conform to, then use ZIKViewRouterForView() to get the router class.
 @discussion
 If there're multi router classes for same view, and those routers is designed for preparing different part of the view when perform route (for example, a router is for presenting actionsheet style for UIAlertController, another router is for presenting alert style for UIAlertController), then each router has to register a unique protocol for the view and get the right router class with their protocol, or just import the router class your want to use directly.
 
 You can register your protocol and let the view conforms to the protocol in category in your interface adapter.
 
 @param viewProtocol The protocol conformed by view to identify the routerClass. Should be a ZIKViewRoutable protocol when ZIKVIEWROUTER_CHECK is enabled. When ZIKVIEWROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKViewRoutable.
 */
+ (void)registerViewProtocol:(Protocol *)viewProtocol;

/**
 Register a config protocol the router's default configuration conforms, then use ZIKViewRouterForConfig() to get the router class.
 @discussion
 If there're multi router classes for same view, and those routers provide different functions and use their subclass of ZIKViewRouteConfiguration (for example, your add a third-party library to your project, the library has a router for quickly presenting a UIAlertController, and in your project, there's a router for integrating UIAlertView and UIAlertController), then each router has to register a unique protocol for their configurations and get the right router class with this protocol, or just import the router class your want to use directly.
 
 You can register your protocol and let the configuration conforms to the protocol in category in your interface adapter.
 
 @param configProtocol The protocol conformed by default configuration of the routerClass. Should be a ZIKViewConfigRoutable protocol when ZIKVIEWROUTER_CHECK is enabled. When ZIKVIEWROUTER_CHECK is disabled, the protocol doesn't need to inheriting from ZIKViewConfigRoutable.
 */
+ (void)registerConfigProtocol:(Protocol *)configProtocol;
@end

#pragma mark Error Handle

extern NSString *const kZIKViewRouteErrorDomain;

///Errors for callback in ZIKRouteErrorHandler and ZIKViewRouteGlobalErrorHandler
typedef NS_ENUM(NSInteger, ZIKViewRouteError) {
    ///Bad implementation in code. When adding a UIView or UIViewController conforms to ZIKRoutableView in xib or storyboard, and it need preparing, you have to implement -prepareDestinationFromExternal:configuration: in the view or view controller which added it. There will be an assert failure for debugging.
    ZIKViewRouteErrorInvalidPerformer,
    ///If you use ZIKViewRouterForView() or ZIKViewRouterForConfig() to fetch router with protocol, the protocol must be declared. There will be an assert failure for debugging.
    ZIKViewRouteErrorInvalidProtocol,
    ///Configuration missed some required values, or some values were conflict. There will be an assert failure for debugging.
    ZIKViewRouteErrorInvalidConfiguration,
    ///This router doesn't support the route type you assigned. There will be an assert failure for debugging.
    ZIKViewRouteErrorUnsupportType,
    /**
     Unbalanced calls to begin/end appearance transitions for destination. This error occurs when you try and display a view controller before the current view controller is finished displaying. This may cause the UIViewController skips or messes up the order calling -viewWillAppear:, -viewDidAppear:, -viewWillDisAppear: and -viewDidDisappear:, and messes up the route state. There will be an assert failure for debugging.
     */
    ZIKViewRouteErrorUnbalancedTransition,
    /**
     1. Source can't perform action with corresponding route type, maybe it's missed or is wrong class, see ZIKViewRouteConfiguration.source. There will be an assert failure for debugging.
     
     2. Source is dealloced when perform route.
     
     3. Source is not in any navigation stack when perform push.
     
     4. Source already presented another view controller when perform present, can't do present now.
     
     5. Attempt to present destination on source whose view is not in the window hierarchy or not added to any superview.
     */
    ZIKViewRouteErrorInvalidSource,
    ///See containerWrapper
    ZIKViewRouteErrorInvalidContainer,
    /**
     Perform or remove route action failed
     @discussion
     1. Do performRoute when the source was dealloced or removed from view hierarchy.
     
     2. Do removeRoute but the destination was poped/dismissed/removed/dealloced.
     
     3. Do removeRoute when a router is not performed yet.
     
     4. Do removeRoute when real routeType is not supported.
     */
    ZIKViewRouteErrorActionFailed,
    ///An unwind segue was aborted because -[destinationViewController canPerformUnwindSegueAction:fromViewController:withSender:] return NO or can't perform segue.
    ZIKViewRouteErrorSegueNotPerformed,
    ///Another same route action is performing.
    ZIKViewRouteErrorOverRoute,
    ///Infinite recursion for performing route detected, see -prepareDestination:configuration: for more detail.
    ZIKViewRouteErrorInfiniteRecursion
};

#pragma mark Dynamic Discover

/**
 Get the router class registered with a view (a ZIKRoutableView) conforming to a unique protocol.
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
 [ZIKViewRouterForView(@protocol(ZIKLoginViewProtocol))
     performWithConfigure:^(ZIKViewRouteConfiguration *config) {
         config.source = self;
         config.prepareForRoute = ^(id<ZIKLoginViewProtocol> destination) {
             destination.account = @"my account";
         };
 }];
 @endcode
 See +registerViewProtocol: and ZIKViewRoutable for more info.
 
 @param viewProtocol The protocol conformed by the view. Should be a ZIKViewRoutable protocol when ZIKVIEWROUTER_CHECK is enabled. When ZIKVIEWROUTER_CHECK is disabled, the protocol doesn't need to inherit from ZIKViewRoutable.
 @return A router class matched with the view. Return nil if protocol is nil or not registered. There will be an assert failure when result is nil.
 */
extern _Nullable Class ZIKViewRouterForView(Protocol *viewProtocol);

/**
 Get the router class combined with a custom ZIKViewRouteConfiguration conforming to a unique protocol.
 @discussion
 Similar to ZIKViewRouterForView(), this function is for decoupling route behavior with router class. If configurations of a module can't be set directly with a protocol the view conforms, you can use a custom ZIKViewRouteConfiguration to config these configurations. Use +registerConfigProtocol: to register the protocol, then you don't need to import the router's header when performing route.
 @code
 //ZIKLoginViewProtocol
 @protocol ZIKLoginViewConfigProtocol <ZIKViewConfigRoutable>
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
 
 @interface ZIKLoginViewRouter : ZIKViewRouter<ZIKViewRouteConfiguration<ZIKLoginViewConfigProtocol> *, ZIKViewRemoveConfiguration *> <ZIKViewRouterProtocol>
 @end
 @implementation ZIKLoginViewRouter
 + (void)registerRoutableDestination {
    [self registerView:[ZIKLoginViewController class]];
    [self registerConfigProtocol:@protocol(ZIKLoginViewConfigProtocol)];
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
 [ZIKViewRouterForConfig(@protocol(ZIKLoginViewConfigProtocol))
     performWithConfigure:^(ZIKViewRouteConfiguration<ZIKLoginViewConfigProtocol> *config) {
         config.source = self;
         config.account = @"my account";
 }];
 @endcode
 See +registerConfigProtocol: and ZIKViewConfigRoutable for more info.
 
 @param configProtocol The protocol conformed by defaultConfiguration of router. Should be a ZIKViewConfigRoutable protocol when ZIKVIEWROUTER_CHECK is enabled. When ZIKVIEWROUTER_CHECK is disabled, the protocol doesn't need to inherit from ZIKViewConfigRoutable.
 @return A router class matched with the view. Return nil if protocol is nil or not registered. There will be an assert failure when result is nil.
 */
extern _Nullable Class ZIKViewRouterForConfig(Protocol *configProtocol);

API_DEPRECATED_WITH_REPLACEMENT("+[ZIKViewRouter registerView:]",ios(7.0,7.0))
extern void ZIKViewRouter_registerView(Class viewClass, Class routerClass);

API_DEPRECATED_WITH_REPLACEMENT("+[ZIKViewRouter registerExclusiveView:]",ios(7.0,7.0))
extern void ZIKViewRouter_registerViewForExclusiveRouter(Class viewClass, Class routerClass);

API_DEPRECATED_WITH_REPLACEMENT("+[ZIKViewRouter registerViewProtocol:]",ios(7.0,7.0))
extern void ZIKViewRouter_registerViewProtocol(Protocol *viewProtocol, Class routerClass);

API_DEPRECATED_WITH_REPLACEMENT("+[ZIKViewRouter registerConfig:]",ios(7.0,7.0))
extern void ZIKViewRouter_registerConfigProtocol(Protocol *configProtocol, Class routerClass);

///If a UIViewController or UIView conforms to ZIKRoutableView, there must be a router for it and it's subclass. Don't use it in other place.
@protocol ZIKRoutableView <NSObject>

@end

NS_ASSUME_NONNULL_END
