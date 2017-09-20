//
//  UIView+ZIKViewRouterPrivate.m
//  ZIKRouter
//
//  Created by zuik on 2017/9/18.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "UIView+ZIKViewRouterPrivate.h"
#import "ZIKViewRouter.h"
#import <objc/runtime.h>

@implementation UIView (ZIKViewRouterPrivate)

///Temporary bind auto created router to a UIView when it's not addSubView: by router. Reset to nil when view is removed.
- (__kindof ZIKViewRouter *)ZIK_destinationViewRouter {
    return objc_getAssociatedObject(self, "ZIK_destinationViewRouter");
}
- (void)setZIK_destinationViewRouter:(nullable ZIKViewRouter *)viewRouter {
    objc_setAssociatedObject(self, "ZIK_destinationViewRouter", viewRouter, OBJC_ASSOCIATION_RETAIN);
}
///Route type when view is routed from a router, will reset to nil when view is removed
- (nullable NSNumber *)ZIK_routeTypeFromRouter {
    NSNumber *result = objc_getAssociatedObject(self, "ZIK_routeTypeFromRouter");
    return result;
}
- (void)setZIK_routeTypeFromRouter:(nullable NSNumber *)routeType {
    NSParameterAssert(!routeType ||
                      [routeType integerValue] <= ZIKViewRouteTypeGetDestination);
    objc_setAssociatedObject(self, "ZIK_routeTypeFromRouter", routeType, OBJC_ASSOCIATION_RETAIN);
}

@end

