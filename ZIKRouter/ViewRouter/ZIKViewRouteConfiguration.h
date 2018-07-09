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
#import "ZIKPlatformCapabilities.h"
#if ZIK_HAS_UIKIT
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif
#import "ZIKRouteConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

///Find router with view protocol. See ZIKRouteErrorInvalidProtocol.
extern ZIKRouteAction const ZIKRouteActionToView;
///Find router with view module protocol. See ZIKRouteErrorInvalidProtocol.
extern ZIKRouteAction const ZIKRouteActionToViewModule;
///Prepare external destination with router. See ZIKRouteErrorInvalidConfiguration.
extern ZIKRouteAction const ZIKRouteActionPrepareOnDestination;
///Perform route on external destination. See ZIKRouteErrorInvalidConfiguration.
extern ZIKRouteAction const ZIKRouteActionPerformOnDestination;

///Route types for view.
typedef NS_ENUM(NSInteger,ZIKViewRouteType) {
#if ZIK_HAS_UIKIT
    ///Navigation using @code-[source pushViewController:animated:]@endcode Source must be an UIViewController.
    ZIKViewRouteTypePush                     NS_ENUM_AVAILABLE_IOS(2_0)    = 0,
#endif
    ///Navigation using @code-[source presentViewController:animated:completion:]@endcode for iOS, @code-[source presentViewControllerAsModalWindow:destination]@endcode for Mac OS. Source must be an UIViewController / NSViewController.
    ZIKViewRouteTypePresentModally           NS_ENUM_AVAILABLE(10_10, 5_0) = 1,
    ///Adaptative type. Popover for iPad, present modally for iPhone, `-presentViewController:asPopoverRelativeToRect:ofView:preferredEdge:behavior:` for Mac OS.
    ZIKViewRouteTypePresentAsPopover         NS_ENUM_AVAILABLE(10_10, 3_2) = 2,
#if !ZIK_HAS_UIKIT
    ///Navigation in Mac OS using @code[source presentViewControllerAsSheet:destination]@endcode Source must be a NSViewController.
    ZIKViewRouteTypePresentAsSheet           NS_ENUM_AVAILABLE_MAC(10_10)  = 3,
    ///Navigation in Mac OS using @code[source presentViewController:destination animator:animator]@endcode Source must be a NSViewController.
    ZIKViewRouteTypePresentWithAnimator      NS_ENUM_AVAILABLE_MAC(10_10)  = 4,
#endif
    ///Navigation using @code[source performSegueWithIdentifier:destination sender:sender]@endcode If segue's destination doesn't comform to ZIKRoutableView, just use ZIKViewRouter to perform the segue.
    ZIKViewRouteTypePerformSegue             NS_ENUM_AVAILABLE(10_10, 5_0) = 5,
    /**
     For iOS, adaptative type using @code-[source showViewController:destination sender:sender]@endcode
     For Mac OS @code
     NSWindow *window = [NSWindow windowWithContentViewController:destination];
     NSWindowController *windowController = [[NSWindowController alloc] initWithWindow:window];
     [windowController showWindow:sender];
     @endcode
     
     For `-showViewController:sender:`:
     
     In UISplitViewController (source is master/detail or in master/detail's navigation stack): if master/detail is an UINavigationController and destination is not an UINavigationController, push destination on master/detail's stack, else replace master/detail with destination.
     
     In UINavigationController, push destination on stack.
     
     Without a container, present modally.
     */
    ZIKViewRouteTypeShow                     NS_ENUM_AVAILABLE(10_7, 8_0)  = 6,
#if ZIK_HAS_UIKIT
    /**
     Adaptative type. Navigation using @code-[source showDetailViewController:destination sender:sender]@endcode
     In UISplitViewController, replace detail with destination, if collapsed, forward to master view controller, if master is an UINavigationController, push on stack, else replace master with destination.
     
     In UINavigationController, present modally.
     
     Without a container, present modally.
     */
    ZIKViewRouteTypeShowDetail               NS_ENUM_AVAILABLE_IOS(8_0)    = 7,
#endif
    ///Get destination viewController and do @code[source addChildViewController:destination]@endcode; You need to add destination's view to soruce's view in addingChildViewHandler; source must be an UIViewController.
    ZIKViewRouteTypeAddAsChildViewController NS_ENUM_AVAILABLE(10_10, 5_0) = 8,
    ///Get your custom UIView and do @code[source addSubview:destination]@endcode; source must be an UIView.
    ZIKViewRouteTypeAddAsSubview             = 9,
    ///Subclass router can provide custom presentation. Class of source and destination is specified by subclass router.
    ZIKViewRouteTypeCustom                   = 10,
    ///Just create and return an UIViewController or UIView in successHandler; Source is not needed for this type.
    ZIKViewRouteTypeMakeDestination          = 11,
    ZIKViewRouteTypeGetDestination           NS_ENUM_DEPRECATED_IOS(7.0, 7.0, "Use ZIKViewRouteTypeMakeDestination instead") = ZIKViewRouteTypeMakeDestination
};

typedef NS_OPTIONS(NSInteger, ZIKViewRouteTypeMask) {
#if ZIK_HAS_UIKIT
    ZIKViewRouteTypeMaskPush                     = (1 << ZIKViewRouteTypePush),
#endif
    ZIKViewRouteTypeMaskPresentModally           = (1 << ZIKViewRouteTypePresentModally),
    ZIKViewRouteTypeMaskPresentAsPopover         = (1 << ZIKViewRouteTypePresentAsPopover),
#if !ZIK_HAS_UIKIT
    ZIKViewRouteTypeMaskPresentAsSheet           = (1 << ZIKViewRouteTypePresentAsSheet),
    ZIKViewRouteTypeMaskPresentWithAnimator      = (1 << ZIKViewRouteTypePresentWithAnimator),
#endif
    ZIKViewRouteTypeMaskPerformSegue             = (1 << ZIKViewRouteTypePerformSegue),
    ZIKViewRouteTypeMaskShow                     = (1 << 6 /*ZIKViewRouteTypeShow*/),
#if ZIK_HAS_UIKIT
    ZIKViewRouteTypeMaskShowDetail               = (1 << 7 /*ZIKViewRouteTypeShowDetail*/),
#endif
    ZIKViewRouteTypeMaskAddAsChildViewController = (1 << ZIKViewRouteTypeAddAsChildViewController),
    ZIKViewRouteTypeMaskAddAsSubview             = (1 << ZIKViewRouteTypeAddAsSubview),
    ZIKViewRouteTypeMaskCustom                   = (1 << ZIKViewRouteTypeCustom),
    ZIKViewRouteTypeMaskMakeDestination          = (1 << ZIKViewRouteTypeMakeDestination),
#if ZIK_HAS_UIKIT
    ZIKViewRouteTypeMaskViewControllerDefault    = (ZIKViewRouteTypeMaskPush
                                                    | ZIKViewRouteTypeMaskPresentModally
                                                    | ZIKViewRouteTypeMaskPresentAsPopover
                                                    | ZIKViewRouteTypeMaskPerformSegue
                                                    | ZIKViewRouteTypeMaskShow
                                                    | ZIKViewRouteTypeMaskShowDetail
                                                    | ZIKViewRouteTypeMaskAddAsChildViewController
                                                    | ZIKViewRouteTypeMaskMakeDestination),
#else
    ZIKViewRouteTypeMaskViewControllerDefault    = (ZIKViewRouteTypeMaskPresentModally
                                                    | ZIKViewRouteTypeMaskPresentAsPopover
                                                    | ZIKViewRouteTypeMaskPresentAsSheet
                                                    | ZIKViewRouteTypeMaskPresentWithAnimator
                                                    | ZIKViewRouteTypeMaskPerformSegue
                                                    | ZIKViewRouteTypeMaskShow
                                                    | ZIKViewRouteTypeMaskAddAsChildViewController
                                                    | ZIKViewRouteTypeMaskMakeDestination),
#endif
    ZIKViewRouteTypeMaskViewDefault              = (ZIKViewRouteTypeMaskAddAsSubview | ZIKViewRouteTypeMaskMakeDestination),
    ZIKViewRouteTypeMaskUIViewControllerDefault  NS_ENUM_DEPRECATED_IOS(7.0, 7.0, "Use ZIKViewRouteTypeMaskViewControllerDefault instead") = ZIKViewRouteTypeMaskViewControllerDefault,
    ZIKViewRouteTypeMaskUIViewDefault            NS_ENUM_DEPRECATED_IOS(7.0, 7.0, "Use ZIKViewRouteTypeMaskViewDefault instead") = ZIKViewRouteTypeMaskViewDefault,
    ZIKViewRouteTypeMaskGetDestination           NS_ENUM_DEPRECATED_IOS(7.0, 7.0, "Use ZIKViewRouteTypeMaskMakeDestination instead") = ZIKViewRouteTypeMaskMakeDestination
};

///Real route type performed for those adaptative types in ZIKViewRouteType
typedef NS_ENUM(NSInteger, ZIKViewRouteRealType) {
    ///Didn't perform any route yet. Router will reset type to this after removed
    ZIKViewRouteRealTypeUnknown                  = 0,
#if ZIK_HAS_UIKIT
    ZIKViewRouteRealTypePush                     = 1,
#endif
    ZIKViewRouteRealTypePresentModally           = 2,
    ZIKViewRouteRealTypePresentAsPopover         = 3,
#if !ZIK_HAS_UIKIT
    ZIKViewRouteRealTypePresentAsSheet           = 4,
    ZIKViewRouteRealTypePresentWithAnimator      = 5,
    ZIKViewRouteRealTypeShowWindow               = 6,
#endif
    ZIKViewRouteRealTypeAddAsChildViewController = 7,
    ZIKViewRouteRealTypeAddAsSubview             = 8,
    ZIKViewRouteRealTypeUnwind                   = 9,
    ZIKViewRouteRealTypeCustom                   = 10
};

@class ZIKViewRoutePath, ZIKViewRoutePopoverConfiguration, ZIKViewRouteSegueConfiguration;
@protocol ZIKViewRouteSource, ZIKViewRouteContainer;
#if ZIK_HAS_UIKIT
typedef UIViewController<ZIKViewRouteContainer>*_Nonnull(^ZIKViewRouteContainerWrapper)(UIViewController *destination);
#else
typedef NSViewController<ZIKViewRouteContainer>*_Nonnull(^ZIKViewRouteContainerWrapper)(NSViewController *destination);
#endif
typedef void(^ZIKViewRoutePopoverConfigure)(ZIKViewRoutePopoverConfiguration *popoverConfig);
typedef void(^ZIKViewRouteSegueConfigure)(ZIKViewRouteSegueConfiguration *segueConfig);
typedef void(^ZIKViewRoutePopoverConfiger)(NS_NOESCAPE ZIKViewRoutePopoverConfigure);
typedef void(^ZIKViewRouteSegueConfiger)(NS_NOESCAPE ZIKViewRouteSegueConfigure);

///Configuration for view module. You can use a subclass to add complex dependencies for destination. The subclass must conform to NSCopying, because the configuration needs to be copied when routing.
@interface ZIKViewRouteConfiguration : ZIKPerformRouteConfiguration <NSCopying>

///Set source and route type in a type safe way. You can extend your custom transition type in ZIKViewRoutePath, and use custom default configuration in router, override -configurePath: and set custom parameters to configuration.
- (void)configurePath:(ZIKViewRoutePath *)path NS_REQUIRES_SUPER;

/**
 Source ViewController or View for route.
 @discussion
 For ZIKViewRouteTypePush, ZIKViewRouteTypePresentModally, ZIKViewRouteTypePresentAsPopover, ZIKViewRouteTypePerformSegue,ZIKViewRouteTypeShow,ZIKViewRouteTypeShowDetail,ZIKViewRouteTypeAddAsChildViewController, source must be an UIViewController.
 
 For ZIKViewRouteTypeAddAsSubview, source must be an UIView.
 
 For ZIKViewRouteTypeMakeDestination, source is not needed.
 */
@property (nonatomic, weak, nullable) id<ZIKViewRouteSource> source;
///The style of route, default is ZIKViewRouteTypePresentModally. Subclass router may return other default value.
@property (nonatomic, assign) ZIKViewRouteType routeType;
///For push/present, default is YES
@property (nonatomic, assign) BOOL animated;

/**
 Wrap destination in an UINavigationController, UITabBarController or UISplitViewController, and perform route on the container. Only available for ZIKViewRouteTypePush, ZIKViewRouteTypePresentModally, ZIKViewRouteTypePresentAsPopover, ZIKViewRouteTypeShow, ZIKViewRouteTypeShowDetail, ZIKViewRouteTypeAddAsChildViewController.
 @discussion
 an UINavigationController or UISplitViewController can't be pushed into another UINavigationController, so:
 
 For ZIKViewRouteTypePush, container can't be an UINavigationController or UISplitViewController
 
 For ZIKViewRouteTypeShow, if source is in an UINavigationController, container can't be an UINavigationController or UISplitViewController
 
 For ZIKViewRouteTypeShowDetail, if source is in a collapsed UISplitViewController, and master is an UINavigationController, container can't be an UINavigationController or UISplitViewController
 
 For ZIKViewRouteTypeAddAsChildViewController, will add container as source's child, so you have to add container's view to source's view in addingChildViewHandler, not the destination's view
 */
@property (nonatomic, copy, nullable) ZIKViewRouteContainerWrapper containerWrapper;

/**
 Prepare for performRoute, and config other dependencies for destination here.
 
 @discussion
 For ZIKViewRouteTypePush, ZIKViewRouteTypePresentModally, ZIKViewRouteTypePresentAsPopover, ZIKViewRouteTypePerformSegue, ZIKViewRouteTypeShow, ZIKViewRouteTypeShowDetail, ZIKViewRouteTypeAddAsChildViewController, destination is an UIViewController.
 
 For ZIKViewRouteTypeAddAsSubview, destination is an UIView.
 
 For ZIKViewRouteTypeCustom, destination is an UIViewController or UIView.
 
 @note
 Use weakSelf in prepareDestination to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^prepareDestination)(id destination);

/**
 Success handler for performRoute. Each time the router was performed, success handler will be called when the operation succeed.
 
 @discussion
 For ZIKViewRouteTypePush, ZIKViewRouteTypePresentModally, ZIKViewRouteTypePresentAsPopover, ZIKViewRouteTypePerformSegue, ZIKViewRouteTypeShow, ZIKViewRouteTypeShowDetail, ZIKViewRouteTypeAddAsChildViewController, destination is an UIViewController.
 
 For ZIKViewRouteTypeAddAsSubview, destination is an UIView.
 
 For ZIKViewRouteTypeCustom, destination is an UIViewController or UIView.
 
 @note
 Use weakSelf in successHandler to avoid retain cycle.
 
 ZIKViewRouter use UIViewController's transitionCoordinator to do completion, so if you override segue's -perform or override -showViewController:sender: and provide custom transition, but didn't use a transitionCoordinator (such as use +[UIView animateWithDuration:animations:completion:] to animate), successHandler when be called immediately, before the animation really completes.
 */
@property (nonatomic, copy, nullable) void(^successHandler)(id destination);

///Sender for -showViewController:sender: ,-showDetailViewController:sender:, -showWindow:.
@property (nonatomic, weak, nullable) id sender;

#if !ZIK_HAS_UIKIT
///Animator for -presentViewController:animator: in Mac OS.
@property (nonatomic, strong, nullable) id<NSViewControllerPresentationAnimator> animator;
#endif

///Config popover for ZIKViewRouteTypePresentAsPopover
@property (nonatomic, readonly, copy) ZIKViewRoutePopoverConfiger configurePopover;

///config segue for ZIKViewRouteTypePerformSegue
@property (nonatomic, readonly, copy) ZIKViewRouteSegueConfiger configureSegue;

///When use routeType ZIKViewRouteTypeAddAsChildViewController, add the destination's view to source's view in this block. If you wrap destination with -containerWrapper, the `destination` in this block is the wrapped ViewController. You can add with animations, and must call completion when the adding action is finished.
#if ZIK_HAS_UIKIT
@property (nonatomic, copy, nullable) void(^addingChildViewHandler)(UIViewController *destination, void(^completion)(void));
#else
@property (nonatomic, copy, nullable) void(^addingChildViewHandler)(NSViewController *destination, void(^completion)(void));
#endif

@property (nonatomic, readonly, strong, nullable) ZIKViewRoutePopoverConfiguration *popoverConfiguration;
@property (nonatomic, readonly, strong, nullable) ZIKViewRouteSegueConfiguration *segueConfiguration;

///When set to YES and the router still exists, if the same destination instance is routed again from external, prepareDestination, successHandler, errorHandler, completionHandler will be called.
@property (nonatomic, assign) BOOL handleExternalRoute;

@end

@interface ZIKViewRoutePopoverConfiguration : ZIKRouteConfiguration <NSCopying>

#if ZIK_HAS_UIKIT
///UIPopoverPresentationControllerDelegate for iOS8 and above, UIPopoverControllerDelegate for iOS7
#if TARGET_OS_TV
@property (nonatomic, weak, nullable) id<UIPopoverControllerDelegate> delegate;
#else
@property (nonatomic, weak, nullable) id<UIPopoverPresentationControllerDelegate> delegate;
#endif
@property (nonatomic, weak, nullable) UIBarButtonItem *barButtonItem;
@property (nonatomic, weak, nullable) UIView *sourceView;
@property (nonatomic, assign) CGRect sourceRect;
@property (nonatomic, assign) UIPopoverArrowDirection permittedArrowDirections;
@property (nonatomic, copy, nullable) NSArray<__kindof UIView *> *passthroughViews;
@property (nonatomic, copy, nullable) UIColor *backgroundColor NS_AVAILABLE_IOS(7_0);
@property (nonatomic, assign) UIEdgeInsets popoverLayoutMargins;
@property (nonatomic, strong, nullable) Class popoverBackgroundViewClass;
#else
/// positioningView
@property (nonatomic, weak, nullable) NSView *sourceView;
/// positioningRect
@property (nonatomic, assign) NSRect sourceRect;
@property (nonatomic, assign) NSRectEdge preferredEdge;
@property (nonatomic, assign) NSPopoverBehavior behavior;
#endif
@end

@interface ZIKViewRouteSegueConfiguration : ZIKRouteConfiguration <NSCopying>
///Should not be nil when route with ZIKViewRouteTypePerformSegue, or there will be an assert failure. But identifier may be nil when routing from storyboard and auto create a router.
@property (nonatomic, copy, nullable) NSString *identifier;
@property (nonatomic, weak, nullable) id sender;
@end

@interface ZIKViewRemoveConfiguration : ZIKRemoveRouteConfiguration <NSCopying>
///For pop/dismiss, default is YES
@property (nonatomic, assign) BOOL animated;

///When use routeType ZIKViewRouteTypeAddAsChildViewController and remove, remove the destination's view from its superview in this block. If you wrap destination with -containerWrapper, the `destination` in this block is the wrapped ViewController. You can remove with animations, and must call completion when the removing action is finished.
#if ZIK_HAS_UIKIT
@property (nonatomic, copy, nullable) void(^removingChildViewHandler)(UIViewController *destination, void(^completion)(void));
#else
@property (nonatomic, copy, nullable) void(^removingChildViewHandler)(NSViewController *destination, void(^completion)(void));
#endif

///When set to YES and the router still exists, if the same destination instance is removed from external, successHandler, errorHandler, completionHandler will be called.
@property (nonatomic, assign) BOOL handleExternalRoute;
@end

#pragma mark Route Path

///Route path for setting route type and those required parameters for each type. You can extend your custom transition type here, and use custom default configuration in router, override -configurePath: and set custom parameters to configuration.
@interface ZIKViewRoutePath : NSObject
///Use default setting of ZIKViewRouteConfiguration, then the path's routeType won't be set to configuration.
@property (nonatomic) BOOL useDefault;
@property (nonatomic, strong, readonly, nullable) id<ZIKViewRouteSource> source;
@property (nonatomic, readonly) ZIKViewRouteType routeType;

@property (nonatomic, strong, readonly, nullable) ZIKViewRoutePopoverConfigure configurePopover;
@property (nonatomic, copy, readonly, nullable) NSString *segueIdentifier;
@property (nonatomic, strong, readonly, nullable) id segueSender;

#if ZIK_HAS_UIKIT
@property (nonatomic, copy, readonly, nullable) void(^addingChildViewHandler)(UIViewController *destination, void(^completion)(void));

/// Push the destination from the source view controller.
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^pushFrom)(UIViewController *source) NS_SWIFT_UNAVAILABLE("Use push(from:) instead");

/// Present the destination modally from the source view controller.
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^presentModallyFrom)(UIViewController *source) NS_SWIFT_UNAVAILABLE("Use presentModally(from:) instead");

/// Present the destination as popover from the source view controller, and configure the popover.
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^presentAsPopoverFrom)(UIViewController *source, ZIKViewRoutePopoverConfigure configurePopover) NS_SWIFT_UNAVAILABLE("Use presentAsPopover(from:configure:) instead");

/// Perform segue from the source view controller, with the segue identifier
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^performSegueFrom)(UIViewController *source, NSString *identifier, id _Nullable sender) NS_SWIFT_UNAVAILABLE("Use performSegue(from:identifier:sender:) instead");

/// Show the destination from the source view controller.
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^showFrom)(UIViewController *source) NS_SWIFT_UNAVAILABLE("Use show(from:) instead");

/// Show the destination as detail from the source view controller.
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^showDetailFrom)(UIViewController *source) NS_SWIFT_UNAVAILABLE("Use showDetail(from:) instead");

/// Add the destination as child view controller to the parent source view controller. Adding destination's view to source's view in addingChildViewHandler, and invoke the completion block when finished.
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^addAsChildViewControllerFrom)(UIViewController *source, void(^addingChildViewHandler)(UIViewController *destination, void(^completion)(void))) NS_SWIFT_UNAVAILABLE("Use addAsChildViewController(from:addingChildViewHandler) instead");

/// Add the destination as subview to the superview.
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^addAsSubviewFrom)(UIView *source) NS_SWIFT_UNAVAILABLE("Use addAsSubview(from:) instead");

/// Perform custom transition type from the source.
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^customFrom)(id<ZIKViewRouteSource> _Nullable source) NS_SWIFT_UNAVAILABLE("Use custom(from:) instead");

/// Use default setting of ZIKViewRouteConfiguration if you don't know which type to use.
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^defaultPathFrom)(UIViewController *source) NS_SWIFT_UNAVAILABLE("Use defaultPath(from:) instead");

/// Just make destination.
@property (nonatomic, class, readonly) ZIKViewRoutePath *makeDestination;

/// Push the destination from the source view controller.
+ (instancetype)pushFrom:(UIViewController *)source NS_SWIFT_NAME(push(from:));

/// Present the destination modally from the source view controller.
+ (instancetype)presentModallyFrom:(UIViewController *)source NS_SWIFT_NAME(presentModally(from:));

/// Present the destination as popover from the source view controller, and configure the popover.
+ (instancetype)presentAsPopoverFrom:(UIViewController *)source configure:(ZIKViewRoutePopoverConfigure)configure NS_SWIFT_NAME(presentAsPopover(from:configure:));

/// Perform segue from the source view controller, with the segue identifier
+ (instancetype)performSegueFrom:(UIViewController *)source identifier:(NSString *)identifier sender:(nullable id)sender NS_SWIFT_NAME(performSegue(from:identifier:sender:));

/// Show the destination from the source view controller.
+ (instancetype)showFrom:(UIViewController *)source NS_SWIFT_NAME(show(from:));

/// Show the destination as detail from the source view controller.
+ (instancetype)showDetailFrom:(UIViewController *)source NS_SWIFT_NAME(showDetail(from:));

/// Add the destination as child view controller to the parent source view controller. Adding destination's view to source's view in addingChildViewHandler, and invoke the completion block when finished.
+ (instancetype)addAsChildViewControllerFrom:(UIViewController *)source addingChildViewHandler:(void(^)(UIViewController *destination, void(^completion)(void)))addingChildViewHandler NS_SWIFT_NAME(addAsChildViewController(from:addingChildViewHandler:));

/// Add the destination as subview to the superview.
+ (instancetype)addAsSubviewFrom:(UIView *)source NS_SWIFT_NAME(addAsSubview(from:));

/// Perform custom transition type from the source.
+ (instancetype)customFrom:(nullable id<ZIKViewRouteSource>)source NS_SWIFT_NAME(custom(from:));

/// Use default setting of ZIKViewRouteConfiguration if you don't know which type to use.
+ (instancetype)defaultPathFrom:(UIViewController *)source NS_SWIFT_NAME(defaultPath(from:));

#else

@property (nonatomic, copy, readonly, nullable) void(^addingChildViewHandler)(NSViewController *destination, void(^completion)(void));

///Animator for -presentViewController:animator: in Mac OS.
@property (nonatomic, strong, readonly, nullable) id<NSViewControllerPresentationAnimator> animator;

/// Present the destination modally from the source view controller.
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^presentModallyFrom)(NSViewController *source) NS_SWIFT_UNAVAILABLE("Use presentModally(from:) instead");

/// Present the destination as popover from the source view controller, and configure the popover.
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^presentAsPopoverFrom)(NSViewController *source, ZIKViewRoutePopoverConfigure configurePopover) NS_SWIFT_UNAVAILABLE("Use presentAsPopover(from:configure:) instead");

/// Present the destination as sheet from the source view controller.
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^presentAsSheetFrom)(NSViewController *source) NS_SWIFT_UNAVAILABLE("Use presentAsSheet(from:) instead");

/// Present the destination with animator from the source view controller.
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^presentWithAnimatorFrom)(NSViewController *source, id<NSViewControllerPresentationAnimator> animator) NS_SWIFT_UNAVAILABLE("Use present(from:animator:) instead");

/// Perform segue from the source view controller, with the segue identifier
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^performSegueFrom)(NSViewController *source, NSString *identifier, id _Nullable sender) NS_SWIFT_UNAVAILABLE("Use performSegue(from:identifier:sender:) instead");

/// Show the destination with `-[NSWindowController showWindow:sender]`.
@property (nonatomic, class, readonly) ZIKViewRoutePath *show;

/// Add the destination as child view controller to the parent source view controller. Adding destination's view to source's view in addingChildViewHandler, and invoke the completion block when finished.
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^addAsChildViewControllerFrom)(NSViewController *source, void(^addingChildViewHandler)(NSViewController *destination, void(^completion)(void))) NS_SWIFT_UNAVAILABLE("Use addAsChildViewController(from:addingChildViewHandler) instead");

/// Add the destination as subview to the superview.
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^addAsSubviewFrom)(NSView *source) NS_SWIFT_UNAVAILABLE("Use addAsSubview(from:) instead");

/// Perform custom transition type from the source.
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^customFrom)(id<ZIKViewRouteSource> _Nullable source) NS_SWIFT_UNAVAILABLE("Use custom(from:) instead");

/// Use default setting of ZIKViewRouteConfiguration if you don't know which type to use.
@property (nonatomic, class, readonly) ZIKViewRoutePath *(^defaultPathFrom)(NSViewController *source) NS_SWIFT_UNAVAILABLE("Use defaultPath(from:) instead");

/// Just make destination.
@property (nonatomic, class, readonly) ZIKViewRoutePath *makeDestination;

/// Present the destination modally from the source view controller.
+ (instancetype)presentModallyFrom:(NSViewController *)source NS_SWIFT_NAME(presentModally(from:));

/// Present the destination as popover from the source view controller, and configure the popover.
+ (instancetype)presentAsPopoverFrom:(NSViewController *)source configure:(ZIKViewRoutePopoverConfigure)configure NS_SWIFT_NAME(presentAsPopover(from:configure:));

/// Present the destination as sheet from the source view controller.
+ (instancetype)presentAsSheetFrom:(NSViewController *)source NS_SWIFT_NAME(presentAsSheet(from:));

/// Present the destination with animator from the source view controller.
+ (instancetype)presentFrom:(NSViewController *)source animator:(id<NSViewControllerPresentationAnimator>)animator NS_SWIFT_NAME(present(from:animator:));

/// Perform segue from the source view controller, with the segue identifier
+ (instancetype)performSegueFrom:(NSViewController *)source identifier:(NSString *)identifier sender:(nullable id)sender NS_SWIFT_NAME(performSegue(from:identifier:sender:));

/// Add the destination as child view controller to the parent source view controller. Adding destination's view to source's view in addingChildViewHandler, and invoke the completion block when finished.
+ (instancetype)addAsChildViewControllerFrom:(NSViewController *)source addingChildViewHandler:(void(^)(NSViewController *destination, void(^completion)(void)))addingChildViewHandler NS_SWIFT_NAME(addAsChildViewController(from:addingChildViewHandler:));

/// Add the destination as subview to the superview.
+ (instancetype)addAsSubviewFrom:(NSView *)source NS_SWIFT_NAME(addAsSubview(from:));

/// Perform custom transition type from the source.
+ (instancetype)customFrom:(nullable id<ZIKViewRouteSource>)source NS_SWIFT_NAME(custom(from:));

/// Use default setting of ZIKViewRouteConfiguration if you don't know which type to use.
+ (instancetype)defaultPathFrom:(NSViewController *)source NS_SWIFT_NAME(defaultPath(from:));

#endif

///It's preferred to use those type safe factory methods, rather than this unsafe initializer, because this initializer doesn't check source's type.
- (instancetype)initWithRouteType:(ZIKViewRouteType)routeType source:(nullable id<ZIKViewRouteSource>)source NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

///Should only be conformed by UIViewController and UIView.
@protocol ZIKViewRouteSource <NSObject>

@optional

/**
 If an UIViewController/UIView is routing from storyboard or an UIView is added by -addSubview:, the view will be detected, and a router will be created to prepare it. If the view need prepare, the router will search the performer of current route and call this method to prepare the destination.
 @note If an UIViewController is routing from manually code (like directly use [performer.navigationController pushViewController:destination animated:YES]), the view will be detected, but won't create a router to search performer and prepare the destination, because we don't know which view controller is the performer calling -pushViewController:animated: (any child view controller in navigationController's stack can perform the route).
 
 @param destination The view to be routed. You can distinguish destinations with their view protocols.
 @param configuration Config for the route. You can distinguish destinations with their router's config protocols. You can modify this to prepare the route, but source, routeType, segueConfiguration, handleExternalRoute won't be modified even you change them.
 */
- (void)prepareDestinationFromExternal:(id)destination configuration:(__kindof ZIKViewRouteConfiguration *)configuration NS_SWIFT_NAME(prepare(destinationFromExternal:configuration:));

@end

#if ZIK_HAS_UIKIT

@interface UIView (ZIKViewRouteSource) <ZIKViewRouteSource>
@end
@interface UIViewController (ZIKViewRouteSource) <ZIKViewRouteSource>
@end

///UINavigationController, UITabBarController, UISplitViewController, or UIPageViewController.
@protocol ZIKViewRouteContainer <NSObject>
@end
@interface UINavigationController (ZIKViewRouteContainer) <ZIKViewRouteContainer>
@end
@interface UITabBarController (ZIKViewRouteContainer) <ZIKViewRouteContainer>
@end
@interface UISplitViewController (ZIKViewRouteContainer) <ZIKViewRouteContainer>
@end
@interface UIPageViewController (ZIKViewRouteContainer) <ZIKViewRouteContainer>
@end

#else

@interface NSView (ZIKViewRouteSource) <ZIKViewRouteSource>
@end
@interface NSViewController (ZIKViewRouteSource) <ZIKViewRouteSource>
@end

///NSTabViewController, NSSplitViewController, or NSPageController.
@protocol ZIKViewRouteContainer <NSObject>
@end
@interface NSTabViewController (ZIKViewRouteContainer) <ZIKViewRouteContainer>
@end
@interface NSSplitViewController (ZIKViewRouteContainer) <ZIKViewRouteContainer>
@end
@interface NSPageController (ZIKViewRouteContainer) <ZIKViewRouteContainer>
@end

#endif

#pragma mark Strict Configuration

///Proxy of ZIKViewRouteConfiguration to handle configuration in a type safe way.
@interface ZIKViewRouteStrictConfiguration<__covariant Destination> : ZIKPerformRouteStrictConfiguration<Destination>
@property (nonatomic, strong, readonly) ZIKViewRouteConfiguration *configuration;
- (instancetype)initWithConfiguration:(ZIKViewRouteConfiguration *)configuration;

/**
 Source ViewController or View for route.
 @discussion
 For ZIKViewRouteTypePush, ZIKViewRouteTypePresentModally, ZIKViewRouteTypePresentAsPopover, ZIKViewRouteTypePerformSegue,ZIKViewRouteTypeShow,ZIKViewRouteTypeShowDetail,ZIKViewRouteTypeAddAsChildViewController, source must be an UIViewController.
 
 For ZIKViewRouteTypeAddAsSubview, source must be an UIView.
 
 For ZIKViewRouteTypeMakeDestination, source is not needed.
 */
@property (nonatomic, weak, nullable) id<ZIKViewRouteSource> source;
///The style of route, default is ZIKViewRouteTypePresentModally. Subclass router may return other default value.
@property (nonatomic, assign) ZIKViewRouteType routeType;
///For push/present, default is YES
@property (nonatomic, assign) BOOL animated;

/**
 Wrap destination in an UINavigationController, UITabBarController or UISplitViewController, and perform route on the container. Only available for ZIKViewRouteTypePush, ZIKViewRouteTypePresentModally, ZIKViewRouteTypePresentAsPopover, ZIKViewRouteTypeShow, ZIKViewRouteTypeShowDetail, ZIKViewRouteTypeAddAsChildViewController.
 @discussion
 an UINavigationController or UISplitViewController can't be pushed into another UINavigationController, so:
 
 For ZIKViewRouteTypePush, container can't be an UINavigationController or UISplitViewController
 
 For ZIKViewRouteTypeShow, if source is in an UINavigationController, container can't be an UINavigationController or UISplitViewController
 
 For ZIKViewRouteTypeShowDetail, if source is in a collapsed UISplitViewController, and master is an UINavigationController, container can't be an UINavigationController or UISplitViewController
 
 For ZIKViewRouteTypeAddAsChildViewController, will add container as source's child, so you have to add container's view to source's view in addingChildViewHandler, not the destination's view
 */
@property (nonatomic, copy, nullable) ZIKViewRouteContainerWrapper containerWrapper;

/**
 Prepare for performRoute, and config other dependencies for destination here.
 
 @discussion
 For ZIKViewRouteTypePush, ZIKViewRouteTypePresentModally, ZIKViewRouteTypePresentAsPopover, ZIKViewRouteTypePerformSegue, ZIKViewRouteTypeShow, ZIKViewRouteTypeShowDetail, ZIKViewRouteTypeAddAsChildViewController, destination is an UIViewController.
 
 For ZIKViewRouteTypeAddAsSubview, destination is an UIView.
 
 For ZIKViewRouteTypeCustom, destination is an UIViewController or UIView.
 
 @note
 Use weakSelf in prepareDestination to avoid retain cycle.
 */
@property (nonatomic, copy, nullable) void(^prepareDestination)(Destination destination);

/**
 Success handler for performRoute. Each time the router was performed, success handler will be called when the operation succeed.
 
 @discussion
 For ZIKViewRouteTypePush, ZIKViewRouteTypePresentModally, ZIKViewRouteTypePresentAsPopover, ZIKViewRouteTypePerformSegue, ZIKViewRouteTypeShow, ZIKViewRouteTypeShowDetail, ZIKViewRouteTypeAddAsChildViewController, destination is an UIViewController.
 
 For ZIKViewRouteTypeAddAsSubview, destination is an UIView.
 
 For ZIKViewRouteTypeCustom, destination is an UIViewController or UIView.
 
 @note
 Use weakSelf in successHandler to avoid retain cycle.
 
 ZIKViewRouter use UIViewController's transitionCoordinator to do completion, so if you override segue's -perform or override -showViewController:sender: and provide custom transition, but didn't use a transitionCoordinator (such as use +[UIView animateWithDuration:animations:completion:] to animate), successHandler when be called immediately, before the animation really completes.
 */
@property (nonatomic, copy, nullable) void(^successHandler)(Destination destination);

///Sender for -showViewController:sender: and -showDetailViewController:sender:
@property (nonatomic, weak, nullable) id sender;

///Config popover for ZIKViewRouteTypePresentAsPopover
@property (nonatomic, readonly, copy) ZIKViewRoutePopoverConfiger configurePopover;

///Config segue for ZIKViewRouteTypePerformSegue
@property (nonatomic, readonly, copy) ZIKViewRouteSegueConfiger configureSegue;

///When use routeType ZIKViewRouteTypeAddAsChildViewController, add the destination's view to source's view in this block. If you wrap destination with -containerWrapper, the `destination` in this block is the wrapped UIViewController. You can add with animations, and must call completion when the adding action is finished.
#if ZIK_HAS_UIKIT
@property (nonatomic, copy, nullable) void(^addingChildViewHandler)(UIViewController *destination, void(^completion)(void));
#else
@property (nonatomic, copy, nullable) void(^addingChildViewHandler)(NSViewController *destination, void(^completion)(void));
#endif

@property (nonatomic, readonly, strong, nullable) ZIKViewRoutePopoverConfiguration *popoverConfiguration;
@property (nonatomic, readonly, strong, nullable) ZIKViewRouteSegueConfiguration *segueConfiguration;

///When set to YES and the router still exists, if the same destination instance is routed again from external, prepareDestination, successHandler, errorHandler, completionHandler will be called.
@property (nonatomic, assign) BOOL handleExternalRoute;

@end

///Proxy of ZIKViewRemoveConfiguration to handle configuration in a type safe way.
@interface ZIKViewRemoveStrictConfiguration<__covariant Destination> : ZIKRemoveRouteStrictConfiguration<Destination>
@property (nonatomic, strong, readonly) ZIKViewRemoveConfiguration *configuration;
- (instancetype)initWithConfiguration:(ZIKViewRemoveConfiguration *)configuration;

///For pop/dismiss, default is YES
@property (nonatomic, assign) BOOL animated;

///When use routeType ZIKViewRouteTypeAddAsChildViewController and remove, remove the destination's view from its superview in this block. If you wrap destination with -containerWrapper, the `destination` in this block is the wrapped UIViewController. You can remove with animations, and must call completion when the removing action is finished.
#if ZIK_HAS_UIKIT
@property (nonatomic, copy, nullable) void(^removingChildViewHandler)(UIViewController *destination, void(^completion)(void));
#else
@property (nonatomic, copy, nullable) void(^removingChildViewHandler)(NSViewController *destination, void(^completion)(void));
#endif

///When set to YES and the router still exists, if the same destination instance is removed from external, successHandler, errorHandler, completionHandler will be called.
@property (nonatomic, assign) BOOL handleExternalRoute;
@end

NS_ASSUME_NONNULL_END
