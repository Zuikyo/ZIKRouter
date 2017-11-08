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

#import "ZIKViewRouter.h"

NS_ASSUME_NONNULL_BEGIN

///Internal methods for subclass. Use these methods when implementing your custom route.
@interface ZIKViewRouter ()
@property (nonatomic, readonly, copy) __kindof ZIKViewRouteConfiguration *original_configuration;
@property (nonatomic, readonly, copy) __kindof ZIKViewRemoveConfiguration *original_removeConfiguration;

///Maintain the route state for custom route.
///Call it when route will perform.
- (void)beginPerformRoute;
///Call it when route is successfully performed.
- (void)endPerformRouteWithSuccess;
///Call it when route perform failed.
- (void)endPerformRouteWithError:(NSError *)error;

///If your custom route type is performing a segue, use this to perform the segue, don't need to use -beginPerformRoute and -endPerformRouteWithSuccess. `Source` is the view controller to perform the segue.
- (void)_performSegueWithIdentifier:(NSString *)identifier fromSource:(UIViewController *)source sender:(nullable id)sender;

///Call it when route will remove.
- (void)beginRemoveRouteFromSource:(id)source;
///Call it when route is successfully removed.
- (void)endRemoveRouteWithSuccessOnDestination:(id)destination fromSource:(id)source;
///Call it when route remove failed.
- (void)endRemoveRouteWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
