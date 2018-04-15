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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (ZIKViewRouter)

/**
 Check UIView is routed or not, then determine a UIView is first appear or is removing from superview. Routed means the UIView is added to a superview and appeared once. This property is for all UIView. The implementation is in ZIKViewRouter.
 @discussion
 If a UIView is adding to superview, -willMoveToSuperview:newSuperview will be called, newSuperview is not nil. If a UIView is removing from superview, -willMoveToSuperview:nil will be called.
 
 If view is first appear, zix_routed will be NO in -willMoveToSuperview:, -didMoveToSuperview, -willMoveToWindow:, -didMoveToWindow (before [super didMoveToWindow], after [super didMoveToWindow], it's YES). If view is removing from superview, zix_routed will be NO in -willMoveToSuperview: and -didMoveToSuperview, but it's still YES in -willMoveToWindow: and -didMoveToWindow. When a UIView has appeared once, that means it's routed, zix_routed is YES.

 @return If the UIView is already routed, return YES, otherwise return NO.
 */
@property (nonatomic, readonly) BOOL zix_routed;

///Get the UIViewController containing the view. Only available in and after -willMoveToWindow:.
- (nullable UIViewController *)zix_firstAvailableUIViewController;

/**
 Get the performer UIViewController who routed this view. Only available in and after -willMoveToWindow:.
 @discussion
 A performer must be a UIViewController, and is custom class, rather than classes from system's frameworks. Search the UIViewController and UIView in nextResponder and parentViewController/superview 's nextResponder.
 @return a UIViewController who add this view as it's subview. return nil when this view is not in any superview or view controller of custom class.
 */
- (nullable id)zix_routePerformer;
@end

NS_ASSUME_NONNULL_END
