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
#import "ZIKClassCapabilities.h"

#if ZIK_HAS_UIKIT
@implementation UIView (ZIKViewRouter)
#else
@implementation NSView (ZIKViewRouter)
#endif
- (BOOL)zix_routed {
    NSNumber *result = objc_getAssociatedObject(self, @selector(zix_routed));
    return [result boolValue];
}
- (void)setZix_routed:(BOOL)routed {
    objc_setAssociatedObject(self, @selector(zix_routed), @(routed), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)zix_removing {
    NSNumber *result = objc_getAssociatedObject(self, @selector(zix_removing));
    return [result boolValue];
}
- (void)setZix_removing:(BOOL)removing {
    objc_setAssociatedObject(self, @selector(zix_removing), @(removing), OBJC_ASSOCIATION_RETAIN);
}

///https://stackoverflow.com/a/3732812/6380485
- (nullable XXViewController *)zix_firstAvailableUIViewController {
    return [self zix_firstAvailableViewController];
}
- (nullable XXViewController *)zix_firstAvailableViewController {
    id nextResponder = [self nextResponder];
    if ([nextResponder isKindOfClass:[XXViewController class]]) {
        return nextResponder;
    } else if ([nextResponder isKindOfClass:[XXView class]]) {
        return [nextResponder zix_firstAvailableViewController];
    } else {
        return nil;
    }
}

- (BOOL)zix_isRootView {
    return [[self nextResponder] isKindOfClass:[XXViewController class]];
}

- (BOOL)zix_isDuringNavigationTransitionBack {
#if ZIK_HAS_UIKIT
    XXViewController *viewController = [self zix_firstAvailableViewController];
    if (!viewController) {
        return NO;
    }
    UINavigationController *navigationController = viewController.navigationController;
    if (navigationController && navigationController.transitionCoordinator != nil) {
        NSArray<XXViewController *> *viewControllers = [navigationController viewControllers];
        if (viewControllers.count >= 2) {
            XXViewController *lastlastvc = viewControllers[viewControllers.count - 2];
            if (!lastlastvc.view.window) {
                return YES;
            }
        }
    }
#endif
    return NO;
}

- (nullable id)zix_routePerformer {
    NSAssert(self.nextResponder || [self isKindOfClass:[XXWindow class]] || [self window], @"View is not in any view hierarchy.");
    
    if ([self isKindOfClass:[XXWindow class]]) {
        XXViewController *performer;
        XXWindow *window = (XXWindow *)self;
#if ZIK_HAS_UIKIT
        performer = window.rootViewController;
#else
        if (@available(macOS 10.10, *)) {
            performer = window.contentViewController;
        }
        if (performer == nil) {
            XXResponder *nextResponder = [window.contentView nextResponder];
            if ([nextResponder isKindOfClass:[XXViewController class]]) {
                performer = (XXViewController *)nextResponder;
            }
        }
#endif
        if (![performer isKindOfClass:[XXApplication class]] &&
            !zix_classIsCustomClass([performer class])) {
            return nil;
        }
        return performer;
    }
    
    XXResponder *nextResponder = [self nextResponder];
    if ([nextResponder isKindOfClass:[XXViewController class]]) {
        if (zix_classIsCustomClass([nextResponder class])) {
            return nextResponder;
        }
        
        XXViewController *parent = [(XXViewController *)nextResponder parentViewController];
        NSAssert(parent, @"view controller should have parent. This View may be added to a system ViewController's view, you should use a custom ViewController and prepare this View inside the custom ViewController.");
        while (parent &&
               (!zix_classIsCustomClass([parent class]) ||
                [parent conformsToProtocol:@protocol(ZIKViewRouteContainer)]
                )) {
            parent = parent.parentViewController;
        }
        return parent;
    } else if ([nextResponder isKindOfClass:[XXView class]]) {
        return [(XXView *)nextResponder zix_routePerformer];
    } else {
        return nil;
    }
}

@end
