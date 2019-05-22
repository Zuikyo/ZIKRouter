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

#if ZIK_HAS_UIKIT
@implementation UIView (ZIKViewRouterPrivate)
#else
@implementation NSView (ZIKViewRouterPrivate)
#endif

///Temporary bind auto created router to an UIView when it's not addSubView: by router. Reset to nil when view is routed or removed.
- (__kindof ZIKViewRouter *)zix_destinationViewRouter {
    return objc_getAssociatedObject(self, @selector(zix_destinationViewRouter));
}
- (void)setZix_destinationViewRouter:(nullable ZIKViewRouter *)viewRouter {
    objc_setAssociatedObject(self, @selector(zix_destinationViewRouter), viewRouter, OBJC_ASSOCIATION_RETAIN);
}
///Route type when view is routed from a router, will reset to nil when view is routed or removed.
- (nullable NSNumber *)zix_routeTypeFromRouter {
    NSNumber *result = objc_getAssociatedObject(self, @selector(zix_routeTypeFromRouter));
    return result;
}
- (void)setZix_routeTypeFromRouter:(nullable NSNumber *)routeType {
    NSParameterAssert(!routeType ||
                      [routeType integerValue] <= ZIKViewRouteTypeMakeDestination);
    objc_setAssociatedObject(self, @selector(zix_routeTypeFromRouter), routeType, OBJC_ASSOCIATION_RETAIN);
}

@end

