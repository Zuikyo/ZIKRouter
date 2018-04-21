//
//  UIViewController+ZIKViewRouter.m
//  ZIKRouter
//
//  Created by zuik on 2017/5/31.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "UIViewController+ZIKViewRouter.h"
#import "UIView+ZIKViewRouter.h"
#import "ZIKPresentationState.h"
#import "ZIKRouterInternal.h"
#import <objc/runtime.h>

@implementation UIViewController (ZIKViewRouter)

- (BOOL)zix_routed {
    NSNumber *result = objc_getAssociatedObject(self, "zix_routed");
    return [result boolValue];
}

- (void)setZix_routed:(BOOL)routed {
    objc_setAssociatedObject(self, "zix_routed", @(routed), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)zix_removing {
    NSNumber *result = objc_getAssociatedObject(self, "zix_removing");
    return [result boolValue];
}

- (void)setZix_removing:(BOOL)removing {
    objc_setAssociatedObject(self, "zix_removing", @(removing), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)zix_isAppRootViewController {
    Class UIApplication = NSClassFromString(@"UIApplication");
    id sharedApplication = [UIApplication performSelector:@selector(sharedApplication)];
    id appDelegate = [sharedApplication performSelector:@selector(delegate)];
    UIWindow *window = [appDelegate performSelector:@selector(window)];
    UIViewController *rootViewController = window.rootViewController;
    if (rootViewController) {
        return rootViewController == self;
    }
    //Maybe in app extension
    id nextResponder = [self nextResponder];
    if ([nextResponder isKindOfClass:[UIWindow class]]) {
        if ([[nextResponder nextResponder] isKindOfClass:UIApplication]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)zix_isRootViewControllerInContainer {
    if (self.navigationController) {
        return self.navigationController.viewControllers.firstObject == self;
    } else if (self.tabBarController) {
        return [self.tabBarController.viewControllers containsObject:self];
    } else if (self.splitViewController) {
        return [self.splitViewController.viewControllers containsObject:self];
    }
    return NO;
}

- (ZIKPresentationState *)zix_presentationState {
    return [[ZIKPresentationState alloc] initFromViewController:self];
}

@end
