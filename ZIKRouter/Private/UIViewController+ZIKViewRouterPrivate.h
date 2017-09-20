//
//  UIViewController+ZIKViewRouterPrivate.h
//  ZIKRouter
//
//  Created by zuik on 2017/9/18.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController ()
- (void)setZIK_routed:(BOOL)routed;
- (void)setZIK_removing:(BOOL)removing;
@end

@class ZIKViewRouter;
@interface UIViewController (ZIKViewRouterPrivate)
///Route type when view is routed from a router. Reset to nil when view is removed.
- (nullable NSNumber *)ZIK_routeTypeFromRouter;
- (void)setZIK_routeTypeFromRouter:(nullable NSNumber *)routeType;
///Temporary bind auto created routers to a segue destination for routable views in destination. Reset to nil when segue is performed.
- (nullable NSArray<ZIKViewRouter *> *)ZIK_destinationViewRouters;
- (void)setZIK_destinationViewRouters:(nullable NSArray<ZIKViewRouter *> *)viewRouters;
///Temporary bind a router to a UIViewController when performing segue from the router. Reset to nil when segue is performed.
- (__kindof ZIKViewRouter *)ZIK_sourceViewRouter;
- (void)setZIK_sourceViewRouter:(nullable __kindof ZIKViewRouter *)viewRouter;
- (nullable Class)ZIK_currentClassCallingPrepareForSegue;
- (void)setZIK_currentClassCallingPrepareForSegue:(nullable Class)vcClass;
- (UIViewController *)ZIK_parentMovingTo;
- (void)setZIK_parentMovingTo:(nullable UIViewController *)parentMovingTo;
- (nullable UIViewController *)ZIK_parentRemovingFrom;
- (void)setZIK_parentRemovingFrom:(nullable UIViewController *)parentRemovingFrom;
- (nullable id<UIViewControllerTransitionCoordinator>)ZIK_currentTransitionCoordinator;
@end

NS_ASSUME_NONNULL_END
