//
//  UIViewController+ZIKViewRouter.m
//  ZIKRouter
//
//  Created by zuik on 2017/5/31.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "UIViewController+ZIKViewRouter.h"
#import "UIView+ZIKViewRouter.h"
#import "ZIKPresentationState.h"
#import "ZIKRouter+Private.h"
#import <objc/runtime.h>

@implementation UIViewController (ZIKViewRouter)

- (BOOL)ZIK_routed {
    NSNumber *result = objc_getAssociatedObject(self, "ZIK_routed");
    return [result boolValue];
}

- (void)setZIK_routed:(BOOL)routed {
    objc_setAssociatedObject(self, "ZIK_routed", @(routed), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)ZIK_removing {
    NSNumber *result = objc_getAssociatedObject(self, "ZIK_removing");
    return [result boolValue];
}

- (void)setZIK_removing:(BOOL)removing {
    objc_setAssociatedObject(self, "ZIK_removing", @(removing), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)ZIK_isAppRootViewController {
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

- (BOOL)ZIK_isRootViewControllerInContainer {
    if (self.navigationController) {
        return self.navigationController.viewControllers.firstObject == self;
    } else if (self.tabBarController) {
        return [self.tabBarController.viewControllers containsObject:self];
    } else if (self.splitViewController) {
        return [self.splitViewController.viewControllers containsObject:self];
    }
    return NO;
}

- (ZIKPresentationState *)ZIK_presentationState {
    return [[ZIKPresentationState alloc] initFromViewController:self];;
}

//- (ZIKViewRouteType)ZIK_routeType {
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
//                            self, @selector(ZIK_presentViewController:animated:completion:));
//
//    ZIKRouter_replaceMethodWithMethod(self, @selector(presentModalViewController:animated:),
//                            self, @selector(ZIK_presentModalViewController:animated:));
//}
//
//- (void)ZIK_presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
//    [viewControllerToPresent ZIK_setRealPresentingViewController:self];
//    [self ZIK_presentViewController:viewControllerToPresent animated:flag completion:completion];
//}
//
//- (void)ZIK_presentModalViewController:(UIViewController *)modalViewController animated:(BOOL)animated {
//    [modalViewController ZIK_setRealPresentingViewController:self];
//    [self ZIK_presentModalViewController:modalViewController animated:animated];
//}
//
//- (nullable UIViewController *)ZIK_realPresentingViewController {
//    NSPointerArray *weakContainer = objc_getAssociatedObject(self, "zik_realPresentingViewController");
//    return [weakContainer pointerAtIndex:0];
//}
//
//- (void)ZIK_setRealPresentingViewController:(UIViewController *)vc {
//    NSPointerArray *weakContainer = [NSPointerArray weakObjectsPointerArray];
//    [weakContainer addPointer:(__bridge void * _Nullable)(vc)];
//    objc_setAssociatedObject(self, "zik_realPresentingViewController", weakContainer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//}

//- (nullable UIViewController *)ZIK_routeSource {
//    UINavigationController *navigationController = self.navigationController;
//    if (navigationController) {
//        NSUInteger indexInStack = [navigationController.viewControllers indexOfObject:self];
//        if (indexInStack == 0) {
//            return [navigationController ZIK_routeSource];
//        } else if (indexInStack == NSNotFound) {
//            NSAssert(self.parentViewController != navigationController, @"logically, this view controller should be a child of a view controller in navigation stack");
//
//            UIViewController *parent = self.parentViewController;
//            while (parent) {
//                if (![[parent class] ZIK_isSystemClass]) {
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
//    UIViewController *realPresentingViewController = [self ZIK_realPresentingViewController];
//    if (realPresentingViewController) {
//        NSAssert(![[realPresentingViewController class] ZIK_isSystemClass], @"presentingViewController should be a custom class");
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
//                    if (![[parent class] ZIK_isSystemClass]) {
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
//            if (![[parent class] ZIK_isSystemClass]) {
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
