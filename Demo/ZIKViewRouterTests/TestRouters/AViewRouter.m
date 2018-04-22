//
//  AViewRouter.m
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/11.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "AViewRouter.h"
@import ZIKRouter.Internal;
#import "TestConfig.h"

DeclareRoutableView(AViewController, TestAViewRouter)

@implementation AViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[AViewController class]];
#if !TEST_BLOCK_ROUTE
    [self registerViewProtocol:ZIKRoutable(AViewInput)];
#endif
}

- (id)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    AViewController *destination = [[AViewController alloc] init];
    return destination;
}

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return [super supportedRouteTypes] | ZIKViewRouteTypeMaskCustom;
}

- (BOOL)canPerformCustomRoute {
    return YES;
}

- (void)performCustomRouteOnDestination:(AViewController *)destination fromSource:(UIViewController *)source configuration:(ZIKViewRouteConfiguration *)configuration {
    [self beginPerformRoute];
    if (source == nil || [source isKindOfClass:[UIViewController class]] == NO) {
        [self endPerformRouteWithError:[[self class] viewRouteErrorWithCode:ZIKViewRouteErrorInvalidSource localizedDescription:@"Source is invalid"]];
        return;
    }
    
    [source addChildViewController:destination];
    destination.view.frame = source.view.frame;
    destination.view.transform = CGAffineTransformMakeScale(0.1, 0.1);
    [UIView animateWithDuration:0.5 animations:^{
        destination.view.backgroundColor = [UIColor redColor];
        [source.view addSubview:destination.view];
        destination.view.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [destination didMoveToParentViewController:source];
        [self endPerformRouteWithSuccess];
    }];
}

- (BOOL)canRemoveCustomRoute {
    return [self _canRemoveFromParentViewController];
}

- (void)removeCustomRouteOnDestination:(AViewController *)destination fromSource:(UIViewController *)source removeConfiguration:(ZIKViewRemoveConfiguration *)removeConfiguration configuration:(ZIKViewRouteConfiguration *)configuration {
    [self beginRemoveRouteFromSource:source];
    if (source == nil) {
        [self endRemoveRouteWithError:[[self class] viewRouteErrorWithCode:ZIKViewRouteErrorInvalidSource localizedDescription:@"Source is dealloced"]];
        return;
    }
    
    [destination willMoveToParentViewController:nil];
    destination.view.transform = CGAffineTransformIdentity;
    [UIView animateWithDuration:0.5 animations:^{
        destination.view.transform = CGAffineTransformMakeScale(0.1, 0.1);
    } completion:^(BOOL finished) {
        [destination.view removeFromSuperview];
        [destination removeFromParentViewController];
        [self endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
    }];
}

@end
