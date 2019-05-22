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
#import "ZIKClassCapabilities.h"
#import <objc/runtime.h>

#if ZIK_HAS_UIKIT
@implementation UIViewController (ZIKViewRouterPrivate)
#else
@implementation NSViewController (ZIKViewRouterPrivate)
#endif
- (nullable NSNumber *)zix_routeTypeFromRouter {
    NSNumber *result = objc_getAssociatedObject(self, @selector(zix_routeTypeFromRouter));
    return result;
}
- (void)setZix_routeTypeFromRouter:(nullable NSNumber *)routeType {
    NSParameterAssert(!routeType ||
                      [routeType integerValue] <= ZIKViewRouteTypeMakeDestination);
    objc_setAssociatedObject(self, @selector(zix_routeTypeFromRouter), routeType, OBJC_ASSOCIATION_RETAIN);
}
- (nullable NSArray<ZIKViewRouter *> *)zix_destinationViewRouters {
    return objc_getAssociatedObject(self, @selector(zix_destinationViewRouters));
}
- (void)setZix_destinationViewRouters:(nullable NSArray<ZIKViewRouter *> *)viewRouters {
    NSParameterAssert(!viewRouters || [viewRouters isKindOfClass:[NSArray class]]);
    objc_setAssociatedObject(self, @selector(zix_destinationViewRouters), viewRouters, OBJC_ASSOCIATION_RETAIN);
}
- (__kindof ZIKViewRouter *)zix_sourceViewRouter {
    return objc_getAssociatedObject(self, @selector(zix_sourceViewRouter));
}
- (void)setZix_sourceViewRouter:(nullable __kindof ZIKViewRouter *)viewRouter {
    objc_setAssociatedObject(self, @selector(zix_sourceViewRouter), viewRouter, OBJC_ASSOCIATION_RETAIN);
}
- (nullable Class)zix_currentClassCallingPrepareForSegue {
    return objc_getAssociatedObject(self, @selector(zix_currentClassCallingPrepareForSegue));
}
- (void)setZix_currentClassCallingPrepareForSegue:(nullable Class)vcClass {
    objc_setAssociatedObject(self, @selector(zix_currentClassCallingPrepareForSegue), vcClass, OBJC_ASSOCIATION_RETAIN);
}
- (nullable XXViewController *)zix_parentMovingTo {
    XXViewController *(^weakContainer)(void) = objc_getAssociatedObject(self, @selector(zix_parentMovingTo));
    if (weakContainer) {
        return weakContainer();
    }
    return nil;
}
- (void)setZix_parentMovingTo:(nullable XXViewController *)parentMovingTo {
    NSParameterAssert(!parentMovingTo
                      || [parentMovingTo isKindOfClass:[XXViewController class]]
#if !ZIK_HAS_UIKIT
                      || [parentMovingTo isKindOfClass:[NSWindowController class]]
                      || [parentMovingTo isKindOfClass:[NSWindow class]]
#endif
                      );
    id object = nil;
    if (parentMovingTo) {
        __weak typeof(XXViewController *)weakParent = parentMovingTo;
        XXViewController *(^weakContainer)(void) = ^ {
            return weakParent;
        };
        object = weakContainer;
    }
    objc_setAssociatedObject(self, @selector(zix_parentMovingTo), object, OBJC_ASSOCIATION_RETAIN);
}
- (nullable XXViewController *)zix_parentRemovingFrom {
    XXViewController *(^weakContainer)(void) = objc_getAssociatedObject(self, @selector(zix_parentRemovingFrom));
    if (weakContainer) {
        return weakContainer();
    }
    return nil;
}
- (void)setZix_parentRemovingFrom:(nullable XXViewController *)parentRemovingFrom {
    NSParameterAssert(!parentRemovingFrom
                      || [parentRemovingFrom isKindOfClass:[XXViewController class]]
#if !ZIK_HAS_UIKIT
                      || [parentRemovingFrom isKindOfClass:[NSWindowController class]]
                      || [parentRemovingFrom isKindOfClass:[NSWindow class]]
#endif
                      );
    id object;
    if (parentRemovingFrom) {
        __weak typeof(XXViewController *)weakParent = parentRemovingFrom;
        XXViewController *(^weakContainer)(void) = ^ {
            return weakParent;
        };
        object = weakContainer;
    }
    objc_setAssociatedObject(self, @selector(zix_parentRemovingFrom), object, OBJC_ASSOCIATION_RETAIN);
}

#if ZIK_HAS_UIKIT
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
#endif

@end

#if !ZIK_HAS_UIKIT
@implementation NSWindowController (ZIKViewRouterPrivate)

- (nullable NSArray<ZIKViewRouter *> *)zix_destinationViewRouters {
    return objc_getAssociatedObject(self, @selector(zix_destinationViewRouters));
}
- (void)setZix_destinationViewRouters:(nullable NSArray<ZIKViewRouter *> *)viewRouters {
    NSParameterAssert(!viewRouters || [viewRouters isKindOfClass:[NSArray class]]);
    objc_setAssociatedObject(self, @selector(zix_destinationViewRouters), viewRouters, OBJC_ASSOCIATION_RETAIN);
}
- (__kindof ZIKViewRouter *)zix_sourceViewRouter {
    return objc_getAssociatedObject(self, @selector(zix_sourceViewRouter));
}
- (void)setZix_sourceViewRouter:(nullable __kindof ZIKViewRouter *)viewRouter {
    objc_setAssociatedObject(self, @selector(zix_sourceViewRouter), viewRouter, OBJC_ASSOCIATION_RETAIN);
}
- (nullable Class)zix_currentClassCallingPrepareForSegue {
    return objc_getAssociatedObject(self, @selector(zix_currentClassCallingPrepareForSegue));
}
- (void)setZix_currentClassCallingPrepareForSegue:(nullable Class)vcClass {
    objc_setAssociatedObject(self, @selector(zix_currentClassCallingPrepareForSegue), vcClass, OBJC_ASSOCIATION_RETAIN);
}

@end
#endif
