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

#import "ZIKClassCapabilities.h"
#if ZIK_HAS_UIKIT
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

#if ZIK_HAS_UIKIT
@interface UIViewController ()
#else
@interface NSViewController ()
#endif
- (void)setZix_routed:(BOOL)routed;
- (void)setZix_removing:(BOOL)removing;
@end

@class ZIKViewRouter;
#if ZIK_HAS_UIKIT
@interface UIViewController (ZIKViewRouterPrivate)
#else
@interface NSViewController (ZIKViewRouterPrivate)
#endif
/// Route type when view is routed from a router. Reset to nil when view is removed.
- (nullable NSNumber *)zix_routeTypeFromRouter;
- (void)setZix_routeTypeFromRouter:(nullable NSNumber *)routeType;
/// Temporary bind auto created routers to a segue destination for routable views in destination. Reset to nil when segue is performed.
- (nullable NSArray<ZIKViewRouter *> *)zix_destinationViewRouters;
- (void)setZix_destinationViewRouters:(nullable NSArray<ZIKViewRouter *> *)viewRouters;
/// Temporary bind a router to a ViewController when performing segue from the router. Reset to nil when segue is performed.
- (nullable __kindof ZIKViewRouter *)zix_sourceViewRouter;
- (void)setZix_sourceViewRouter:(nullable __kindof ZIKViewRouter *)viewRouter;
- (nullable Class)zix_currentClassCallingPrepareForSegue;
- (void)setZix_currentClassCallingPrepareForSegue:(nullable Class)vcClass;
#if ZIK_HAS_UIKIT
- (nullable id<UIViewControllerTransitionCoordinator>)zix_currentTransitionCoordinator;
@property (nonatomic, weak, nullable) XXViewController *zix_parentMovingTo;
@property (nonatomic, weak, nullable) XXViewController *zix_parentRemovingFrom;
#else
@property (nonatomic, weak, nullable) id zix_parentMovingTo;
@property (nonatomic, weak, nullable) id zix_parentRemovingFrom;
#endif
@end

#if !ZIK_HAS_UIKIT
@interface NSWindowController (ZIKViewRouterPrivate)
/// Temporary bind auto created routers to a segue destination for routable views in destination. Reset to nil when segue is performed.
- (nullable NSArray<ZIKViewRouter *> *)zix_destinationViewRouters;
- (void)setZix_destinationViewRouters:(nullable NSArray<ZIKViewRouter *> *)viewRouters;
/// Temporary bind a router to a ViewController when performing segue from the router. Reset to nil when segue is performed.
- (nullable __kindof ZIKViewRouter *)zix_sourceViewRouter;
- (void)setZix_sourceViewRouter:(nullable __kindof ZIKViewRouter *)viewRouter;
- (nullable Class)zix_currentClassCallingPrepareForSegue;
- (void)setZix_currentClassCallingPrepareForSegue:(nullable Class)vcClass;
@end
#endif

NS_ASSUME_NONNULL_END
