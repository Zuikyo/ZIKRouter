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

- (nullable NSNumber *)ZIK_routeTypeFromRouter {
    NSNumber *result = objc_getAssociatedObject(self, "ZIK_routeTypeFromRouter");
    return result;
}
- (void)setZIK_routeTypeFromRouter:(nullable NSNumber *)routeType {
    NSParameterAssert(!routeType ||
                      [routeType integerValue] <= ZIKViewRouteTypeGetDestination);
    objc_setAssociatedObject(self, "ZIK_routeTypeFromRouter", routeType, OBJC_ASSOCIATION_RETAIN);
}
- (nullable NSArray<ZIKViewRouter *> *)ZIK_destinationViewRouters {
    return objc_getAssociatedObject(self, "ZIK_destinationViewRouters");
}
- (void)setZIK_destinationViewRouters:(nullable NSArray<ZIKViewRouter *> *)viewRouters {
    NSParameterAssert(!viewRouters || [viewRouters isKindOfClass:[NSArray class]]);
    objc_setAssociatedObject(self, "ZIK_destinationViewRouters", viewRouters, OBJC_ASSOCIATION_RETAIN);
}
- (__kindof ZIKViewRouter *)ZIK_sourceViewRouter {
    return objc_getAssociatedObject(self, "ZIK_sourceViewRouter");
}
- (void)setZIK_sourceViewRouter:(nullable __kindof ZIKViewRouter *)viewRouter {
    objc_setAssociatedObject(self, "ZIK_sourceViewRouter", viewRouter, OBJC_ASSOCIATION_RETAIN);
}
- (nullable Class)ZIK_currentClassCallingPrepareForSegue {
    return objc_getAssociatedObject(self, "ZIK_CurrentClassCallingPrepareForSegue");
}
- (void)setZIK_currentClassCallingPrepareForSegue:(nullable Class)vcClass {
    objc_setAssociatedObject(self, "ZIK_CurrentClassCallingPrepareForSegue", vcClass, OBJC_ASSOCIATION_RETAIN);
}
- (UIViewController *)ZIK_parentMovingTo {
    UIViewController *(^weakContainer)(void) = objc_getAssociatedObject(self, "ZIK_parentMovingTo");
    if (weakContainer) {
        return weakContainer();
    }
    return nil;
}
- (void)setZIK_parentMovingTo:(nullable UIViewController *)parentMovingTo {
    NSParameterAssert(!parentMovingTo || [parentMovingTo isKindOfClass:[UIViewController class]]);
    id object = nil;
    if (parentMovingTo) {
        __weak typeof(UIViewController *)weakParent = parentMovingTo;
        UIViewController *(^weakContainer)(void) = ^ {
            return weakParent;
        };
        object = weakContainer;
    }
    objc_setAssociatedObject(self, "ZIK_parentMovingTo", object, OBJC_ASSOCIATION_RETAIN);
}
- (nullable UIViewController *)ZIK_parentRemovingFrom {
    UIViewController *(^weakContainer)(void) = objc_getAssociatedObject(self, "ZIK_parentRemovingFrom");
    if (weakContainer) {
        return weakContainer();
    }
    return nil;
}
- (void)setZIK_parentRemovingFrom:(nullable UIViewController *)parentRemovingFrom {
    NSParameterAssert(!parentRemovingFrom || [parentRemovingFrom isKindOfClass:[UIViewController class]]);
    id object;
    if (parentRemovingFrom) {
        __weak typeof(UIViewController *)weakParent = parentRemovingFrom;
        UIViewController *(^weakContainer)(void) = ^ {
            return weakParent;
        };
        object = weakContainer;
    }
    objc_setAssociatedObject(self, "ZIK_parentRemovingFrom", object, OBJC_ASSOCIATION_RETAIN);
}
- (nullable id<UIViewControllerTransitionCoordinator>)ZIK_currentTransitionCoordinator {
    id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.transitionCoordinator;
    if (!transitionCoordinator) {
        transitionCoordinator = self.navigationController.transitionCoordinator;
        if (!transitionCoordinator) {
            transitionCoordinator = self.presentingViewController.transitionCoordinator;
            if (!transitionCoordinator) {
                return [self.parentViewController ZIK_currentTransitionCoordinator];
            }
        }
    }
    return transitionCoordinator;
}

@end
