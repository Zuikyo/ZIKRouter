//
//  ZIKViewRouter.h
//  ZIKRouter
//
//  Created by zuik on 2017/3/2.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZIKRouter.h"
#import "ZIKViewRoutable.h"
#import "ZIKViewConfigRoutable.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ZIKRoutableView;
@class ZIKViewRouter,ZIKViewRouteConfiguration,ZIKViewRemoveConfiguration;
///Protocol for ZIKViewRouter's subclass.
@protocol ZIKViewRouterProtocol <NSObject>

///Register the destination class with those ZIKViewRouter_registerXXX functions. ZIKViewRouter will call this method at startup. If a router was not registered with any view class, there'll be an assert failure.
+ (void)registerRoutableDestination;

/**
 Create and initialize your destination with configuration.
 
 @note
 Router with ZIKViewRouteTypePerformSegue route type won't invoke this method, because destination is created from storyboard.
 
 Router created with -performOnDestination:configure:removeConfigure: won't invoke this method.
 
 This methods is only responsible for create the destination. The additional initialization should be in -prepareDestination:configuration:.
 
 @param configuration Configuration for route
 @return A UIViewController or UIView, If the configuration is invalid, return nil to make this route failed.
 */
- (nullable id<ZIKRoutableView>)destinationWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration;

@optional

///Whether the destination is all configed. Destination created from external will use this method to determine whether the router have to search the performer to prepare itself.
+ (BOOL)destinationPrepared:(id)destination;

/**
 Prepare the destination with the configuration when view is first appear. Unwind segue to destination won't call this method.
 @warning
 When it's removed and routed again, it's alse treated as first appear, so this method may be called more than once. You should check whether the destination is already prepared to avoid unnecessary preparation.
 
 If you get a prepared destination by ZIKViewRouteTypeGetDestination or -prepareDestination:configure:removeConfigure:, this method will be called. When the destination is routed, this method will also be called, because the destination may be changed.
 
 @param destination The view to perform route
 @param configuration The config for route
 */
- (void)prepareDestination:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration;

/**
 Called when view is first appear and preparation is finished. You can check whether destination is preapred correctly. Unwind segue to destination won't call this method.
 @warning
 when it's removed and routed again, it's alse treated as first appear, so this method may be called more than once.
 
 @param destination The view to perform route
 @param configuration The config for route
 */
- (void)didFinishPrepareDestination:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration;

///Default is kDefaultRouteTypesForViewController for UIViewController type destination, if your destination is a UIView, override this and return kDefaultRouteTypesForView. Router can also limit the route type.
+ (NSArray<NSNumber *> *)supportedRouteTypes;
///You can do dependency injection by subclass ZIKViewRouteConfiguration, and add your custom property; Then you must override this to return a default instance of your subclass
+ (__kindof ZIKViewRouteConfiguration *)defaultRouteConfiguration;
///You can do dependency injection by subclass ZIKViewRemoveConfiguration, and add your custom property; Then you must override this to return a default instance of your subclass
+ (__kindof ZIKViewRemoveConfiguration *)defaultRemoveConfiguration;

///Custom route support
///Validate the configuration for your custom route.
+ (BOOL)validateCustomRouteConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration removeConfiguration:(__kindof ZIKViewRemoveConfiguration *)removeConfiguration;
///Whether can perform custom route on current source.
- (BOOL)canPerformCustomRoute;
///Whether can remove custom route on current source.
- (BOOL)canRemoveCustomRoute;
///Perform your custom route. You must maintain the router's state with methods in ZIKViewRouter+Private.h.
- (void)performCustomRouteOnDestination:(id)destination fromSource:(id)source configuration:(__kindof ZIKViewRouteConfiguration *)configuration;
///Remove your custom route. You must maintain the router's state with methods in ZIKViewRouter+Private.h.
- (void)removeCustomRouteOnDestination:(id)destination fromSource:(id)source removeConfiguration:(__kindof ZIKViewRemoveConfiguration *)removeConfiguration configuration:(__kindof ZIKViewRouteConfiguration *)configuration;

/**
 AOP support.
 Route with ZIKViewRouteTypeAddAsChildViewController and ZIKViewRouteTypeGetDestination won't get AOP notification, because they are not complete route for displaying the destination, the destination will get AOP notification when it's really displayed.
 
 Router will be nil when route is from external or AddAsChildViewController/GetDestination route type.
 
 Source may be nil when remove route, because source may already be deallced.
 */

/**
 AOP callback when any perform route action will begin. All router classes managing the same view class will be notified.
 @discussion
 Invoked time:
 
 For UIViewController routing from router or storyboard, invoked after destination is preapared and about to do route action.
 For UIViewController not routing from router, or routed by ZIKViewRouteTypeGetDestination or ZIKViewRouteTypeAddAsChildViewController then displayed manually, invoked in -viewWillAppear:. The parameter `router` is nil.
 For UIView routing by ZIKViewRouteTypeAddAsSubview type, invoked after destination is prepared and before -addSubview: is called.
 For UIView routing from xib or from manually addSubview: or routed by ZIKViewRouteTypeGetDestination, invoked after destination is prepared, and is about to be visible (moving to window), but not when -willMoveToSuperview:. Beacuse we need to auto create router and search performer in responder hierarchy, in some situation, the responder is only available when the UIView is on a window. See comments inside -ZIKViewRouter_hook_willMoveToSuperview: for more detial.
 */
+ (void)router:(nullable ZIKViewRouter *)router willPerformRouteOnDestination:(id)destination fromSource:(nullable id)source;

/**
 AOP callback when any perform route action did finish. All router classes managing the same view class will be notified.
 @discussion
 Invoked time:
 
 For UIViewController routing from router or storyboard, invoked after route animation is finished. See -routeCompletion.
 For UIViewController not routing from router, or routed by ZIKViewRouteTypeAddAsChildViewController or ZIKViewRouteTypeGetDestination then displayed manually, invoked in -viewDidAppear:. The parameter `router` is nil.
 For UIView routing by ZIKViewRouteTypeAddAsSubview type, invoked after -addSubview: is called.
 For UIView routing from xib or from manually addSubview: or routed by ZIKViewRouteTypeGetDestination, invoked after destination is visible (did move to window), but not when -didMoveToSuperview:. See comments inside -ZIKViewRouter_hook_willMoveToSuperview: for more detial.
 */
+ (void)router:(nullable ZIKViewRouter *)router didPerformRouteOnDestination:(id)destination fromSource:(nullable id)source;

/**
 AOP callback when any remove route action will begin. All router classes managing the same view class will be notified.
 @discussion
 Invoked time:
 
 For UIViewController or UIView removing from router, invoked before remove route action is called.
 For UIViewController not removing from router, invoked in -viewWillDisappear:. The parameter `router` is nil.
 For UIView not removing from router, invoked in willMoveToSuperview:nil. The parameter `router` is nil.
 */
+ (void)router:(nullable ZIKViewRouter *)router willRemoveRouteOnDestination:(id)destination fromSource:(nullable id)source;

/**
 AOP callback when any remove route action did finish. All router classes managing the same view class will be notified.
 @discussion
 Invoked time:
 
 For UIViewController or UIView removing from router, invoked after remove route action is called.
 For UIViewController not removing from router, invoked in -viewDidDisappear:. The parameter `router` is nil.
 For UIView not removing from router, invoked in didMoveToSuperview:nil. The parameter `router` is nil. The source may be nil, bacause superview may be dealloced
 */
+ (void)router:(nullable ZIKViewRouter *)router didRemoveRouteOnDestination:(id)destination fromSource:(nullable id)source;

@end

///Route type for view
typedef NS_ENUM(NSInteger,ZIKViewRouteType) {
    ///Navigation using @code-[source pushViewController:animated:]@endcode Source must be a UIViewController.
    ZIKViewRouteTypePush,
    ///Navigation using @code-[source presentViewController:animated:completion:]@endcode Source must be a UIViewController.
    ZIKViewRouteTypePresentModally,
    ///Adaptative type. Popover for iPad, present modally for iPhone
    ZIKViewRouteTypePresentAsPopover,
    ///Navigation using @code[source performSegueWithIdentifier:destination sender:sender]@endcode If segue's destination doesn't comform to ZIKRoutableView, just use ZIKViewRouter to perform the segue. If destination contains child view controllers, and childs conform to ZIKRoutableView, prepareForRoute and routeCompletion will be called repeatedly for each routable view.
    ZIKViewRouteTypePerformSegue,
    /**
     Adaptative type. Navigation using @code-[source showViewController:destination sender:sender]@endcode
     In UISplitViewController (source is master/detail or in master/detail's navigation stack): if master/detail is a UINavigationController and destination is not a UINavigationController, push destination on master/detail's stack, else replace master/detail with destination.
     
     In UINavigationController, push destination on stack.
     
     Without a container, present modally.
     */
    ZIKViewRouteTypeShow NS_ENUM_AVAILABLE_IOS(8_0),
    /** 
     Adaptative type. Navigation using @code-[source showDetailViewController:destination sender:sender]@endcode
     In UISplitViewController, replace detail with destination, if collapsed, forward to master view controller, if master is a UINavigationController, push on stack, else replace master with destination.
     
     In UINavigationController, present modally.
     
     Without a container, present modally.
     */
    ZIKViewRouteTypeShowDetail NS_ENUM_AVAILABLE_IOS(8_0),
    ///Get destination viewController and do @code[source addChildViewController:destination]@endcode; You need to get destination in routeCompletion, and add it's view to your view hierarchy; source must be a UIViewController.
    ZIKViewRouteTypeAddAsChildViewController,
    ///Get your custom UIView and do @code[source addSubview:destination]@endcode; source must be a UIView.
    ZIKViewRouteTypeAddAsSubview,
    ///Subclass router can provide custom presentation. Class of source and destination is specified by subclass router.
    ZIKViewRouteTypeCustom,
    ///Just create and return a UIViewController or UIView in routeCompletion; Source is not needed for this type.
    ZIKViewRouteTypeGetDestination
};

///Real route type performed for those adaptative types in ZIKViewRouteType
typedef NS_ENUM(NSInteger, ZIKViewRouteRealType) {
    ///Didn't perform any route yet. Router will reset type to this after removed
    ZIKViewRouteRealTypeUnknown,
    ZIKViewRouteRealTypePush,
    ZIKViewRouteRealTypePresentModally,
    ZIKViewRouteRealTypePresentAsPopover,
    ZIKViewRouteRealTypeAddAsChildViewController,
    ZIKViewRouteRealTypeAddAsSubview,
    ZIKViewRouteRealTypeUnwind,
    ZIKViewRouteRealTypeCustom
};

@class ZIKViewRouter, ZIKViewRouteConfiguration, ZIKViewRemoveConfiguration;
@protocol ZIKViewRouteSource;

/**
 Error handler for all view router, for debug and log.
 @discussion
 Actions: init, performRoute, removeRoute, configureSegue

 @param router The router where error happens
 @param routeAction The action where error happens
 @param error Error in kZIKViewRouteErrorDomain or domain from subclass router, see ZIKViewRouteError for detail
 */
typedef void(^ZIKViewRouteGlobalErrorHandler)(__kindof ZIKViewRouter * _Nullable router, SEL routeAction, NSError *error);

#pragma mark ZIKViewRouter

/**
 The view router can perform all navigation types in UIKit through one method. Subclass it and implement ZIKViewRouterProtocol to make router of your view.
 @discussion
 Features:
 
 1. Prepare the route with protocol in block, instead of directly configuring the destination (the source is coupled with the destination) or in delegate method (in -prepareForSegue:sender: you have to distinguish different destinations, and they're alse coupled with source).
 
 2. Support all route types in UIKit, and can remove the destination without using -popViewControllerAnimated:/-dismissViewControllerAnimated:completion:/removeFromParentViewController/removeFromSuperview in different sistuation. Router can choose the proper method. You can alse add custom route type.
 
 3. Find destination with registered protocol, decoupling the source with and the destination class.
 
 4. Support storyboard. UIViewController and UIView from a segue can auto create it's registered router (but the initial view controller of app is exceptional, it's not from a segue).
 
 5. Enough error checking for route action.
 
 6. AOP support for destination's route action.
 
 Method swizzle declaration:
 
 What did ZIKViewRouter hooked: -willMoveToParentViewController:, -didMoveToParentViewController:, -viewWillAppear:, -viewDidAppear:, -viewWillDisappear:, -viewDidDisappear:, -viewDidLoad, -willMoveToSuperview:, -didMoveToSuperview, -willMoveToWindow:, -didMoveToWindow, all UIViewControllers' -prepareForSegue:sender:, all UIStoryboardSegues' -perform.
 
 ZIKViewRouter hooks these methods for AOP. -willMoveToSuperview, -willMoveToWindow:, -prepareForSegue:sender: will detect if the view is registered with a router, and auto create a router if it's not routed from it's router.
 
 About auto create:
 
 When a UIViewController is registered, and is routing from storyboard segue, a router will be auto created to prepare the UIViewController. If the destination needs preparing, the segue's performer is responsible for preparing in delegate method -prepareForDestinationRoutingFromExternal:configuration:. But if a UIViewController is routed from code manually, ZIKViewRouter won't auto create router, only get AOP notify, because we can't find the performer to prepare the destination. So you should avoid route the UIViewController from code manually, if you use a router as a dependency injector for preparing the UIViewController. You can check whether the destination is prepared in those AOP delegate methods.
 
 When Adding a registered UIView by code or xib, a router will be auto created. We search the view controller with custom class (not system class like native UINavigationController, or any container view controller) in it's responder hierarchy as the performer. If the registered UIView needs preparing, you have to add the view to a superview in a view controller before it removed from superview. There will be an assert failure if there is no view controller to prepare it (such as: 1. add it to a superview, and the superview is never added to a view controller; 2. add it to a UIWindow). If your custom class view use a routable view as it's subview, the custom view should use a router to add and prepare the routable view, then the routable view don't need to search performer because it already prepared.
 */
@interface ZIKViewRouter : ZIKRouter <ZIKViewRouterProtocol>

///If this router's view is a UIViewController routed from storyboard, or a UIView added as subview from xib or code, a router will be auto created to prepare the view, and the router's autoCreated is YES; But when a UIViewController is routed from code manually or is the initial view controller of app in storyboard, router won't be auto created because we can't find the performer to prepare the destination.
@property (nonatomic, readonly, assign) BOOL autoCreated;
///Whether current routing action is from router, or from external
@property (nonatomic, readonly, assign) BOOL routingFromInternal;
///Real route type performed for those adaptative types in ZIKViewRouteType
@property (nonatomic, readonly, assign) ZIKViewRouteRealType realRouteType;

///Covariant property from superclass
- (__kindof ZIKViewRouteConfiguration *)configuration;
///Covariant property from superclass
- (__kindof ZIKViewRemoveConfiguration *)removeConfiguration;

///If configuration is invalid, this will return nil with assert failure
- (nullable instancetype)initWithConfiguration:(__kindof ZIKViewRouteConfiguration *)configuration
                           removeConfiguration:(nullable __kindof ZIKViewRemoveConfiguration *)removeConfiguration NS_DESIGNATED_INITIALIZER;
///Covariant method from superclass
- (nullable instancetype)initWithConfigure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder
                           removeConfigure:(void(NS_NOESCAPE ^ _Nullable)(__kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder;

/**
 Whether can perform a view route now
 @discusstion
 Situations when return NO:
 
 1. State is routing or routed or removing
 
 2. Source was dealloced
 
 3. Source can't perform the route type: source is not in any navigation stack for push type, or source has presented a view controller for present type

 @return YES if source can perform route now, otherwise NO
 */
- (BOOL)canPerform;

+ (nullable __kindof ZIKRouter *)performRoute NS_UNAVAILABLE;

///Convenient method to perform route
+ (nullable __kindof ZIKViewRouter *)performWithConfigure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder
                                          removeConfigure:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder;
+ (nullable __kindof ZIKViewRouter *)performWithConfigure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder;
///If this destination doesn't need any variable to initialize, just pass source and perform route.
+ (__kindof ZIKViewRouter *)performWithSource:(id<ZIKViewRouteSource>)source routeType:(ZIKViewRouteType)routeType;

/**
 Perform route on destination. If you get a prepared destination by ZIKViewRouteTypeGetDestination, you can use this method to perform route on the destination.

 @param destination The destination to perform route
 @param configBuilder Builder for config when perform route
 @param removeConfigBuilder Builder for config when remove route
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
+ (nullable __kindof ZIKViewRouter *)performOnDestination:(id)destination
                                                configure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder
                                          removeConfigure:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder;
+ (nullable __kindof ZIKViewRouter *)performOnDestination:(id)destination
                                                configure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder;
+ (__kindof ZIKViewRouter *)performOnDestination:(id)destination source:(id<ZIKViewRouteSource>)source routeType:(ZIKViewRouteType)routeType;

/**
 Prepare destination from external, then you can use the router to perform route.
 @discussion
 The initial view controller of storyboard for launching app is not from segue, so you have to manually create it's router and use this method to prepare it. You can also use this to prepare other view create from external, use it like a builder.

 @param destination The destination to prepare. Destination must be registered with this router class.
 @param configBuilder Builder for config when perform route
 @param removeConfigBuilder Builder for config when remove route
 @return A router for the destination. If the destination is not registered with this router class, return nil and get assert failure.
 */
+ (nullable __kindof ZIKViewRouter *)prepareDestination:(id)destination
                                              configure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder
                                        removeConfigure:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKViewRemoveConfiguration *config))removeConfigBuilder;
+ (nullable __kindof ZIKViewRouter *)prepareDestination:(id)destination
                                              configure:(void(NS_NOESCAPE ^)(__kindof ZIKViewRouteConfiguration *config))configBuilder;
/**
 Whether can remove a performed view route. Always use it in main thread, bacause state may change in main thread after you check the state in child thread.
 @discussion
 4 situation can't remove:
 
 1. Router is not performed yet.
 
 2. Destination was already poped/dismissed/removed/dealloced.
 
 3. Use ZIKViewRouteTypeCustom and the router didn't provide removeRoute, or -canRemoveCustomRoute return NO.
 
 4. If route type is adaptative type, it will choose different presentation for different situation (ZIKViewRouteTypePerformSegue, ZIKViewRouteTypeShow, ZIKViewRouteTypeShowDetail). Then if it's real route type is not Push/PresentModally/PresentAsPopover/AddAsChildViewController, destination can't be removed.
 
 5. Router was auto created when a destination is displayed and not from storyboard, so router don't know destination's state before route, and can't analyze it's real route type to do corresponding remove action.
 
 6. Destination's route type is complicated and is considered as custom route type. Such as destination is added to a UITabBarController, then added to a UINavigationController, and finally presented modally. We don't know the remove action should do dismiss or pop or remove from it's UITabBarController.
 
 @note Router should be removed be the performer, but not inside the destination. Only the performer knows how the destination was displayed (situation 6).

 @return return YES if can do removeRoute
 */
- (BOOL)canRemove;

///Remove a routed destination. Auto choose proper remove action in pop/dismiss/removeFromParentViewController/removeFromSuperview/custom. If -canRemove return NO, this will failed, use -removeRouteWithSuccessHandler:performerErrorHandler: to get error info. Main thread only.
- (void)removeRoute;

///Router doesn't support all routeTypes, for example, router for a UIView destination can't support those UIViewController's routeTypes
+ (BOOL)supportRouteType:(ZIKViewRouteType)type;

///Set error callback for all view router instance. Use this to debug and log
+ (void)setGlobalErrorHandler:(ZIKViewRouteGlobalErrorHandler)globalErrorHandler;
@end

#pragma mark Error Handle

extern NSString *const kZIKViewRouteErrorDomain;

///Errors for callback in ZIKRouteErrorHandler and ZIKViewRouteGlobalErrorHandler
typedef NS_ENUM(NSInteger, ZIKViewRouteError) {
    
    ///Bad implementation in code. When adding a UIView or UIViewController conforms to ZIKRoutableView in xib or storyboard, and it need preparing, you have to implement -prepareForDestinationRoutingFromExternal:configuration: in the view or view controller which added it. There will be an assert failure for debugging.
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
};

#pragma mark Configuration

@class ZIKViewRoutePopoverConfiguration,ZIKViewRouteSegueConfiguration;
@protocol ZIKViewRouteContainer;
typedef UIViewController<ZIKViewRouteContainer>*_Nonnull(^ZIKViewRouteContainerWrapper)(UIViewController *destination);
typedef void(^ZIKViewRoutePopoverConfigure)(ZIKViewRoutePopoverConfiguration *popoverConfig);
typedef void(^ZIKViewRouteSegueConfigure)(ZIKViewRouteSegueConfiguration *segueConfig);
typedef void(^ZIKViewRoutePopoverConfiger)(NS_NOESCAPE ZIKViewRoutePopoverConfigure);
typedef void(^ZIKViewRouteSegueConfiger)(NS_NOESCAPE ZIKViewRouteSegueConfigure);

///Config of route. You can also use a subclass to add complex dependencies for destination. Your subclass must conforms to NSCopying.
@interface ZIKViewRouteConfiguration : ZIKRouteConfiguration <NSCopying>

/**
 Source ViewController or View for route
 @discussion
 For ZIKViewRouteTypePush, ZIKViewRouteTypePresentModally, ZIKViewRouteTypePresentAsPopover, ZIKViewRouteTypePerformSegue,ZIKViewRouteTypeShow,ZIKViewRouteTypeShowDetail,ZIKViewRouteTypeAddAsChildViewController, source must be a UIViewController.
 
 For ZIKViewRouteTypeAddAsSubview, source must be a UIView.
 
 For ZIKViewRouteTypeGetDestination, source is not needed.
 */
@property (nonatomic, weak) id<ZIKViewRouteSource> source;
///The style of route, default is ZIKViewRouteTypePresentModally. Subclass router may return other default value.
@property (nonatomic, assign) ZIKViewRouteType routeType;
///For push/present, default is YES
@property (nonatomic, assign) BOOL animated;

/**
 Wrap destination in a UINavigationController, UITabBarController or UISplitViewController, and perform route on the container. Only available for ZIKViewRouteTypePush, ZIKViewRouteTypePresentModally, ZIKViewRouteTypePresentAsPopover, ZIKViewRouteTypeShow, ZIKViewRouteTypeShowDetail, ZIKViewRouteTypeAddAsChildViewController.
 @discussion
 a UINavigationController or UISplitViewController can't be pushed into another UINavigationController, so:
 
 For ZIKViewRouteTypePush, container can't be a UINavigationController or UISplitViewController
 
 For ZIKViewRouteTypeShow, if source is in a UINavigationController, container can't be a UINavigationController or UISplitViewController
 
 For ZIKViewRouteTypeShowDetail, if source is in a collapsed UISplitViewController, and master is a UINavigationController, container can't be a UINavigationController or UISplitViewController
 
 For ZIKViewRouteTypeAddAsChildViewController, will add container as source's child, so you have to add container's view to source's view in routeCompletion, not the destination's view
 */
@property (nonatomic, copy, nullable) ZIKViewRouteContainerWrapper containerWrapper;

/**
 Prepare for performRoute, and config other dependency for destination here. Subclass can offer more specific info.
 
 @discussion
 For ZIKViewRouteTypePush, ZIKViewRouteTypePresentModally,  ZIKViewRouteTypePresentAsPopover, ZIKViewRouteTypeShow, ZIKViewRouteTypeShowDetail, ZIKViewRouteTypeAddAsChildViewController, destination is a UIViewController.
 
 For ZIKViewRouteTypeAddAsSubview, destination is a UIView.
 
 For ZIKViewRouteTypePerformSegue and ZIKViewRouteTypeCustom, destination is a UIViewController or UIView.
 
 For ZIKViewRouteTypePerformSegue, if destination contains child view controllers, and childs conform to ZIKRoutableView, prepareForRoute will alse be called for each childs.
 @note
 Use weakSelf in prepareForRoute to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^prepareForRoute)(id destination);

/**
 Completion for performRoute.
 
 @discussion
 For ZIKViewRouteTypePush, ZIKViewRouteTypePresentModally, ZIKViewRouteTypePresentAsPopover, ZIKViewRouteTypeShow, ZIKViewRouteTypeShowDetail, ZIKViewRouteTypeAddAsChildViewController, destination is a UIViewController.
 
 For ZIKViewRouteTypeAddAsSubview, destination is a UIView.
 
 For ZIKViewRouteTypePerformSegue and ZIKViewRouteTypeCustom, destination is a UIViewController or UIView.
 
 For ZIKViewRouteTypePerformSegue, if destination contains child view controllers, and childs conform to ZIKRoutableView, routeCompletion will alse be called for each childs.
 
 @note
 Use weakSelf in routeCompletion to avoid retain cycle.
 
  ZIKViewRouter use UIViewController's transitionCoordinator to do completion, so if you override segue's -perform or override -showViewController:sender: and provide custom transition, but didn't use a transitionCoordinator (such as use +[UIView animateWithDuration:animations:completion:] to animate), routeCompletion when be called immediately, before the animation really completes.
 */
@property (nonatomic, copy, nullable) void(^routeCompletion)(id destination);

///Sender for -showViewController:sender: and -showDetailViewController:sender:
@property (nonatomic, weak, nullable) id sender;

///Config popover for ZIKViewRouteTypePresentAsPopover
@property (nonatomic, readonly, copy) ZIKViewRoutePopoverConfiger configurePopover;

///config segue for ZIKViewRouteTypePerformSegue
@property (nonatomic, readonly, copy) ZIKViewRouteSegueConfiger configureSegue;

@property (nonatomic, readonly, strong, nullable) ZIKViewRoutePopoverConfiguration *popoverConfiguration;
@property (nonatomic, readonly, strong, nullable) ZIKViewRouteSegueConfiguration *segueConfiguration;

///When set to YES and the router still exists, if the same destination instance is routed again from external, prepareForRoute, routeCompletion, providerSuccessHandler, providerErrorHandler will be called
@property (nonatomic, assign) BOOL handleExternalRoute;
@end

@interface ZIKViewRoutePopoverConfiguration : ZIKRouteConfiguration <NSCopying>

///UIPopoverPresentationControllerDelegate for above iOS8, UIPopoverControllerDelegate for iOS7
@property (nonatomic, weak, nullable) id<UIPopoverPresentationControllerDelegate> delegate;
@property (nonatomic, weak, nullable) UIBarButtonItem *barButtonItem;
@property (nonatomic, weak, nullable) UIView *sourceView;
@property (nonatomic, assign) CGRect sourceRect;
@property (nonatomic, assign) UIPopoverArrowDirection permittedArrowDirections;

@property (nonatomic, copy, nullable) NSArray<__kindof UIView *> *passthroughViews;//TODO:change strong reference to weak
@property (nonatomic, copy, nullable) UIColor *backgroundColor NS_AVAILABLE_IOS(7_0);
@property (nonatomic, assign) UIEdgeInsets popoverLayoutMargins;
@property (nonatomic, strong, nullable) Class popoverBackgroundViewClass;
@end

@interface ZIKViewRouteSegueConfiguration : ZIKRouteConfiguration <NSCopying>
///Should not be nil when route with ZIKViewRouteTypePerformSegue, or there will be an assert failure. But identifier may be nil when routing from storyboard and auto create a router.
@property (nonatomic, copy, nullable) NSString *identifier;
@property (nonatomic, weak, nullable) id sender;
@end

@interface ZIKViewRemoveConfiguration : ZIKRouteConfiguration <NSCopying>
///For pop/dismiss, default is YES
@property (nonatomic, assign) BOOL animated;

/**
 Handler when finish remove.
 @note
 Use weakSelf in routeCompletion to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^removeCompletion)(void);

///When set to YES and the router still exists, if the same destination instance is removed from external, removeCompletion, providerSuccessHandler, providerErrorHandler will be called
@property (nonatomic, assign) BOOL handleExternalRoute;
@end

#pragma mark Dynamic discover

/**
 Get the router class registered with a view (a ZIKRoutableView) conforming to a unique protocol.
 @discussion
 This function is for decoupling route behavior with router class. If a view conforms to a protocol for configuring it's dependencies, and the protocol is only used by this view, you can use ZIKViewRouter_registerViewProtocol() to register the protocol, then you don't need to import the router's header when performing route.
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
    ZIKViewRouter_registerView([ZIKLoginViewController class], self);
    ZIKViewRouter_registerViewProtocol(@protocol(ZIKLoginViewProtocol), self);
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
 See ZIKViewRouter_registerViewProtocol() for more info.
 
 It's safe to use protocols inheriting from ZIKViewRoutable and won't get nil. ZIKViewRouter will validate all ZIKViewRoutable protocols and registered protocols when app launch in DEBUG mode. In case someone passing an unexpected protocol, you can define a protocol like "#define _ZIKLoginViewProtocol_ (Protocol<ZIKViewRoutable> *)\@protocol(ZIKLoginViewProtocol)", and use the macro like ZIKViewRouterForView(_ZIKLoginViewProtocol_). Then if someone pass an undefined protocol, there will be a warning. Add "-Werror=incompatible-pointer-types" to "Build Settings->Other C Flags" to change build warning to build error.
 
 @param viewProtocol The protocol conformed by the view.
 @return A router class matched with the view. Return nil if protocol is nil or not declared. There will be an assert failure when result is nil.
 */
extern _Nullable Class ZIKViewRouterForView(Protocol<ZIKViewRoutable> *viewProtocol);

/**
 Get the router class combined with a custom ZIKViewRouteConfiguration conforming to a unique protocol.
 @discussion
 Similar to ZIKViewRouterForView(), this function is for decoupling route behavior with router class. If configurations of a module can't be set directly with a protocol the view conforms, you can use a custom ZIKViewRouteConfiguration to config these configurations. Use ZIKViewRouter_registerViewProtocol or ZIKViewRouter_registerConfigProtocol() to register the protocol, then you don't need to import the router's header when performing route.
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
 
 @implementation ZIKLoginViewRouter
 + (void)registerRoutableDestination {
    ZIKViewRouter_registerView([ZIKLoginViewController class], self);
    ZIKViewRouter_registerViewProtocol(@protocol(ZIKLoginViewConfigProtocol), self);
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
 See ZIKViewRouter_registerConfigProtocol() for more info.
 
 It's safe to use protocols inheriting from ZIKViewConfigRoutable and won't get nil. ZIKViewRouter will validate all ZIKViewConfigRoutable protocols and registered protocols when app launch in DEBUG mode. In case someone passing a undeclared protocol, you can define a protocol like "#define _ZIKLoginConfigProtocol_ (Protocol<ZIKViewConfigRoutable> *)\@protocol(ZIKLoginConfigProtocol)", and use the macro like ZIKViewRouterForView(_ZIKLoginConfigProtocol_). Then if someone pass a undefined protocol, there will be a warning. Add "-Werror=incompatible-pointer-types" to "Build Settings->Other C Flags" to change build warning to build error.

 @param configProtocol The protocol conformed by defaultConfiguration of router
 @return A router class matched with the view. Return nil if protocol is nil or not declared. There will be an assert failure when result is nil.
 */
extern _Nullable Class ZIKViewRouterForConfig(Protocol<ZIKViewConfigRoutable> *configProtocol);

#pragma mark ZIKViewRouterProtocol

#pragma mark Router Register

#ifdef DEBUG
#define ZIKVIEWROUTER_CHECK 1
#else
#define ZIKVIEWROUTER_CHECK 0
#endif

/**
 Register a viewClass with it's router's class, so we can create the router of a view when view is not created from router(UIViewController from storyboard or UIView added with -addSubview:, can't detect UIViewController displayed from code because we can't get the performer vc), and require the performer to config the view, and get AOP notified for some route actions.
 @note
 One view may be registered with multi routers, when view is routed from storyboard or -addSubview:, a router will be auto created from one of the registered router classes randomly. If you want to use a certain router, see ZIKViewRouter_registerViewForExclusiveRouter().
 One router may manage multi views. You can register multi view classes to a same router class.
 
 @param viewClass The view class managed by router
 @param routerClass The router class to bind with view class
 */
extern void ZIKViewRouter_registerView(Class viewClass, Class routerClass);

/**
 If the view will hold and use it's router, and the router has it's custom functions for this view, that means the view is coupled with the router. In this situation, you can use this function to combine viewClass with a specific routerClass, then no other routerClass can be used for this viewClass. If another routerClass try to register with the viewClass, there will be an assert failure.
 
 @param viewClass The view class requiring a specific router class
 @param routerClass The unique router class to bind with view class
 */
extern void ZIKViewRouter_registerViewForExclusiveRouter(Class viewClass, Class routerClass);

/**
 Register a view protocol that all views registered with the router conform to, then use ZIKViewRouterForView() to get the router class.
 @discussion
 If there're multi router classes for same view, and those routers is designed for preparing different part of the view when perform route (for example, a router is for presenting actionsheet style for UIAlertController, another router is for presenting alert style for UIAlertController), then each router has to register a unique protocol for the view and get the right router class with their protocol, or just import the router class your want to use directly.
 
 You can register your protocol and let the view conforms to the protocol in category in your interface adapter.
 
 @param viewProtocol The protocol conformed by view to identify the routerClass
 @param routerClass The router class to bind with view class
 */
extern void ZIKViewRouter_registerViewProtocol(Protocol *viewProtocol, Class routerClass);

/**
 Register a config protocol the router's default configuration conforms, then use ZIKViewRouterForConfig() to get the router class.
 @discussion
 If there're multi router classes for same view, and those routers provide different functions and use their subclass of ZIKViewRouteConfiguration (for example, your add a third-party library to your project, the library has a router for quickly presenting a UIAlertController, and in your project, there's a router for integrating UIAlertView and UIAlertController), then each router has to register a unique protocol for their configurations and get the right router class with this protocol, or just import the router class your want to use directly.
 
  You can register your protocol and let the configuration conforms to the protocol in category in your interface adapter.
 
 @param configProtocol The protocol conformed by default configuration of the routerClass
 @param routerClass The router class to bind with view class
 */
extern void ZIKViewRouter_registerConfigProtocol(Protocol *configProtocol, Class routerClass);

///If a UIViewController or UIView conforms to ZIKRoutableView, means there is a router class for it. Don't use it in other place.
@protocol ZIKRoutableView <NSObject>

@end

#pragma mark Router Implementation

extern NSArray<NSNumber *> *kDefaultRouteTypesForViewController;
extern NSArray<NSNumber *> *kDefaultRouteTypesForView;

@protocol ZIKViewRouteSource <NSObject>

@optional

/**
 If a UIViewController/UIView is routing from storyboard or a UIView is added by -addSubview:, the view will be detected, and a router will be created to prepare it. If the view need prepare, the router will search the performer of current route and call this method to prepare the destination.
 @note If a UIViewController is routing from manually code or is the initial view controller of app in storyboard (like directly use [performer.navigationController pushViewController:destination animated:YES]), the view will be detected, but won't create a router to search performer and prepare the destination, because we don't know which view controller is the performer calling -pushViewController:animated: (any child view controller in navigationController's stack can perform the route).

 @param destination The view will be routed. You can distinguish destinations with their view protocols.
 @param configuration Config for the route. You can distinguish destinations with their router's config protocols. You can modify this to prepare the route, but source, routeType, segueConfiguration, handleExternalRoute won't be modified even you change them.
 */
- (void)prepareForDestinationRoutingFromExternal:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration;

@end

@interface UIView () <ZIKViewRouteSource>
@end
@interface UIViewController () <ZIKViewRouteSource>
@end

@protocol ZIKViewRouteContainer <NSObject>
@end
@interface UINavigationController () <ZIKViewRouteContainer>
@end
@interface UITabBarController () <ZIKViewRouteContainer>
@end
@interface UISplitViewController () <ZIKViewRouteContainer>
@end

NS_ASSUME_NONNULL_END
