//
//  ZIKViewRouteError.h
//  ZIKRouter
//
//  Created by zuik on 2017/11/6.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSErrorDomain const ZIKViewRouteErrorDomain;

/// Errors for callback in ZIKRouteErrorHandler and ZIKViewRouteGlobalErrorHandler
#ifdef NS_ERROR_ENUM
typedef NS_ERROR_ENUM(ZIKViewRouteErrorDomain, ZIKViewRouteError) {
#else
typedef NS_ENUM(NSInteger, ZIKViewRouteError) {
#endif
    /// Bad implementation in code. When adding an UIView or UIViewController conforms to ZIKRoutableView in xib or storyboard, and it needs preparing, you have to implement -prepareDestinationFromExternal:configuration: in the view controller which added it.
    ZIKViewRouteErrorInvalidPerformer     = 10,
    /// This router doesn't support the route type you assigned.
    ZIKViewRouteErrorUnsupportType        = 11,
    /**
     Unbalanced calls to begin/end appearance transitions for destination. This error occurs when you try and display a view controller before the current view controller is finished displaying. This may cause the UIViewController skips or messes up the order calling -viewWillAppear:, -viewDidAppear:, -viewWillDisAppear: and -viewDidDisappear:, and messes up the route state.
     */
    ZIKViewRouteErrorUnbalancedTransition = 12,
    /**
     1. Source can't perform action with corresponding route type, maybe it's missed or is wrong class, see ZIKViewRouteConfiguration.source.
     
     2. Source is dealloced when perform route.
     
     3. Source is not in any navigation stack when perform push.
     
     4. Source already presented another view controller when perform present, can't do present now.
     
     5. Attempt to present destination on source whose view is not in the window hierarchy or not added to any superview.
     */
    ZIKViewRouteErrorInvalidSource        = 13,
    /// See containerWrapper
    ZIKViewRouteErrorInvalidContainer     = 14,
    /// An unwind segue was aborted because -[destinationViewController canPerformUnwindSegueAction:fromViewController:withSender:] return NO or can't perform segue.
    ZIKViewRouteErrorSegueNotPerformed    = 15
    
    /**
     ZIKRouteErrorActionFailed for ZIKViewRouter:
     
     @discussion
     1. Do performRoute when the source was dealloced or removed from view hierarchy.
     
     2. Do performOnDestination but the destination can perform the route type.
     
     3. Do removeRoute but the destination was poped/dismissed/removed/dealloced.
     
     4. Do removeRoute when a router is not performed yet.
     
     5. Do removeRoute when real routeType is not supported.
     */
};
