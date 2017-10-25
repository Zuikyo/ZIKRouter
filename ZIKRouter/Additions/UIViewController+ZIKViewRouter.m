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
    return [[ZIKPresentationState alloc] initFromViewController:self];;
}

//- (ZIKViewRouteType)zix_routeType {
//    ZIKViewRouteType routeType = ZIKViewRouteTypeCustom;
//    
//    UINavigationController *navigationController = self.navigationController;
//    if (navigationController) {
//        NSUInteger indexInStack = [navigationController.viewControllers indexOfObject:self];
//        if (indexInStack == 0) {
//            if (navigationController.parentViewController) {
//                if (navigationController.parentViewController != navigationController.splitViewController) {
//                    return ZIKViewRouteTypeAddAsChildViewController;
//                }
//            } else if (navigationController.presentingViewController) {
//                if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) {
//                    return ZIKViewRouteTypePresentModally;
//                }
//                if (self.modalPresentationStyle == UIModalPresentationPopover) {
//                    return ZIKViewRouteTypePresentAsPopover;
//                }
//                return ZIKViewRouteTypePresentModally;
//            }
//        } else if (indexInStack == NSNotFound) {//is child of a view controller in navigation stack
//            NSAssert(self.parentViewController != navigationController, @"logically, this view controller should be a child of a view controller in navigation stack");
//            
//            return ZIKViewRouteTypeAddAsChildViewController;
//        } else {//in navigation stack
//            return ZIKViewRouteTypePush;
//        }
//    }
//    
//    UIViewController *presentingViewController = self.presentingViewController;
//    if (presentingViewController) {
//        routeType = ZIKViewRouteTypePresentModally;
//        if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) {
//            return ZIKViewRouteTypePresentModally;
//        }
//        if (NSClassFromString(@"UIPopoverPresentationController")) {
//            if (self.modalPresentationStyle == UIModalPresentationPopover) {
//                routeType = ZIKViewRouteTypePresentAsPopover;
//            }
//        }
//        //iOS7上检测ZIKViewRouteTypePresentAsPopover需要用UIPopoverController *popover = objc_getAssociatedObject(destination, "zikrouter_popover")
//        return routeType;
//    }
//    
//    UISplitViewController *splitViewController = self.splitViewController;
//    if (splitViewController) {
//        NSUInteger index = [splitViewController.viewControllers indexOfObject:self];
//        if (index == 0) {
//            return ZIKViewRouteTypeShow;
//        } else if (index == 1) {
//            return ZIKViewRouteTypeShowDetail;
//        } else {
//            if (self.parentViewController != splitViewController &&
//                self.parentViewController != navigationController) {
//                return ZIKViewRouteTypeAddAsChildViewController;
//            }
//        }
//    }
//    
//    if (self.parentViewController) {
//        return ZIKViewRouteTypeAddAsChildViewController;
//    }
//    
//    return ZIKViewRouteTypeCustom;
//}

//+ (void)load {
//    ZIKRouter_replaceMethodWithMethod(self, @selector(presentViewController:animated:completion:),
//                            self, @selector(zix_presentViewController:animated:completion:));
//
//    ZIKRouter_replaceMethodWithMethod(self, @selector(presentModalViewController:animated:),
//                            self, @selector(zix_presentModalViewController:animated:));
//}
//
//- (void)zix_presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
//    [viewControllerToPresent zix_setRealPresentingViewController:self];
//    [self zix_presentViewController:viewControllerToPresent animated:flag completion:completion];
//}
//
//- (void)zix_presentModalViewController:(UIViewController *)modalViewController animated:(BOOL)animated {
//    [modalViewController zix_setRealPresentingViewController:self];
//    [self zix_presentModalViewController:modalViewController animated:animated];
//}
//
//- (nullable UIViewController *)zix_realPresentingViewController {
//    NSPointerArray *weakContainer = objc_getAssociatedObject(self, "zik_realPresentingViewController");
//    return [weakContainer pointerAtIndex:0];
//}
//
//- (void)zix_setRealPresentingViewController:(UIViewController *)vc {
//    NSPointerArray *weakContainer = [NSPointerArray weakObjectsPointerArray];
//    [weakContainer addPointer:(__bridge void * _Nullable)(vc)];
//    objc_setAssociatedObject(self, "zik_realPresentingViewController", weakContainer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//}

//- (nullable UIViewController *)zix_routeSource {
//    UINavigationController *navigationController = self.navigationController;
//    if (navigationController) {
//        NSUInteger indexInStack = [navigationController.viewControllers indexOfObject:self];
//        if (indexInStack == 0) {
//            return [navigationController zix_routeSource];
//        } else if (indexInStack == NSNotFound) {
//            NSAssert(self.parentViewController != navigationController, @"logically, this view controller should be a child of a view controller in navigation stack");
//
//            UIViewController *parent = self.parentViewController;
//            while (parent) {
//                if (![[parent class] zix_isSystemClass]) {
//                    return self.parentViewController;
//                } else {
//                    parent = parent.parentViewController;
//                }
//            }
//            return nil;
//        } else {
//            return [navigationController.viewControllers objectAtIndex:indexInStack - 1];
//        }
//    }
//
//    UIViewController *realPresentingViewController = [self zix_realPresentingViewController];
//    if (realPresentingViewController) {
//        NSAssert(![[realPresentingViewController class] zix_isSystemClass], @"presentingViewController should be a custom class");
//
//        return realPresentingViewController;
//    }
//
//
//    UISplitViewController *splitViewController = self.splitViewController;
//    if (splitViewController) {
//        NSUInteger index = [splitViewController.viewControllers indexOfObject:self];
//        if (index == 0) {
//            return nil;
//        } else if (index == 1) {
//            return nil;
//        } else {
//            if (self.parentViewController != self.splitViewController &&
//                self.parentViewController != self.navigationController) {
//                UIViewController *parent = self.parentViewController;
//                while (parent) {
//                    if (![[parent class] zix_isSystemClass]) {
//                        return self.parentViewController;
//                    } else {
//                        parent = parent.parentViewController;
//                    }
//                }
//                return nil;
//            }
//        }
//    }
//
//    if (self.parentViewController) {
//        UIViewController *parent = self.parentViewController;
//        while (parent) {
//            if (![[parent class] zix_isSystemClass]) {
//                return self.parentViewController;
//            } else {
//                parent = parent.parentViewController;
//            }
//        }
//        return nil;
//    }
//
//    return nil;
//}

@end
