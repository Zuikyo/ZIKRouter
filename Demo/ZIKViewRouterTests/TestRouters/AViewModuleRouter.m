//
//  AViewModuleRouter.m
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/20.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "AViewModuleRouter.h"
#import "AViewController.h"
@import ZIKRouter.Internal;
#import "TestConfig.h"

@interface AViewModuleConfiguration()
@property (nonatomic, copy, nullable) void(^makeDestinationCompletion)(id<AViewInput>);
@end


@implementation AViewModuleConfiguration

- (id)copyWithZone:(NSZone *)zone {
    AViewModuleConfiguration *config = [super copyWithZone:zone];
    config.title = self.title;
    self.makeDestinationCompletion = self.makeDestinationCompletion;
    return config;
}

- (void)makeDestinationCompletion:(void(^)(id<AViewInput> destination))block; {
    self.makeDestinationCompletion = block;
}

@end

DeclareRoutableView(AViewController, AViewModuleRouter)
@implementation AViewModuleRouter

+ (void)registerRoutableDestination {
    [self registerView:[AViewController class]];
#if !TEST_BLOCK_ROUTE
    [self registerModuleProtocol:ZIKRoutable(AViewModuleInput)];
#endif
}

- (AViewController *)destinationWithConfiguration:(AViewModuleConfiguration *)configuration {
    AViewController *destination = [[AViewController alloc] init];
    destination.title = configuration.title;
    return destination;
}

- (void)didFinishPrepareDestination:(AViewController *)destination configuration:(AViewModuleConfiguration *)configuration {
    if (configuration.makeDestinationCompletion) {
        configuration.makeDestinationCompletion(destination);
        configuration.makeDestinationCompletion = nil;
    }
}

+ (AViewModuleConfiguration *)defaultRouteConfiguration {
    return [[AViewModuleConfiguration alloc] init];
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
