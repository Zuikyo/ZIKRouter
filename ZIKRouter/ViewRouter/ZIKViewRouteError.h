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

extern NSString *const kZIKViewRouteErrorDomain;

///Errors for callback in ZIKRouteErrorHandler and ZIKViewRouteGlobalErrorHandler
typedef NS_ENUM(NSInteger, ZIKViewRouteError) {
    ///Bad implementation in code. When adding a UIView or UIViewController conforms to ZIKRoutableView in xib or storyboard, and it need preparing, you have to implement -prepareDestinationFromExternal:configuration: in the view or view controller which added it. There will be an assert failure for debugging.
    ZIKViewRouteErrorInvalidPerformer,
    ///If you use ZIKViewRouter.toView() or ZIKViewRouter.toModule() to fetch router with protocol, the protocol must be declared. There will be an assert failure for debugging.
    ZIKViewRouteErrorInvalidProtocol,
    ///Configuration missed some required values, or some values were conflict. There will be an assert failure for debugging.
    ZIKViewRouteErrorInvalidConfiguration,
    ///This router doesn't support the route type you assigned. There will be an assert failure for debugging.
    ZIKViewRouteErrorUnsupportType,
    /**
     Unbalanced calls to begin/end appearance transitions for destination. This error occurs when you try and display a view controller before the current view controller is finished displaying. This may cause the UIViewController skips or messes up the order calling -viewWillAppear:, -viewDidAppear:, -viewWillDisAppear: and -viewDidDisappear:, and messes up the route state. There will be an assert failure for debugging.
     */
    ZIKViewRouteErrorUnbalancedTransition,
    /**
     1. Source can't perform action with corresponding route type, maybe it's missed or is wrong class, see ZIKViewRouteConfiguration.source. There will be an assert failure for debugging.
     
     2. Source is dealloced when perform route.
     
     3. Source is not in any navigation stack when perform push.
     
     4. Source already presented another view controller when perform present, can't do present now.
     
     5. Attempt to present destination on source whose view is not in the window hierarchy or not added to any superview.
     */
    ZIKViewRouteErrorInvalidSource,
    ///See containerWrapper
    ZIKViewRouteErrorInvalidContainer,
    /**
     Perform or remove route action failed
     @discussion
     1. Do performRoute when the source was dealloced or removed from view hierarchy.
     
     2. Do removeRoute but the destination was poped/dismissed/removed/dealloced.
     
     3. Do removeRoute when a router is not performed yet.
     
     4. Do removeRoute when real routeType is not supported.
     */
    ZIKViewRouteErrorActionFailed,
    ///An unwind segue was aborted because -[destinationViewController canPerformUnwindSegueAction:fromViewController:withSender:] return NO or can't perform segue.
    ZIKViewRouteErrorSegueNotPerformed,
    ///Another same route action is performing.
    ZIKViewRouteErrorOverRoute,
    ///Infinite recursion for performing route detected, see -prepareDestination:configuration: for more detail.
    ZIKViewRouteErrorInfiniteRecursion
};
