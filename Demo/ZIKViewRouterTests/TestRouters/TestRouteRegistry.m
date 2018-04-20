//
//  TestRouteRegistry.m
//  ZIKViewRouterTests
//
//  Created by zuik on 2018/4/18.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "TestRouteRegistry.h"
#import "SourceViewRouter.h"
@import ZIKRouter.Internal;
#import "TestConfig.h"

#import "AViewRouter.h"
#import "AViewInput.h"
#import "AViewController.h"
#import "AViewModuleInput.h"
#import "AViewModuleRouter.h"

#import "BSubviewRouter.h"
#import "BSubviewInput.h"
#import "BSubview.h"
#import "BSubviewModuleInput.h"
#import "BSubviewModuleRouter.h"

@implementation TestRouteRegistry

#if !AUTO_REGISTER_ROUTERS

+ (void)load {
    [self registerRoutes];
}

#endif

+ (void)registerRoutes {
    ZIKRouteRegistry.autoRegister = NO;
    
    [SourceViewRouter registerRoutableDestination];
    
    [self registerViewRoute];
    [self registerViewModuleRoute];
    [self registerSubviewRoute];
    [self registerSubviewModuleRoute];
}

+ (void)registerViewRoute {
    [AViewRouter registerRoutableDestination];
    
    ZIKDestinationViewRoute(id<AViewInput>) *route;
    route = [ZIKDestinationViewRoute(id<AViewInput>)
             makeRouteWithDestination:[AViewController class]
             makeDestination:^id<AViewInput> _Nullable(ZIKViewRouteConfig * _Nonnull config, ZIKRouter * _Nonnull router) {
                 return [[AViewController alloc] init];
             }];
    route.name = @"Route for AViewController<AViewInput>";
    route
#if TEST_BLOCK_ROUTE
    .registerDestinationProtocol(ZIKRoutableProtocol(AViewInput))
#endif
    .makeSupportedRouteTypes(^ZIKBlockViewRouteTypeMask{
        return ZIKBlockViewRouteTypeMaskUIViewControllerDefault | ZIKBlockViewRouteTypeMaskCustom;
    })
    .prepareDestination(^(id<AViewInput> destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    })
    .didFinishPrepareDestination(^(id<AViewInput> destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    })
    .canPerformCustomRoute(^BOOL(ZIKViewRouter * _Nonnull router) {
        return YES;
    })
    .performCustomRoute(^(AViewController *destination, UIViewController * _Nullable source, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        [router beginPerformRoute];
        if (source == nil || [source isKindOfClass:[UIViewController class]] == NO) {
            [router endPerformRouteWithError:[ZIKViewRouter viewRouteErrorWithCode:ZIKViewRouteErrorInvalidSource localizedDescription:@"Source is invalid"]];
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
            [router endPerformRouteWithSuccess];
        }];
    })
    .canRemoveCustomRoute(^BOOL(ZIKViewRouter * _Nonnull router) {
        return [router _canRemoveFromParentViewController];
    })
    .removeCustomRoute(^(AViewController *destination, UIViewController *_Nullable source, ZIKViewRemoveConfiguration *removeConfig, ZIKViewRouteConfiguration *config, ZIKViewRouter *router) {
        [router beginRemoveRouteFromSource:source];
        if (source == nil) {
            [router endRemoveRouteWithError:[ZIKViewRouter viewRouteErrorWithCode:ZIKViewRouteErrorInvalidSource localizedDescription:@"Source is dealloced"]];
            return;
        }
        
        [destination willMoveToParentViewController:nil];
        destination.view.transform = CGAffineTransformIdentity;
        [UIView animateWithDuration:0.5 animations:^{
            destination.view.transform = CGAffineTransformMakeScale(0.1, 0.1);
        } completion:^(BOOL finished) {
            [destination.view removeFromSuperview];
            [destination removeFromParentViewController];
            [router endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
        }];
    });
}

+ (void)registerViewModuleRoute {
    [AViewModuleRouter registerRoutableDestination];
    
    ZIKModuleViewRoute(AViewModuleInput) *route;
    route = [ZIKModuleViewRoute(AViewModuleInput)
             makeRouteWithDestination:[AViewController class]
             makeDestination:^id _Nullable(ZIKViewRouteConfig<AViewModuleInput> * _Nonnull config, ZIKRouter * _Nonnull router) {
                 AViewController *destination = [[AViewController alloc] init];
                 destination.title = config.title;
                 return destination;
             }];
    route.name = @"Route for AViewModuleInput module (AViewController)";
    route
#if TEST_BLOCK_ROUTE
    .registerModuleProtocol(ZIKRoutableProtocol(AViewModuleInput))
#endif
    .makeSupportedRouteTypes(^ZIKBlockViewRouteTypeMask{
        return ZIKBlockViewRouteTypeMaskUIViewControllerDefault | ZIKBlockViewRouteTypeMaskCustom;
    })
    .makeDefaultConfiguration(^ZIKViewRouteConfig<AViewModuleInput> * _Nonnull{
        return [[AViewModuleConfiguration alloc] init];
    })
    .prepareDestination(^(id destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    })
    .didFinishPrepareDestination(^(id destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    })
    .canPerformCustomRoute(^BOOL(ZIKViewRouter * _Nonnull router) {
        return YES;
    })
    .performCustomRoute(^(AViewController *destination, UIViewController * _Nullable source, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        [router beginPerformRoute];
        if (source == nil || [source isKindOfClass:[UIViewController class]] == NO) {
            [router endPerformRouteWithError:[ZIKViewRouter viewRouteErrorWithCode:ZIKViewRouteErrorInvalidSource localizedDescription:@"Source is invalid"]];
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
            [router endPerformRouteWithSuccess];
        }];
    })
    .canRemoveCustomRoute(^BOOL(ZIKViewRouter * _Nonnull router) {
        return [router _canRemoveFromParentViewController];
    })
    .removeCustomRoute(^(AViewController *destination, UIViewController *_Nullable source, ZIKViewRemoveConfiguration *removeConfig, ZIKViewRouteConfiguration *config, ZIKViewRouter *router) {
        [router beginRemoveRouteFromSource:source];
        if (source == nil) {
            [router endRemoveRouteWithError:[ZIKViewRouter viewRouteErrorWithCode:ZIKViewRouteErrorInvalidSource localizedDescription:@"Source is dealloced"]];
            return;
        }
        
        [destination willMoveToParentViewController:nil];
        destination.view.transform = CGAffineTransformIdentity;
        [UIView animateWithDuration:0.5 animations:^{
            destination.view.transform = CGAffineTransformMakeScale(0.1, 0.1);
        } completion:^(BOOL finished) {
            [destination.view removeFromSuperview];
            [destination removeFromParentViewController];
            [router endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
        }];
    });;
}

+ (void)registerSubviewRoute {
    [BSubviewRouter registerRoutableDestination];
    
    ZIKDestinationViewRoute(id<BSubviewInput>) *route;
    route = [ZIKDestinationViewRoute(id<BSubviewInput>)
             makeRouteWithDestination:[BSubview class]
             makeDestination:^id<BSubviewInput> _Nullable(ZIKViewRouteConfig * _Nonnull config, ZIKRouter * _Nonnull router) {
                 return [[BSubview alloc] init];
             }];
    route.name = @"Route for BSubview<BSubviewInput>";
    route
#if TEST_BLOCK_ROUTE
    .registerDestinationProtocol(ZIKRoutableProtocol(BSubviewInput))
#endif
    .makeSupportedRouteTypes(^ZIKBlockViewRouteTypeMask{
        return ZIKBlockViewRouteTypeMaskUIViewDefault | ZIKBlockViewRouteTypeMaskCustom;
    })
    .prepareDestination(^(id<BSubviewInput> destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    })
    .didFinishPrepareDestination(^(id<BSubviewInput> destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    });
}

+ (void)registerSubviewModuleRoute {
    [BSubviewModuleRouter registerRoutableDestination];
    
    ZIKModuleViewRoute(BSubviewModuleInput) *route;
    route = [ZIKModuleViewRoute(BSubviewModuleInput)
             makeRouteWithDestination:[BSubview class]
             makeDestination:^id _Nullable(ZIKViewRouteConfig<BSubviewModuleInput> * _Nonnull config, ZIKRouter * _Nonnull router) {
                 BSubview *destination = [[BSubview alloc] init];
                 destination.title = config.title;
                 return destination;
             }];
    route.name = @"Route for BSubviewModuleInput module (BSubview)";
    route
#if TEST_BLOCK_ROUTE
    .registerModuleProtocol(ZIKRoutableProtocol(BSubviewModuleInput))
#endif
    .makeSupportedRouteTypes(^ZIKBlockViewRouteTypeMask{
        return ZIKBlockViewRouteTypeMaskUIViewDefault | ZIKBlockViewRouteTypeMaskCustom;
    })
    .makeDefaultConfiguration(^ZIKViewRouteConfig<BSubviewModuleInput> * _Nonnull{
        return [[BSubviewModuleConfiguration alloc] init];
    })
    .prepareDestination(^(id destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    })
    .didFinishPrepareDestination(^(id destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    });
}

@end
