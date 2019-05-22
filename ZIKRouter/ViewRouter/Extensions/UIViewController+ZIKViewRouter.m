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
#import "ZIKClassCapabilities.h"

#if ZIK_HAS_UIKIT
@implementation UIViewController (ZIKViewRouter)
#else
@implementation NSViewController (ZIKViewRouter)
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

#if ZIK_HAS_UIKIT

- (BOOL)zix_isAppRootViewController {
    Class XXApplication = NSClassFromString(@"UIApplication");
    id sharedApplication = [XXApplication performSelector:@selector(sharedApplication)];
    id appDelegate = [sharedApplication performSelector:@selector(delegate)];
    XXWindow *window = [appDelegate performSelector:@selector(window)];
    XXViewController *rootViewController = window.rootViewController;
    if (rootViewController) {
        return rootViewController == self;
    }
    //Maybe in app extension
    id nextResponder = [self nextResponder];
    if ([nextResponder isKindOfClass:[XXWindow class]]) {
        if ([[nextResponder nextResponder] isKindOfClass:XXApplication]) {
            return YES;
        }
    }
    return NO;
}

#else

- (BOOL)zix_isAppRootViewController {
    NSArray<NSWindow *> *windows = [NSApplication sharedApplication].windows;
    for (NSWindow *window in windows) {
        XXResponder *rootViewController;
        if (@available(macOS 10.10, *)) {
            rootViewController = window.contentViewController;
        } else {
            rootViewController = [window.contentView nextResponder];
        }
        if (rootViewController && rootViewController == self) {
            return YES;
        }
    }
    return NO;
}

#endif

#if ZIK_HAS_UIKIT
- (ZIKPresentationState *)zix_presentationState {
    return [[ZIKPresentationState alloc] initFromViewController:self];
}
#endif

@end
