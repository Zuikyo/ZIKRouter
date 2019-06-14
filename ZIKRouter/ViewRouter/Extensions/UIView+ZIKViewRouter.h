//
//  UIView+ZIKViewRouter.h
//  ZIKRouter
//
//  Created by zuik on 2017/5/31.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKPlatformCapabilities.h"
#if ZIK_HAS_UIKIT
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

#if ZIK_HAS_UIKIT
@interface UIView (ZIKViewRouter)
#else
@interface NSView (ZIKViewRouter)
#endif

/**
 Check UIView/NSView is routed or not, then determine an UIView/NSView is first appear or is removing from superview. Routed means the UIView/NSView is added to a superview and appeared once. This property is for all UIView/NSView. The implementation is in ZIKViewRouter.
 @discussion
 If an UIView/NSView is adding to superview, -willMoveToSuperview:newSuperview will be called, newSuperview is not nil. If an UIView/NSView is removing from superview, -willMoveToSuperview:nil will be called.
 
 If view is first appear, zix_routed will be NO in -willMoveToSuperview:, -didMoveToSuperview, -willMoveToWindow:, -didMoveToWindow (before [super didMoveToWindow], after [super didMoveToWindow], it's YES). If view is removing from superview, zix_routed will be NO in -willMoveToSuperview: and -didMoveToSuperview, but it's still YES in -willMoveToWindow: and -didMoveToWindow. When an UIView/NSView has appeared once, that means it's routed, zix_routed is YES.

 @return If the UIView/NSView is already routed, return YES, otherwise return NO.
 */
@property (nonatomic, readonly) BOOL zix_routed;

/// Whether the UIView/NSView is removing. YES in -willMoveToSuperview:nil and -didMoveToWindow nil.
@property (nonatomic, readonly) BOOL zix_removing;

/// Get the ViewController containing the view. Only available in and after -willMoveToWindow:.
#if ZIK_HAS_UIKIT
- (nullable UIViewController *)zix_firstAvailableUIViewController API_DEPRECATED_WITH_REPLACEMENT("zix_firstAvailableViewController", ios(7.0, 7.0));
- (nullable UIViewController *)zix_firstAvailableViewController;
#else
- (nullable NSViewController *)zix_firstAvailableViewController;
#endif

/// Whether the UIView/NSView is root view of some view controller.
- (BOOL)zix_isRootView;

/// Whether the UIView/NSView is during transition back of navigation controller from another view controller.
- (BOOL)zix_isDuringNavigationTransitionBack;

/**
 Get the performer UIViewController/NSViewController who routed this view. Only available in and after -willMoveToWindow:.
 @discussion
 A performer must be an UIViewController/NSViewController, and is custom class, rather than classes from system's frameworks. Search the UIViewController/NSViewController in nextResponder and parentViewController/superview's nextResponder.
 @return an UIViewController/NSViewController who add this view as its subview. return nil when this view is not in any superview or view controller of custom class.
 */
- (nullable id)zix_routePerformer;
@end

NS_ASSUME_NONNULL_END
