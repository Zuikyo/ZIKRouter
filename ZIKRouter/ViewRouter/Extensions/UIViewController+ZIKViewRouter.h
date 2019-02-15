//
//  UIViewController+ZIKViewRouter.h
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
#import "ZIKViewRouter.h"

NS_ASSUME_NONNULL_BEGIN

@class ZIKPresentationState;

#if ZIK_HAS_UIKIT
@interface UIViewController (ZIKViewRouter)
#else
@interface NSViewController (ZIKViewRouter)
#endif
/**
 Check UIViewController/NSViewController is routed or not, then determine an UIViewController/NSViewController is first appear or is removing. This property is for all UIViewController/NSViewController.  The implementation is in ZIKViewRouter.
 @discussion
 If an UIViewController/NSViewController is first appear, zix_routed will be NO in -viewWillAppear: and -viewDidAppear: (before [super viewDidAppear:], it's YES after [super viewDidAppear:]). If an UIViewController/NSViewController is removing, zix_routed will be NO in -viewDidDisappear:. When an UIViewController/NSViewController is displaying (even invisible), that means it's routed, zix_routed is YES.
 
 @return If the UIViewController/NSViewController is already routed, return YES, otherwise return NO.
 */
@property (nonatomic, readonly) BOOL zix_routed;

/**
 Check UIViewController/NSViewController is removing or not. This property is for all UIViewController/NSViewController. The implementation is in ZIKViewRouter.
 @discussion
 If an UIViewController/NSViewController is removing, zix_removing will be YES in -viewWillDisappear: and -viewDidDisappear: (before [super viewDidDisappear:], it's NO after [super viewDidDisappear:]). A removing may be cancelled, such as user swipes to pop view controller from navigation stack but the swiping gesture is cancelled.
 
 @return If the UIViewController/NSViewController is removing, return YES, otherwise return NO.
 */
@property (nonatomic, readonly) BOOL zix_removing;
@property (nonatomic, readonly) BOOL zix_isAppRootViewController;

#if ZIK_HAS_UIKIT
- (ZIKPresentationState *)zix_presentationState;
#endif

@end

NS_ASSUME_NONNULL_END
