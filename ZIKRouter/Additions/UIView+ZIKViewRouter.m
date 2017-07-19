//
//  UIView+ZIKViewRouter.m
//  ZIKViperDemo
//
//  Created by zuik on 2017/5/31.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "UIView+ZIKViewRouter.h"
#import "UIViewController+ZIKViewRouter.h"
#import <objc/runtime.h>

BOOL ZIKClassIsCustomClass(Class class) {
    NSCParameterAssert(class);
    if (!class) {
        return NO;
    }
    static NSString *mainBundlePath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mainBundlePath = [[NSBundle mainBundle] bundlePath];
    });
    if ([[[NSBundle bundleForClass:class] bundlePath] isEqualToString:mainBundlePath]) {
        return YES;
    }
    return NO;
}

@implementation UIView (ZIKViewRouter)

- (BOOL)ZIK_routed {
    NSNumber *result = objc_getAssociatedObject(self, "ZIK_routed");
    return [result boolValue];
}
- (void)setZIK_routed:(BOOL)routed {
    objc_setAssociatedObject(self, "ZIK_routed", @(routed), OBJC_ASSOCIATION_RETAIN);
}

///https://stackoverflow.com/a/3732812/6380485
- (nullable UIViewController *)ZIK_firstAvailableUIViewController {
    id nextResponder = [self nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        return nextResponder;
    } else if ([nextResponder isKindOfClass:[UIView class]]) {
        return [nextResponder ZIK_firstAvailableUIViewController];
    } else {
        return nil;
    }
}

- (nullable id)ZIK_routePerformer {
    NSAssert(self.nextResponder || [self isKindOfClass:[UIWindow class]], @"View is not in any view hierarchy.");
    
    if ([self isKindOfClass:[UIWindow class]]) {
        UIViewController *performer = [(UIWindow *)self rootViewController];
        if (![performer isKindOfClass:[UIApplication class]] &&
            !ZIKClassIsCustomClass([performer class])) {
            return nil;
        }
        return performer;
    }
    
    UIResponder *nextResponder = [self nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        if (ZIKClassIsCustomClass([nextResponder class])) {
            return nextResponder;
        }
        
        UIViewController *parent = [(UIViewController *)nextResponder parentViewController];
        NSAssert(parent, @"view controller should have parent");
        while (parent &&
               (!ZIKClassIsCustomClass([parent class]) ||
               [parent isKindOfClass:[UITabBarController class]] ||
               [parent isKindOfClass:[UINavigationController class]] ||
               [parent isKindOfClass:[UISplitViewController class]])) {
            parent = parent.parentViewController;
        }
        return parent;
    } else if ([nextResponder isKindOfClass:[UIView class]]) {
        return [(UIView *)nextResponder ZIK_routePerformer];
    } else {
        return nil;
    }
}

@end
