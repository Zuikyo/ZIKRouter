//
//  UIView+ZIKViewRouter.m
//  ZIKRouter
//
//  Created by zuik on 2017/5/31.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "UIView+ZIKViewRouter.h"
#import "UIViewController+ZIKViewRouter.h"
#import <objc/runtime.h>
#import "ZIKRouterRuntime.h"

@implementation UIView (ZIKViewRouter)

- (BOOL)zix_routed {
    NSNumber *result = objc_getAssociatedObject(self, "zix_routed");
    return [result boolValue];
}
- (void)setZix_routed:(BOOL)routed {
    objc_setAssociatedObject(self, "zix_routed", @(routed), OBJC_ASSOCIATION_RETAIN);
}

///https://stackoverflow.com/a/3732812/6380485
- (nullable UIViewController *)zix_firstAvailableUIViewController {
    id nextResponder = [self nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        return nextResponder;
    } else if ([nextResponder isKindOfClass:[UIView class]]) {
        return [nextResponder zix_firstAvailableUIViewController];
    } else {
        return nil;
    }
}

- (nullable id)zix_routePerformer {
    NSAssert(self.nextResponder || [self isKindOfClass:[UIWindow class]], @"View is not in any view hierarchy.");
    
    if ([self isKindOfClass:[UIWindow class]]) {
        UIViewController *performer = [(UIWindow *)self rootViewController];
        if (![performer isKindOfClass:[UIApplication class]] &&
            !ZIKRouter_classIsCustomClass([performer class])) {
            return nil;
        }
        return performer;
    }
    
    UIResponder *nextResponder = [self nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        if (ZIKRouter_classIsCustomClass([nextResponder class])) {
            return nextResponder;
        }
        
        UIViewController *parent = [(UIViewController *)nextResponder parentViewController];
        NSAssert(parent, @"view controller should have parent. This UIView may be added to a system UIViewController's view, you should use a custom UIViewController and prepare this UIView inside the custom UIViewController.");
        while (parent &&
               (!ZIKRouter_classIsCustomClass([parent class]) ||
               [parent isKindOfClass:[UITabBarController class]] ||
               [parent isKindOfClass:[UINavigationController class]] ||
               [parent isKindOfClass:[UISplitViewController class]])) {
            parent = parent.parentViewController;
        }
        return parent;
    } else if ([nextResponder isKindOfClass:[UIView class]]) {
        return [(UIView *)nextResponder zix_routePerformer];
    } else {
        return nil;
    }
}

@end
