//
//  ZIKViewRouterProtocol.h
//  ZIKRouter
//
//  Created by zuik on 2017/9/18.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import "ZIKViewRouteConfiguration.h"

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
+ (ZIKViewRouteTypeMask)supportedRouteTypes;
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
///Perform your custom route. You must maintain the router's state with methods in ZIKViewRouterInternal.h.
- (void)performCustomRouteOnDestination:(id)destination fromSource:(id)source configuration:(__kindof ZIKViewRouteConfiguration *)configuration;
///Remove your custom route. You must maintain the router's state with methods in ZIKViewRouterInternal.h.
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

NS_ASSUME_NONNULL_END
