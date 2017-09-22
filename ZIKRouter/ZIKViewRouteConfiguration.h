//
//  ZIKViewRouteConfiguration.h
//  ZIKRouter
//
//  Created by zuik on 2017/9/18.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ZIKRouter.h"

NS_ASSUME_NONNULL_BEGIN

///Route type for view
typedef NS_ENUM(NSInteger,ZIKViewRouteType) {
    ///Navigation using @code-[source pushViewController:animated:]@endcode Source must be a UIViewController.
    ZIKViewRouteTypePush,
    ///Navigation using @code-[source presentViewController:animated:completion:]@endcode Source must be a UIViewController.
    ZIKViewRouteTypePresentModally,
    ///Adaptative type. Popover for iPad, present modally for iPhone.
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

typedef NS_OPTIONS(NSInteger, ZIKViewRouteTypeMask) {
    ZIKViewRouteTypeMaskPush                     = (1 << ZIKViewRouteTypePush),
    ZIKViewRouteTypeMaskPresentModally           = (1 << ZIKViewRouteTypePresentModally),
    ZIKViewRouteTypeMaskPresentAsPopover         = (1 << ZIKViewRouteTypePresentAsPopover),
    ZIKViewRouteTypeMaskPerformSegue             = (1 << ZIKViewRouteTypePerformSegue),
    ZIKViewRouteTypeMaskShow                     = (1 << ZIKViewRouteTypeShow),
    ZIKViewRouteTypeMaskShowDetail               = (1 << ZIKViewRouteTypeShowDetail),
    ZIKViewRouteTypeMaskAddAsChildViewController = (1 << ZIKViewRouteTypeAddAsChildViewController),
    ZIKViewRouteTypeMaskAddAsSubview             = (1 << ZIKViewRouteTypeAddAsSubview),
    ZIKViewRouteTypeMaskCustom                   = (1 << ZIKViewRouteTypeCustom),
    ZIKViewRouteTypeMaskGetDestination           = (1 << ZIKViewRouteTypeGetDestination),
    ZIKViewRouteTypeMaskUIViewControllerDefault  = (ZIKViewRouteTypeMaskPush | ZIKViewRouteTypeMaskPresentModally | ZIKViewRouteTypeMaskPresentAsPopover | ZIKViewRouteTypeMaskPerformSegue | ZIKViewRouteTypeMaskShow | ZIKViewRouteTypeMaskShowDetail | ZIKViewRouteTypeMaskAddAsChildViewController | ZIKViewRouteTypeMaskGetDestination),
    ZIKViewRouteTypeMaskUIViewDefault            = (ZIKViewRouteTypeMaskAddAsSubview | ZIKViewRouteTypeMaskGetDestination)
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

@class ZIKViewRoutePopoverConfiguration,ZIKViewRouteSegueConfiguration;
@protocol ZIKViewRouteSource,ZIKViewRouteContainer;
typedef UIViewController<ZIKViewRouteContainer>*_Nonnull(^ZIKViewRouteContainerWrapper)(UIViewController *destination);
typedef void(^ZIKViewRoutePopoverConfigure)(ZIKViewRoutePopoverConfiguration *popoverConfig);
typedef void(^ZIKViewRouteSegueConfigure)(ZIKViewRouteSegueConfiguration *segueConfig);
typedef void(^ZIKViewRoutePopoverConfiger)(NS_NOESCAPE ZIKViewRoutePopoverConfigure);
typedef void(^ZIKViewRouteSegueConfiger)(NS_NOESCAPE ZIKViewRouteSegueConfigure);

///Configuration of route. You can also use a subclass to add complex dependencies for destination. Your subclass must conforms to NSCopying, because the configuration need to be copied when routing.
@interface ZIKViewRouteConfiguration : ZIKRouteConfiguration <NSCopying>

/**
 Source ViewController or View for route
 @discussion
 For ZIKViewRouteTypePush, ZIKViewRouteTypePresentModally, ZIKViewRouteTypePresentAsPopover, ZIKViewRouteTypePerformSegue,ZIKViewRouteTypeShow,ZIKViewRouteTypeShowDetail,ZIKViewRouteTypeAddAsChildViewController, source must be a UIViewController.
 
 For ZIKViewRouteTypeAddAsSubview, source must be a UIView.
 
 For ZIKViewRouteTypeGetDestination, source is not needed.
 */
@property (nonatomic, weak, nullable) id<ZIKViewRouteSource> source;
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
 Prepare for performRoute, and config other dependencies for destination here. Subclass can offer more specific info.
 
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

///UIPopoverPresentationControllerDelegate for iOS8 and above, UIPopoverControllerDelegate for iOS7
@property (nonatomic, weak, nullable) id<UIPopoverPresentationControllerDelegate> delegate;
@property (nonatomic, weak, nullable) UIBarButtonItem *barButtonItem;
@property (nonatomic, weak, nullable) UIView *sourceView;
@property (nonatomic, assign) CGRect sourceRect;
@property (nonatomic, assign) UIPopoverArrowDirection permittedArrowDirections;
@property (nonatomic, copy, nullable) NSArray<__kindof UIView *> *passthroughViews;
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

@protocol ZIKViewRouteSource <NSObject>

@optional

/**
 If a UIViewController/UIView is routing from storyboard or a UIView is added by -addSubview:, the view will be detected, and a router will be created to prepare it. If the view need prepare, the router will search the performer of current route and call this method to prepare the destination.
 @note If a UIViewController is routing from manually code or is the initial view controller of app in storyboard (like directly use [performer.navigationController pushViewController:destination animated:YES]), the view will be detected, but won't create a router to search performer and prepare the destination, because we don't know which view controller is the performer calling -pushViewController:animated: (any child view controller in navigationController's stack can perform the route).
 
 @param destination The view to be routed. You can distinguish destinations with their view protocols.
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
