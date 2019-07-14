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

#if __has_include("ZIKViewRouter.h")

#import "ZIKViewRouter.h"
#import "ZIKRouterInternal.h"
#import "ZIKViewRouteError.h"
#import "ZIKViewRouterType.h"
#import "ZIKPlatformCapabilities.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZIKViewMakeableConfiguration<__covariant Destination> ()
/**
 Prepare the destination from the router internal before `prepareDestination:configuration:`.

 When it's removed and routed again, this method may be called more than once. You should check whether the destination is already prepared to avoid unnecessary preparation.
 */
@property (nonatomic, copy, nullable) void(^_prepareDestination)(Destination destination);
@end

/// Internal methods for subclass to override. Use these methods when implementing your custom route.
@interface ZIKViewRouter<__covariant Destination, __covariant RouteConfig: ZIKViewRouteConfiguration *> ()
@property (nonatomic, readonly, copy) RouteConfig original_configuration;
@property (nonatomic, readonly, copy) ZIKViewRemoveConfiguration *original_removeConfiguration;

#pragma mark Required Override

/// Register the destination class with those +registerXXX: methods. ZIKViewRouter will call this method before app did finish launching. You can also initialize your module in it. If a router was not registered with any view class, there'll be an assert failure.
+ (void)registerRoutableDestination;

/**
 Create your destination with configuration.
 
 @note
 Router with ZIKViewRouteTypePerformSegue route type won't invoke this method, because destination is created from storyboard.
 
 Router created with -performOnDestination:fromSource:configuring:removing: won't invoke this method.
 
 This methods is only responsible for create the destination. The additional initialization should be in -prepareDestination:configuration:.
 
 @param configuration Configuration for route.
 @return an UIViewController or UIView, If the configuration is invalid, return nil to make this route failed.
 */
//- (nullable Destination)destinationWithConfiguration:(RouteConfig)configuration;

#pragma mark Optional Override

/// Invoked after all registrations are finished when ZIKROUTER_CHECK is enabled, when ZIKROUTER_CHECK is disabled, this won't be invoked. You can override and do some debug checking or logging.
+ (void)_didFinishRegistration;

/// Supported route types of this router. Default is ZIKViewRouteTypeMaskViewControllerDefault for UIViewController type destination, if your destination is an UIView, override this and return ZIKViewRouteTypeMaskViewDefault. Router subclass can also limit the route type.
+ (ZIKViewRouteTypeMask)supportedRouteTypes;

/**
 Whether the router should be auto created for destination from storyboard segue or from external addSubview:.
 @discussion
 A router will be auto created when destination is routing from storyboard or UIView/NSView from external -addSubview:. See -destinationFromExternalPrepared: for more details.
 
 Sometimes you don't want to auto create the router when the destination already has a router or is already prepared. It's OK to recreate the router but it's recommanded to check and avoid those unnecessary auto creating.
 
 @note
 UIKit may implicitly remove and add the UIView during some animation. If the routable UIView is the root view of a view controller, it may be removed and added to an animating view when the view controller performs some view transition to another view controller, such as -pushViewController:animated: and popViewControllerAnimated:. So the router may be auto created again because the view is removed and added again when pushed to another view controller and poping back.
 Sample code:
 @code
 + (BOOL)shouldAutoCreateForDestination:(id)destination fromSource:(nullable id)source {
     // You can check whether the destination already has a router or is already prepared, then you can ignore this auto creating.
     if ([destination isKindOfClass:[UIView class]]) {
         UIView *view = destination;
         if ([view zix_isRootView] && [view zix_isDuringNavigationTransitionBack]) {
            return NO;
         }
     }
     return YES;
 }
 @endcode
 
 @param destination The view from external, such as UIViewController from storyboard and UIView from -addSubview:.
 @param source The source UIViewController or UIView.
 @return Return YES to create the router, otherwise return NO. Default is YES.
 */
+ (BOOL)shouldAutoCreateForDestination:(Destination)destination fromSource:(nullable id)source;

/**
 Whether the destination is all prepared, if not, it requires the performer to prepare it. This method is for destination from storyboard and UIView from external -addSubview:.
 @discussion
 Destination created from external will use this method to determine whether the router have to search the performer to prepare itself by invoking performer's -prepareDestinationFromExternal:configuration:.
 
 @note
 This method will be called for multi times when routing.
 @discussion
 ## About auto create: read https://github.com/Zuikyo/ZIKRouter/blob/master/Documentation/English/Storyboard.md
 
 When an UIViewController conforms to ZIKRoutableView, and is routing from storyboard segue or from -instantiateInitialViewController, a router will be auto created to prepare the UIViewController. If the destination needs preparing (-destinationFromExternalPrepared: returns NO), the segue's sourceViewController is responsible for preparing in delegate method -prepareDestinationFromExternal:configuration:. But When you show destination without router, such as use `[source presentViewController:destination animated:NO completion:nil]`, the routers can get AOP callback, but can't search source view controller to prepare the destination. So the router won't be auto created. If you use a router as a dependency injector for preparing the UIViewController, you should always display the UIViewController instance with router.
 
 When Adding a routable UIView with -addSubview: or from xib, a router will be auto created. We search the view controller of custom class (not system class like native UINavigationController, or any container view controller) in its responder hierarchy as the performer. If the registered UIView needs preparing (-destinationFromExternalPrepared: returns NO), you have to add the view to a superview in a view controller before it's removed from superview. There will be an assert failure if there is no view controller to prepare it (such as: 1. add it to a superview, and the superview is never added to a view controller; 2. add it to an UIWindow). If your custom class view use a routable view as its subview, the custom view should use a router to add and prepare the routable view, then the routable view doesn't need to search performer because it's already prepared.
 
 @param destination The view from external, such as UIViewController from storyboard and UIView from -addSubview:.
 @return If the destination requires the performer to prepare it, return NO, then router will call performer's -prepareDestinationFromExternal:configuration:. Default is YES.
 */
- (BOOL)destinationFromExternalPrepared:(Destination)destination NS_SWIFT_NAME(destinationFromExternalPrepared(destination:));

+ (BOOL)destinationPrepared:(Destination)destination API_DEPRECATED_WITH_REPLACEMENT("destinationFromExternalPrepared:", ios(7.0, 7.0));

/**
 Prepare the destination with the configuration when view first appears. When it's removed and routed again, it's alse treated as first appearance, so this method may be called more than once. You should check whether the destination is already prepared to avoid unnecessary preparation.
 
 The reason of separating instantiation and preparation of destination, is that not all destination are creating from `destinationWithConfiguration:` (destination from storyboard or external), we can reuse the preparation code if we put them in this method.
 
 If you get a prepared destination by ZIKViewRouteTypeMakeDestination or -prepareDestination:configuring:removing:, this method will be called. When the destination is routing, this method will also be called, because the destination may be changed.
 
 Unwind segue to destination won't call this method.
 
 @warning
 Cycle Dependency: read https://github.com/Zuikyo/ZIKRouter/blob/master/Documentation/English/CircularDependencies.md
 
 If a router(A) fetch destination(A)'s dependency destination(B) with another router(B) in router(A)'s -prepareDestination:configuration:, and the destination(A) is also the destination(B)'s dependency, so destination(B)'s router(B) will also fetch destination(A) with router(A) in its -prepareDestination:configuration:. Then there will be an infinite recursion.
 
 To void it, when router(A) fetch destination(B) in -prepareDestination:configuration:, router(A) must inject destination(A) to destination(B) in -prepareDestination block of router(B)'s config or use custom config property. And router(B) should check in -prepareDestination:configuration: to avoid unnecessary preparation to fetch destination(A) again.
 
 @param destination The view to perform route.
 @param configuration The configuration for route.
 */
- (void)prepareDestination:(Destination)destination configuration:(RouteConfig)configuration;

/**
 Called when view first appears and its preparation is finished. You can check whether destination is prepared correctly. Unwind segue to destination won't call this method.
 @warning
 when it's removed and routed again, it's alse treated as first appearance, so this method may be called more than once. You should check whether the destination is already prepared to avoid unnecessary preparation.
 
 @param destination The view to perform route.
 @param configuration The configuration for route.
 */
- (void)didFinishPrepareDestination:(Destination)destination configuration:(RouteConfig)configuration;

#pragma mark Custom Route Required Override

/// Custom route for ZIKViewRouteTypeCustom. The router must override +supportedRouteTypes to add ZIKViewRouteTypeMaskCustom.

/// Whether the router can perform custom route now. Default is NO.
- (BOOL)canPerformCustomRoute;
/// Whether the router can remove custom route now. Default is NO. Check the states of destination and source, return NO if they can't be removed.
- (BOOL)canRemoveCustomRoute;

/**
 Perform custom view transition action, and maintain the router's state.
 
 Steps to use custom transition:
 
 1. Override `supportedRouteTypes`, add`ZIKViewRouteTypeCustom`
 
 2. If the router needs to validate the configuration, override `-validateCustomRouteConfiguration:removeConfiguration:`
 
 3. Override `canPerformCustomRoute` to check whether the router can perform route now because the default return value is false
 
 4. Override `performCustomRouteOnDestination:fromSource:configuration:` to do custom transition. If the transition is performing a segue, use `_performSegueWithIdentifier:fromSource:sender:`
 
 5. Manage router's state with `beginPerformRoute`, `endPerformRouteWithSuccess`, `endPerformRouteWithError:`
 */
- (void)performCustomRouteOnDestination:(Destination)destination fromSource:(nullable id)source configuration:(RouteConfig)configuration;

#pragma mark Custom Route Optional Override

/**
 Remove custom view transition. You must maintain the router's state with methods in ZIKViewRouterInternal.h.
 
 Steps to use custom transition for removing a view:
 
 1. Override `supportedRouteTypes`, add`ZIKViewRouteTypeCustom`
 
 2. Override `removeCustomRouteOnDestination:fromSource:removeConfiguration:configuration:` to do custom transition
 
 3. Manage router's state with `beginRemoveRouteFromSource:`, `endRemoveRouteWithSuccessOnDestination:fromSource:`, `endRemoveRouteWithError:`
 */
- (void)removeCustomRouteOnDestination:(Destination)destination fromSource:(nullable id)source removeConfiguration:(ZIKViewRemoveConfiguration *)removeConfiguration configuration:(RouteConfig)configuration;

/// Validate the configuration for your custom route. If return NO, current perform action will be failed.
+ (BOOL)validateCustomRouteConfiguration:(RouteConfig)configuration removeConfiguration:(ZIKViewRemoveConfiguration *)removeConfiguration;

#pragma mark Custom Route Checking

/// Check view controller state in -canPerformCustomRoute, -canRemoveCustomRoute or -performCustomRouteOnDestination:fromSource:configuration:.

/// Whether the source can perform present now.
- (BOOL)_canPerformPresent;
#if ZIK_HAS_UIKIT
/// Whether the source can perform push now.
- (BOOL)_canPerformPush;
/// Whether the destination is not in navigation stack of the source. If the destination is already pushed, it can't be pushed again.
+ (BOOL)_validateDestination:(UIViewController *)destination notInNavigationStackOfSource:(UIViewController *)source;

/// Whether the destination can pop.
- (BOOL)_canPop;
#endif
/// Whether the destination can dismiss.
- (BOOL)_canDismiss;
/// Whether the destination can remove from parant.
- (BOOL)_canRemoveFromParentViewController;
/// Whether the destination can remove from superview.
- (BOOL)_canRemoveFromSuperview;

#pragma mark Custom Route State Control

/// when you implement custom route or remove route by overriding -performRouteOnDestination:configuration: or -removeDestination:removeConfiguration:, maintain the route state with these methods, and state control methods in ZIKRouterInternal.h.

/// Call it when router will perform custom route.
- (void)beginPerformRoute;

/// If your custom route type is performing a segue, use this to perform the segue, don't need to use -beginPerformRoute and -endPerformRouteWithSuccess. `source` is the view controller to perform the segue.
#if ZIK_HAS_UIKIT
- (void)_performSegueWithIdentifier:(NSString *)identifier fromSource:(UIViewController *)source sender:(nullable id)sender;
#else
- (void)_performSegueWithIdentifier:(NSString *)identifier fromSource:(NSViewController *)source sender:(nullable id)sender;
#endif

/// Call it when route will begin custom remove.
- (void)beginRemoveRouteFromSource:(nullable id)source;
/// Call it when route is successfully removed.
- (void)endRemoveRouteWithSuccessOnDestination:(Destination)destination fromSource:(nullable id)source;
/// Call it when route remove failed.
- (void)endRemoveRouteWithError:(NSError *)error;

- (void)endRemoveRouteWithSuccess NS_UNAVAILABLE
;
#pragma mark Error Handle

/// error from ZIKViewRouteErrorDomain.
+ (NSError *)viewRouteErrorWithCode:(ZIKViewRouteError)code localizedDescription:(NSString *)description;
/// error from ZIKViewRouteErrorDomain.
+ (NSError *)viewRouteErrorWithCode:(ZIKViewRouteError)code localizedDescriptionFormat:(NSString *)format ,...;

+ (void)notifyGlobalErrorWithRouter:(nullable __kindof ZIKViewRouter *)router action:(ZIKRouteAction)action error:(NSError *)error;

#pragma mark AOP

/**
 AOP support.
 Route with ZIKViewRouteTypeAddAsChildViewController and ZIKViewRouteTypeMakeDestination won't get AOP notification, because they are not complete route for displaying the destination, the destination will get AOP notification when it's really displayed.
 
 Router will be nil when route is from external or AddAsChildViewController/MakeDestination route type.
 
 Source may be nil when remove route, because source may already be deallced.
 */

/**
 AOP callback when any perform route action will begin. All router classes managing the same view class will be notified.
 @discussion
 Invoked time:
 
 For UIViewController routing from router or storyboard, invoked after destination is preapared and about to do route action.
 
 For UIViewController not routing from router, or routed by ZIKViewRouteTypeMakeDestination or ZIKViewRouteTypeAddAsChildViewController then displayed manually, invoked in -viewWillAppear:. The parameter `router` is nil.
 
 For UIView routing by ZIKViewRouteTypeAddAsSubview type, invoked after destination is prepared and before -addSubview: is called.
 
 For UIView routing from xib or from manually addSubview: or routed by ZIKViewRouteTypeMakeDestination, invoked after destination is prepared, and is about to be visible (moving to window), but not in -willMoveToSuperview:. Beacuse we need to auto create router and search performer in responder hierarchy. In some situation, the responder is only available when the UIView is on a window. See comments inside -ZIKViewRouter_hook_willMoveToSuperview: for more detial.
 */
+ (void)router:(nullable ZIKViewRouter *)router willPerformRouteOnDestination:(Destination)destination fromSource:(nullable id)source;

/**
 AOP callback when any perform route action did finish. All router classes managing the same view class will be notified.
 @discussion
 Invoked time:
 
 For UIViewController routing from router or storyboard, invoked after route animation is finished. See -successHandler.
 
 For UIViewController not routing from router, or routed by ZIKViewRouteTypeAddAsChildViewController or ZIKViewRouteTypeMakeDestination then displayed manually, invoked in -viewDidAppear:. The parameter `router` is nil.
 
 For UIView routing by ZIKViewRouteTypeAddAsSubview type, invoked after -addSubview: is called.
 
 For UIView routing from xib or from manually addSubview: or routed by ZIKViewRouteTypeMakeDestination, invoked after destination is visible (did move to window), but not in -didMoveToSuperview:. See comments inside -ZIKViewRouter_hook_willMoveToSuperview: for more detial.
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

FOUNDATION_EXTERN ZIKAnyViewRouterType *_Nullable _ZIKViewRouterToView(Protocol *viewProtocol);

FOUNDATION_EXTERN ZIKAnyViewRouterType *_Nullable _ZIKViewRouterToModule(Protocol *configProtocol);

FOUNDATION_EXTERN ZIKAnyViewRouterType *_Nullable _ZIKViewRouterToIdentifier(NSString *identifier);

FOUNDATION_EXTERN Protocol<ZIKViewRoutable> *_Nullable _routableViewProtocolFromObject(id object);

FOUNDATION_EXTERN Protocol<ZIKViewModuleRoutable> *_Nullable _routableViewModuleProtocolFromObject(id object);

typedef id  _Nullable (^ZIKViewFactoryBlock)(ZIKViewRouteConfiguration * _Nonnull);

FOUNDATION_EXTERN void _registerViewProtocolWithSwiftFactory(Protocol<ZIKViewRoutable> *viewProtocol, Class viewClass, ZIKViewFactoryBlock function);

FOUNDATION_EXTERN void _registerViewModuleProtocolWithSwiftFactory(Protocol<ZIKViewModuleRoutable> *moduleProtocol, Class viewClass, id(^block)(void));

FOUNDATION_EXTERN void _registerViewIdentifierWithSwiftFactory(NSString *identifier, Class viewClass, ZIKViewFactoryBlock function);

FOUNDATION_EXTERN void _registerViewModuleIdentifierWithSwiftFactory(NSString *identifier, Class viewClass, id(^block)(void));

NS_ASSUME_NONNULL_END

#endif
