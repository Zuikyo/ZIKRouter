//
//  UIView+ZIKViewRouter.h
//  ZIKRouter
//
//  Created by zuik on 2017/5/31.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern BOOL ZIKClassIsCustomClass(Class class);

@protocol ZIKViperView;
@interface UIView (ZIKViewRouter)

/**
 Check UIView is routed or not, then determine a UIView is first appear or is removing from superview. Routed means the UIView is added to a superview and appeared once. This property is for all UIView. The implementation is in ZIKViewRouter.
 @discussion
 If a UIView is adding to superview, -willMoveToSuperview:newSuperview will be called, newSuperview is not nil. If a UIView is removing from superview, -willMoveToSuperview:nil will be called.
 
 If view is first appear, ZIK_routed will be NO in -willMoveToSuperview:, -didMoveToSuperview, -willMoveToWindow:, -didMoveToWindow (before [super didMoveToWindow], after [super didMoveToWindow], it's YES). If view is removing from superview, ZIK_routed will be NO in -willMoveToSuperview: and -didMoveToSuperview, but it's still YES in -willMoveToWindow: and -didMoveToWindow. When a UIView has appeared once, that means it's routed, ZIK_routed is YES.

 @return If the UIView is already routed, return YES, otherwise return NO
 */
- (BOOL)ZIK_routed;

///Get the UIViewController containing the view. Only available in and after -willMoveToWindow:.
- (nullable UIViewController *)ZIK_firstAvailableUIViewController;


/**
 Get the performer UIViewController or UIView who routed this view. Only available in and after -willMoveToWindow:.
 @discussion
 A performer must be a UIViewController or UIView, and is custom class, rather than classes from system's frameworks. Search the UIViewController and UIView in nextResponder and parentViewController/superview 's nextResponder.
 @return a UIViewController or UIView who add this view as it's subview. return nil when this view is not in any superview or view controller of custom class
 */
- (nullable id)ZIK_routePerformer;
@end

NS_ASSUME_NONNULL_END
