//
//  ZIKViewRouterInternal.h
//  ZIKRouter
//
//  Created by zuik on 2017/5/25.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKViewRouter.h"

NS_ASSUME_NONNULL_BEGIN

///Internal methods for subclass to override. Use these methods when implementing your custom route.
@interface ZIKViewRouter<__covariant Destination: id, __covariant RouteConfig: ZIKViewRouteConfiguration *> ()
@property (nonatomic, readonly, copy) RouteConfig original_configuration;
@property (nonatomic, readonly, copy) ZIKViewRemoveConfiguration *original_removeConfiguration;

#pragma mark Required Override

///Register the destination class with those +registerXXX: methods. ZIKViewRouter will call this method before app did finish launch. If a router was not registered with any view class, there'll be an assert failure.
+ (void)registerRoutableDestination;

/**
 Create your destination with configuration.
 
 @note
 Router with ZIKViewRouteTypePerformSegue route type won't invoke this method, because destination is created from storyboard.
 
 Router created with -performOnDestination:fromSource:configuring:removing: won't invoke this method.
 
 This methods is only responsible for create the destination. The additional initialization should be in -prepareDestination:configuration:.
 
 @param configuration Configuration for route.
 @return A UIViewController or UIView, If the configuration is invalid, return nil to make this route failed.
 */
//- (nullable Destination)destinationWithConfiguration:(RouteConfig)configuration;

#pragma mark Optional Override

///Invoked after auto registration is finished when ZIKROUTER_CHECK is enabled. You can override and validate whether those routable swift protocols used in your module as external dependencies have registered with routers, because we can't enumerate swift protocols at runtime.
+ (void)_autoRegistrationDidFinished;

/**
 Whether the destination is all configured.
 @discussion
 Destination created from external will use this method to determine whether the router have to search the performer to prepare itself by invoking performer's -prepareDestinationFromExternal:configuration:.
 
 @param destination The view to perform route.
 @return If the destination is not prepared, return NO. Default is YES.
 */
+ (BOOL)destinationPrepared:(Destination)destination;

/**
 Prepare the destination with the configuration when view first appears. Unwind segue to destination won't call this method.
 @warning
 If a router(A) fetch destination(A)'s dependency destination(B) with another router(B) in router(A)'s -prepareDestination:configuration:, and the destination(A) is also the destination(B)'s dependency, so destination(B)'s router(B) will also fetch destination(A) with router(A) in it's -prepareDestination:configuration:. Then there will be an infinite recursion.
 
 To void it, when router(A) fetch destination(B) in -prepareDestination:configuration:, router(A) must inject destination(A) to destination(B) in -prepareRoute block of router(B)'s config or use custom config property. And router(B) should check in -prepareDestination:configuration: to avoid unnecessary preparation to fetch destination(A) again.
 
 @note
 When it's removed and routed again, it's alse treated as first appearance, so this method may be called more than once. You should check whether the destination is already prepared to avoid unnecessary preparation.
 
 If you get a prepared destination by ZIKViewRouteTypeGetDestination or -prepareDestination:configuring:removing:, this method will be called. When the destination is routed, this method will also be called, because the destination may be changed.
 
 @param destination The view to perform route.
 @param configuration The configuration for route.
 */
- (void)prepareDestination:(Destination)destination configuration:(RouteConfig)configuration;

/**
 Called when view first appears and it's preparation is finished. You can check whether destination is preapred correctly. Unwind segue to destination won't call this method.
 @warning
 when it's removed and routed again, it's alse treated as first appearance, so this method may be called more than once. You should check whether the destination is already prepared to avoid unnecessary preparation.
 
 @param destination The view to perform route.
 @param configuration The configuration for route.
 */
- (void)didFinishPrepareDestination:(Destination)destination configuration:(RouteConfig)configuration;

#pragma mark Custom Route Required Override

///Custom route for ZIKViewRouteTypeCustom. The router must override +supportedRouteTypes to add ZIKViewRouteTypeMaskCustom.

///Whether the router can perform custom route now.
- (BOOL)canPerformCustomRoute;
///Whether the router can remove custom route now.
- (BOOL)canRemoveCustomRoute;

///Perform your custom route. You must maintain the router's state with methods in ZIKViewRouterInternal.h.
- (void)performCustomRouteOnDestination:(Destination)destination fromSource:(nullable id)source configuration:(RouteConfig)configuration;

#pragma mark Custom Route Optional Override

///Remove your custom route. You must maintain the router's state with methods in ZIKViewRouterInternal.h.
- (void)removeCustomRouteOnDestination:(Destination)destination fromSource:(nullable id)source removeConfiguration:(ZIKViewRemoveConfiguration *)removeConfiguration configuration:(RouteConfig)configuration;

///Validate the configuration for your custom route. If return NO, current perform action will be failed.
+ (BOOL)validateCustomRouteConfiguration:(RouteConfig)configuration removeConfiguration:(ZIKViewRemoveConfiguration *)removeConfiguration;

#pragma mark Custom Route State Control

///Maintain the route state when you implement custom route or remove route by overriding -performRouteOnDestination:configuration: or -removeDestination:removeConfiguration:.
///Call it when route will perform.
- (void)beginPerformRoute;
///Call it when route is successfully performed.
- (void)endPerformRouteWithSuccess;
///Call it when route perform failed.
- (void)endPerformRouteWithError:(NSError *)error;

///If your custom route type is performing a segue, use this to perform the segue, don't need to use -beginPerformRoute and -endPerformRouteWithSuccess. `source` is the view controller to perform the segue.
- (void)_performSegueWithIdentifier:(NSString *)identifier fromSource:(UIViewController *)source sender:(nullable id)sender;

///Call it when route will remove.
- (void)beginRemoveRouteFromSource:(nullable id)source;
///Call it when route is successfully removed.
- (void)endRemoveRouteWithSuccessOnDestination:(Destination)destination fromSource:(nullable id)source;
///Call it when route remove failed.
- (void)endRemoveRouteWithError:(NSError *)error;

#pragma mark AOP

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
 For UIView routing from xib or from manually addSubview: or routed by ZIKViewRouteTypeGetDestination, invoked after destination is prepared, and is about to be visible (moving to window), but not in -willMoveToSuperview:. Beacuse we need to auto create router and search performer in responder hierarchy. In some situation, the responder is only available when the UIView is on a window. See comments inside -ZIKViewRouter_hook_willMoveToSuperview: for more detial.
 */
+ (void)router:(nullable ZIKViewRouter *)router willPerformRouteOnDestination:(Destination)destination fromSource:(nullable id)source;

/**
 AOP callback when any perform route action did finish. All router classes managing the same view class will be notified.
 @discussion
 Invoked time:
 
 For UIViewController routing from router or storyboard, invoked after route animation is finished. See -routeCompletion.
 For UIViewController not routing from router, or routed by ZIKViewRouteTypeAddAsChildViewController or ZIKViewRouteTypeGetDestination then displayed manually, invoked in -viewDidAppear:. The parameter `router` is nil.
 For UIView routing by ZIKViewRouteTypeAddAsSubview type, invoked after -addSubview: is called.
 For UIView routing from xib or from manually addSubview: or routed by ZIKViewRouteTypeGetDestination, invoked after destination is visible (did move to window), but not in -didMoveToSuperview:. See comments inside -ZIKViewRouter_hook_willMoveToSuperview: for more detial.
 */
+ (void)router:(nullable ZIKViewRouter *)router didPerformRouteOnDestination:(Destination)destination fromSource:(nullable id)source;

/**
 AOP callback when any remove route action will begin. All router classes managing the same view class will be notified.
 @discussion
 Invoked time:
 
 For UIViewController or UIView removing from router, invoked before remove route action is called.
 For UIViewController not removing from router, invoked in -viewWillDisappear:. The parameter `router` is nil.
 For UIView not removing from router, invoked in -willMoveToSuperview:nil. The parameter `router` is nil.
 */
+ (void)router:(nullable ZIKViewRouter *)router willRemoveRouteOnDestination:(Destination)destination fromSource:(nullable id)source;

/**
 AOP callback when any remove route action did finish. All router classes managing the same view class will be notified.
 @discussion
 Invoked time:
 
 For UIViewController or UIView removing from router, invoked after remove route action is called.
 For UIViewController not removing from router, invoked in -viewDidDisappear:. The parameter `router` is nil.
 For UIView not removing from router, invoked in -didMoveToSuperview:nil. The parameter `router` is nil. The source may be nil, bacause superview may be dealloced.
 */
+ (void)router:(nullable ZIKViewRouter *)router didRemoveRouteOnDestination:(Destination)destination fromSource:(nullable id)source;

@end

NS_ASSUME_NONNULL_END
