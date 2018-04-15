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
- (void)setZix_routed:(BOOL)routed;
- (void)setZix_removing:(BOOL)removing;
@end

@class ZIKViewRouter;
@interface UIViewController (ZIKViewRouterPrivate)
///Route type when view is routed from a router. Reset to nil when view is removed.
- (nullable NSNumber *)zix_routeTypeFromRouter;
- (void)setZix_routeTypeFromRouter:(nullable NSNumber *)routeType;
///Temporary bind auto created routers to a segue destination for routable views in destination. Reset to nil when segue is performed.
- (nullable NSArray<ZIKViewRouter *> *)zix_destinationViewRouters;
- (void)setZix_destinationViewRouters:(nullable NSArray<ZIKViewRouter *> *)viewRouters;
///Temporary bind a router to a UIViewController when performing segue from the router. Reset to nil when segue is performed.
- (__kindof ZIKViewRouter *)zix_sourceViewRouter;
- (void)setZix_sourceViewRouter:(nullable __kindof ZIKViewRouter *)viewRouter;
- (nullable Class)zix_currentClassCallingPrepareForSegue;
- (void)setZix_currentClassCallingPrepareForSegue:(nullable Class)vcClass;
- (UIViewController *)zix_parentMovingTo;
- (void)setZix_parentMovingTo:(nullable UIViewController *)parentMovingTo;
- (nullable UIViewController *)zix_parentRemovingFrom;
- (void)setZix_parentRemovingFrom:(nullable UIViewController *)parentRemovingFrom;
- (nullable id<UIViewControllerTransitionCoordinator>)zix_currentTransitionCoordinator;
@end

NS_ASSUME_NONNULL_END
