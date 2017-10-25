//
//  UIViewController+ZIKViewRouterPrivate.m
//  ZIKRouter
//
//  Created by zuik on 2017/9/18.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "UIViewController+ZIKViewRouterPrivate.h"
#import "ZIKViewRouter.h"
#import <objc/runtime.h>

@implementation UIViewController (ZIKViewRouterPrivate)

- (nullable NSNumber *)zix_routeTypeFromRouter {
    NSNumber *result = objc_getAssociatedObject(self, "zix_routeTypeFromRouter");
    return result;
}
- (void)setZix_routeTypeFromRouter:(nullable NSNumber *)routeType {
    NSParameterAssert(!routeType ||
                      [routeType integerValue] <= ZIKViewRouteTypeGetDestination);
    objc_setAssociatedObject(self, "zix_routeTypeFromRouter", routeType, OBJC_ASSOCIATION_RETAIN);
}
- (nullable NSArray<ZIKViewRouter *> *)zix_destinationViewRouters {
    return objc_getAssociatedObject(self, "zix_destinationViewRouters");
}
- (void)setZix_destinationViewRouters:(nullable NSArray<ZIKViewRouter *> *)viewRouters {
    NSParameterAssert(!viewRouters || [viewRouters isKindOfClass:[NSArray class]]);
    objc_setAssociatedObject(self, "zix_destinationViewRouters", viewRouters, OBJC_ASSOCIATION_RETAIN);
}
- (__kindof ZIKViewRouter *)zix_sourceViewRouter {
    return objc_getAssociatedObject(self, "zix_sourceViewRouter");
}
- (void)setZix_sourceViewRouter:(nullable __kindof ZIKViewRouter *)viewRouter {
    objc_setAssociatedObject(self, "zix_sourceViewRouter", viewRouter, OBJC_ASSOCIATION_RETAIN);
}
- (nullable Class)zix_currentClassCallingPrepareForSegue {
    return objc_getAssociatedObject(self, "zix_currentClassCallingPrepareForSegue");
}
- (void)setZix_currentClassCallingPrepareForSegue:(nullable Class)vcClass {
    objc_setAssociatedObject(self, "zix_currentClassCallingPrepareForSegue", vcClass, OBJC_ASSOCIATION_RETAIN);
}
- (UIViewController *)zix_parentMovingTo {
    UIViewController *(^weakContainer)(void) = objc_getAssociatedObject(self, "zix_parentMovingTo");
    if (weakContainer) {
        return weakContainer();
    }
    return nil;
}
- (void)setZix_parentMovingTo:(nullable UIViewController *)parentMovingTo {
    NSParameterAssert(!parentMovingTo || [parentMovingTo isKindOfClass:[UIViewController class]]);
    id object = nil;
    if (parentMovingTo) {
        __weak typeof(UIViewController *)weakParent = parentMovingTo;
        UIViewController *(^weakContainer)(void) = ^ {
            return weakParent;
        };
        object = weakContainer;
    }
    objc_setAssociatedObject(self, "zix_parentMovingTo", object, OBJC_ASSOCIATION_RETAIN);
}
- (nullable UIViewController *)zix_parentRemovingFrom {
    UIViewController *(^weakContainer)(void) = objc_getAssociatedObject(self, "zix_parentRemovingFrom");
    if (weakContainer) {
        return weakContainer();
    }
    return nil;
}
- (void)setZix_parentRemovingFrom:(nullable UIViewController *)parentRemovingFrom {
    NSParameterAssert(!parentRemovingFrom || [parentRemovingFrom isKindOfClass:[UIViewController class]]);
    id object;
    if (parentRemovingFrom) {
        __weak typeof(UIViewController *)weakParent = parentRemovingFrom;
        UIViewController *(^weakContainer)(void) = ^ {
            return weakParent;
        };
        object = weakContainer;
    }
    objc_setAssociatedObject(self, "zix_parentRemovingFrom", object, OBJC_ASSOCIATION_RETAIN);
}
- (nullable id<UIViewControllerTransitionCoordinator>)zix_currentTransitionCoordinator {
    id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.transitionCoordinator;
    if (!transitionCoordinator) {
        transitionCoordinator = self.navigationController.transitionCoordinator;
        if (!transitionCoordinator) {
            transitionCoordinator = self.presentingViewController.transitionCoordinator;
            if (!transitionCoordinator) {
                return [self.parentViewController zix_currentTransitionCoordinator];
            }
        }
    }
    return transitionCoordinator;
}

@end
