//
//  ZIKPresentationState.m
//  ZIKRouter
//
//  Created by zuik on 2017/6/19.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKPresentationState.h"

#if ZIK_HAS_UIKIT
@interface ZIKPresentationState ()
@property (nonatomic, strong, nullable) NSNumber *viewController;
@property (nonatomic, strong, nullable) NSNumber *presentingViewController;
@property (nonatomic, assign) BOOL isModalPresentationPopover;
@property (nonatomic, strong, nullable) NSNumber *navigationController;
@property (nonatomic, strong, nullable) NSArray<NSNumber *> *navigationViewControllers;
@property (nonatomic, strong, nullable) ZIKPresentationState *navigationControllerState;

@property (nonatomic, strong, nullable) NSNumber *splitController;
@property (nonatomic, strong, nullable) NSArray<NSNumber *> *splitViewControllers;
@property (nonatomic, strong, nullable) NSNumber *parentViewController;
@property (nonatomic, assign) BOOL isViewLoaded;
@end

@implementation ZIKPresentationState

- (instancetype)initFromViewController:(UIViewController *)viewController {
    NSAssert([NSThread isMainThread], @"ZIKPresentationState must be created in main thread.");
    
    if (self = [super init]) {
        if (viewController) {
            _viewController = [NSNumber numberWithInteger:(NSInteger)viewController];
        }
        if (viewController.presentingViewController) {
            _presentingViewController = [NSNumber numberWithInteger:(NSInteger)viewController.presentingViewController];
#ifdef __IPHONE_11_0
            if (@available(iOS 8.0, *)) {
#else
            if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
#endif
#if !TARGET_OS_TV
                if (viewController.modalPresentationStyle == UIModalPresentationPopover) {
                    _isModalPresentationPopover = YES;
                }
#endif
            }
        }
        
        UINavigationController *navigationController = viewController.navigationController;
        if (navigationController) {
            _navigationController = [NSNumber numberWithInteger:(NSInteger)navigationController];;
            
            NSMutableArray<NSNumber *> *viewControllers = [NSMutableArray array];
            for (UIViewController *vc in navigationController.viewControllers) {
                [viewControllers addObject:[NSNumber numberWithInteger:(NSInteger)vc]];
            }
            _navigationViewControllers = viewControllers;
            _navigationControllerState = [[ZIKPresentationState alloc] initFromViewController:navigationController];
        }
        
        UISplitViewController *splitViewController = viewController.splitViewController;
        if (splitViewController) {
            _splitController = [NSNumber numberWithInteger:(NSInteger)splitViewController];;
            
            NSMutableArray<NSNumber *> *viewControllers = [NSMutableArray array];
            for (UIViewController *vc in splitViewController.viewControllers) {
                [viewControllers addObject:[NSNumber numberWithInteger:(NSInteger)vc]];
            }
            _splitViewControllers = viewControllers;
        }
        
        UIViewController *parentViewController = viewController.parentViewController;
        if (parentViewController) {
            _parentViewController = [NSNumber numberWithInteger:(NSInteger)parentViewController];
        }
        
        _isViewLoaded = viewController.isViewLoaded;
    }
    return self;
}

+ (ZIKViewRouteDetailType)detailRouteTypeFromStateBeforeRoute:(ZIKPresentationState *)before stateAfterRoute:(ZIKPresentationState *)after {
    NSAssert([before.viewController isEqual:after.viewController], @"Analyze route type from before state and after state must created from same view controller !");
    
    if (![before.viewController isEqual:after.viewController]) {
        return ZIKViewRouteDetailTypeCustom;
    }
    NSNumber *viewController = before.viewController;
    
    NSNumber *navBefore = before.navigationController;
    NSNumber *navAfter = after.navigationController;
    NSArray<NSNumber *> *navigationViewControllersBefore = before.navigationViewControllers;
    NSArray<NSNumber *> *navigationViewControllersAfter = after.navigationViewControllers;
    
    NSNumber *parentViewControllerBefore = before.parentViewController;
    NSNumber *parentViewControllerAfter = after.parentViewController;
    
    NSNumber *splitBefore = before.splitController;
    NSNumber *splitAfter = after.splitController;
    NSArray<NSNumber *> *splitViewControllersBefore = before.splitViewControllers;
    NSArray<NSNumber *> *splitViewControllersAfter = after.splitViewControllers;
    
    //check navigation
    if (!navBefore && navAfter) {
        NSAssert(parentViewControllerAfter, @"if a view controller has navigationController, it should have a parent");
        NSAssert(!navigationViewControllersBefore, nil);
        NSAssert(navigationViewControllersAfter,nil);
        
        NSUInteger indexInStack = [navigationViewControllersAfter indexOfObject:viewController];
        if (indexInStack == 0) {//is root of navigationController
            NSAssert([parentViewControllerAfter isEqual:navAfter], @"UINavigationController's rootViewController's parentViewController should be it self.");
            
            ZIKPresentationState *navigationState = after.navigationControllerState;
            if (navigationState.parentViewController) {
                if (![navigationState.parentViewController isEqual:navigationState.splitController]) {//the navigationController was added to a parent
                    if (![parentViewControllerBefore isEqual:parentViewControllerAfter]) {
                        if (!parentViewControllerBefore) {
                            return ZIKViewRouteDetailTypeAddAsChildViewController;
                        }
                        return ZIKViewRouteDetailTypeChangeParentViewController;
                    }
                }
            } else if (navigationState.presentingViewController) {//the navigationController was presented
                if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) {
                    return ZIKViewRouteDetailTypePresentModally;
                }
                if (navigationState.isModalPresentationPopover) {
                    return ZIKViewRouteDetailTypePresentAsPopover;
                }
                return ZIKViewRouteDetailTypePresentModally;
            }
        } else if (indexInStack == NSNotFound) {//is child of a view controller in navigation stack
            NSAssert(parentViewControllerAfter, @"logically, this view controller should be a child of a view controller in navigation stack");
            
            if (!parentViewControllerBefore) {
                return ZIKViewRouteDetailTypeAddAsChildViewController;
            }
            if ([parentViewControllerBefore isEqual:parentViewControllerAfter]) {
                return ZIKViewRouteDetailTypeParentPushed;
            }
            return ZIKViewRouteDetailTypeChangeParentViewController;
        } else {//in navigation stack
            return ZIKViewRouteDetailTypePush;
        }
    } else if (navBefore && navAfter) {
        NSAssert(navigationViewControllersBefore, nil);
        NSAssert(navigationViewControllersAfter,nil);
        NSAssert(parentViewControllerBefore, @"if a view controller has navigationController, it should have a parent");
        NSAssert(parentViewControllerAfter, @"if a view controller has navigationController, it should have a parent");
        
        if (![navBefore isEqual:navAfter]) {//navigationController was changed
            if (![parentViewControllerBefore isEqual:parentViewControllerAfter]) {//parent was changed
                if ([parentViewControllerBefore isEqual:navBefore] &&
                    [parentViewControllerAfter isEqual:navAfter]) {//this view controller changed navigationController
                    return ZIKViewRouteDetailTypeChangeNavigationController;
                }
                return ZIKViewRouteDetailTypeChangeParentViewController;//removed from navigation stack or parent in a navigation stack, then pushed into another navigation stack or added to a parent in another navigation stack
            } else {
                return ZIKViewRouteDetailTypeParentChangeNavigationController;//its parent changed navigationController
            }
        }
        
        if ([navigationViewControllersBefore containsObject:viewController] &&
            [navigationViewControllersAfter containsObject:viewController]) {//still in the same navigationController
            NSAssert([navBefore isEqual:parentViewControllerBefore], @"UINavigationController's viewControllers' parent should be the UINavigationController");
            NSAssert([navAfter isEqual:parentViewControllerAfter], @"UINavigationController's viewControllers' parent should be the UINavigationController");
            
            NSUInteger indexInBefore = [navigationViewControllersBefore indexOfObject:viewController];
            NSUInteger indexInAfter = [navigationViewControllersAfter indexOfObject:viewController];
            if (indexInBefore != indexInAfter) {
                return ZIKViewRouteDetailTypeChangeOrderInNavigationStack;
            }
            if (navigationViewControllersBefore.count > navigationViewControllersAfter.count) {
                return ZIKViewRouteDetailTypeNavigationPopOthers;
            } else if (navigationViewControllersBefore.count < navigationViewControllersAfter.count) {
                return ZIKViewRouteDetailTypeNavigationPushOthers;
            } else if (![before.navigationControllerState isEqual:after.navigationControllerState]) {//its navigationController changed presentation
                return [[self class] detailRouteTypeFromStateBeforeRoute:before.navigationControllerState stateAfterRoute:after.navigationControllerState];
            }
        } else if ([navigationViewControllersBefore containsObject:viewController] &&
                   ![navigationViewControllersAfter containsObject:viewController]) {//before:in navigation stack, after:added to a parent in a  navigation stack
            NSAssert([navBefore isEqual:parentViewControllerBefore], @"UINavigationController's viewControllers' parent should be the UINavigationController");
            NSAssert(![navAfter isEqual:parentViewControllerAfter], @"If a view controller is not in its UINavigationController's viewControllers, it should be in child of a vc in those viewControllers");
            NSAssert(![parentViewControllerBefore isEqual:parentViewControllerAfter], @"View controller was removed from its navigation stack, so its parent should be different");
            
            return ZIKViewRouteDetailTypeChangeParentViewController;//removed from navigation stack, then  added to a parent in same navigation stack
        } else if (![navigationViewControllersBefore containsObject:viewController] &&
                   [navigationViewControllersAfter containsObject:viewController]) {//before:child of a parent in a navigation stack, after: pushed in same navigation stack
            NSAssert(![navBefore isEqual:parentViewControllerBefore], @"If a view controller is not in its UINavigationController's viewControllers, it should be in child of a vc in those viewControllers");
            NSAssert([navAfter isEqual:parentViewControllerAfter], @"UINavigationController's viewControllers' parent should be the UINavigationController");
            NSAssert(![parentViewControllerBefore isEqual:parentViewControllerAfter], @"View controller was pushed into navigation stack, so its parent should be different");
            
            return ZIKViewRouteDetailTypeChangeParentViewController;
        }
    } else if (navBefore && !navAfter) {
        NSAssert(navigationViewControllersBefore, nil);
        NSAssert(!navigationViewControllersAfter,nil);
        
        if ([navigationViewControllersBefore containsObject:viewController]) {
            return ZIKViewRouteDetailTypeRemoveFromNavigationStack;
        }
    }
    
    ///check present style
    NSNumber *presentingBefore = before.presentingViewController;
    NSNumber *presentingAfter = after.presentingViewController;
    if (!presentingBefore && presentingAfter) {//before: not presented, after: be presented
        if (after.isModalPresentationPopover) {
            return ZIKViewRouteDetailTypePresentAsPopover;
        }
        return ZIKViewRouteDetailTypePresentModally;
    } else if (presentingBefore && !presentingAfter) {
        return ZIKViewRouteDetailTypeDismissed;
    }
    
    //check split
    if (splitBefore && splitAfter) {
        NSAssert(splitViewControllersBefore, nil);
        NSAssert(splitViewControllersAfter, nil);
        
        NSUInteger indexInBefore = [splitViewControllersBefore indexOfObject:viewController];
        NSUInteger indexInAfter = [splitViewControllersAfter indexOfObject:viewController];
        if (indexInBefore != indexInAfter) {
            return ZIKViewRouteDetailTypeCustom;
        }
    } else if (!splitBefore && splitAfter) {
        NSAssert(!splitViewControllersBefore, nil);
        NSAssert(splitViewControllersAfter, nil);
        
        NSUInteger index = [splitViewControllersAfter indexOfObject:viewController];
        if (index == 0) {
            return ZIKViewRouteDetailTypeBecomeSplitMaster;
        } else if (index == 1) {
            return ZIKViewRouteDetailTypeBecomeSplitDetail;
        } else {
            NSAssert(after.parentViewController, @"view controller should be a child of a view controller in master/detail");
            
            if ([before.parentViewController isEqual:after.parentViewController]) {//parent is same, but parent was added into a split
                return ZIKViewRouteDetailTypeParentChangeSplitController;
            } else if (!before.parentViewController) {//added as a child of a view controller in master/detail
                return ZIKViewRouteDetailTypeAddAsChildViewController;
            }
        }
    } else if (splitBefore && !splitAfter) {
        NSAssert(splitViewControllersBefore, nil);
        NSAssert(!splitViewControllersAfter, nil);
        
        NSUInteger index = [splitViewControllersAfter indexOfObject:viewController];
        if (index == 0) {
            return ZIKViewRouteDetailTypeRemoveAsSplitMaster;
        } else if (index == 1) {
            return ZIKViewRouteDetailTypeRemoveAsSplitDetail;
        } else {
            if ([before.parentViewController isEqual:after.parentViewController]) {//parent is same, but parent was removed from a split
                return ZIKViewRouteDetailTypeParentChangeSplitController;
            } else if (before.parentViewController) {//view controller was removed from a parent in a split
                return ZIKViewRouteDetailTypeRemoveFromParentViewController;
            }
            
            if (!after.parentViewController) {
                return ZIKViewRouteDetailTypeRemoveFromParentViewController;
            } else {
                return ZIKViewRouteDetailTypeCustom;
            }
        }
    }
    
    //check parent
    if ([parentViewControllerBefore isEqual:parentViewControllerAfter]) {
        return ZIKViewRouteDetailTypeCustom;
    }
    if (!parentViewControllerBefore && parentViewControllerAfter) {
        return ZIKViewRouteDetailTypeAddAsChildViewController;
    }
    if (parentViewControllerBefore && parentViewControllerAfter &&
        ![parentViewControllerBefore isEqual:parentViewControllerAfter]) {
        return ZIKViewRouteDetailTypeChangeParentViewController;
    }
    
    return ZIKViewRouteDetailTypeCustom;
}

+ (NSString *)descriptionOfType:(ZIKViewRouteDetailType)routeType {
    NSString *description;
    switch (routeType) {
        case ZIKViewRouteDetailTypePush:
            description = @"Push";
            break;
        case ZIKViewRouteDetailTypePresentModally:
            description = @"PresentModally";
            break;
        case ZIKViewRouteDetailTypePresentAsPopover:
            description = @"PresentAsPopover";
            break;
        case ZIKViewRouteDetailTypeAddAsChildViewController:
            description = @"AddAsChildViewController";
            break;
        case ZIKViewRouteDetailTypeChangeParentViewController:
            description = @"ChangeParentViewController";
            break;
        case ZIKViewRouteDetailTypeRemoveFromParentViewController:
            description = @"RemoveFromParentViewController";
            break;
        case ZIKViewRouteDetailTypeChangeNavigationController:
            description = @"ChangeNavigationController";
            break;
        case ZIKViewRouteDetailTypeParentPushed:
            description = @"ParentPushed";
            break;
        case ZIKViewRouteDetailTypeParentChangeNavigationController:
            description = @"ParentChangeNavigationController";
            break;
        case ZIKViewRouteDetailTypeChangeOrderInNavigationStack:
            description = @"ChangeOrderInNavigationStack";
            break;
        case ZIKViewRouteDetailTypeNavigationPopOthers:
            description = @"NavigationPopOthers";
            break;
        case ZIKViewRouteDetailTypeNavigationPushOthers:
            description = @"NavigationPushOthers";
            break;
        case ZIKViewRouteDetailTypeRemoveFromNavigationStack:
            description = @"RemoveFromNavigationStack";
            break;
        case ZIKViewRouteDetailTypeDismissed:
            description = @"Dismissed";
            break;
        case ZIKViewRouteDetailTypeRemoveAsSplitMaster:
            description = @"RemoveAsSplitMaster";
            break;
        case ZIKViewRouteDetailTypeRemoveAsSplitDetail:
            description = @"RemoveAsSplitDetail";
            break;
        case ZIKViewRouteDetailTypeBecomeSplitMaster:
            description = @"BecomeSplitMaster";
            break;
        case ZIKViewRouteDetailTypeBecomeSplitDetail:
            description = @"BecomeSplitDetail";
            break;
        case ZIKViewRouteDetailTypeParentChangeSplitController:
            description = @"ParentChangeSplitController";
            break;
        case ZIKViewRouteDetailTypeCustom:
            description = @"Custom";
            break;
    }
    return description;
}

- (BOOL)isEqual:(id)object {
    if (![object isMemberOfClass:[self class]]) {
        return NO;
    }
    ZIKPresentationState *other = object;
    
    if (![self.viewController isEqual:other.viewController]) {
        return NO;
    }
    
    if (self.presentingViewController || other.presentingViewController) {
        if (![self.presentingViewController isEqual:other.presentingViewController]) {
            return NO;
        }
    }
    
    if (self.isModalPresentationPopover != other.isModalPresentationPopover) {
        return NO;
    }
    
    if (self.navigationController || other.navigationController) {
        if (![self.navigationController isEqual:other.navigationController]) {
            return NO;
        }
        if (![self.navigationViewControllers isEqual:other.navigationViewControllers]) {
            return NO;
        }
        if (self.navigationControllerState || other.navigationControllerState) {
            if (![self.navigationControllerState isEqual:other.navigationControllerState]) {
                return NO;
            }
        }
    }
    
    if (self.splitController || other.splitController) {
        if (![self.splitController isEqual:other.splitController]) {
            return NO;
        }
        if (![self.splitViewControllers isEqual:other.splitViewControllers]) {
            return NO;
        }
    }
    
    if (self.parentViewController || other.parentViewController) {
        if (![self.parentViewController isEqual:other.parentViewController]) {
            return NO;
        }
        
    }
    
    if (!self.isViewLoaded && other.isViewLoaded) {
        return NO;
    }
    if (self.isViewLoaded && !other.isViewLoaded) {
        return NO;
    }
    if (self.isViewLoaded != other.isViewLoaded) {
        return NO;
    }
    
    return YES;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"viewController:%@",self.viewController];
    if (self.presentingViewController) {
        [description appendFormat:@", presentingViewController:%@, isModalPresentationPopover:%@",self.presentingViewController,@(self.isModalPresentationPopover)];
    }
    if (self.presentingViewController) {
        [description appendFormat:@", presentingViewController:%@",self.presentingViewController];
    }
    if (self.navigationController) {
        [description appendFormat:@", navigationController:%@, navigationViewControllers:%@, navigationControllerState:(%@)",self.navigationController,self.navigationViewControllers, self.navigationControllerState];
    }
    if (self.splitController) {
        [description appendFormat:@", splitController:%@, splitViewControllers:%@",self.splitController, self.splitController];
    }
    if (self.parentViewController) {
        [description appendFormat:@", parentViewController:%@",self.parentViewController];
    }
    [description appendFormat:@", isViewLoaded:%@",@(self.isViewLoaded)];
    return description;
}

@end
#endif
