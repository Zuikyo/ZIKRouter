//
//  TestRouteRegistry.m
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/18.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "TestRouteRegistry.h"
#import "TestConfig.h"
#import "AServiceRouter.h"
#import "AServiceInput.h"
#import "AService.h"
#import "AServiceModuleRouter.h"
#import "AServiceModuleInput.h"

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
@import ZIKRouter.Internal;

@implementation TestRouteRegistry

+ (void)load {
    ZIKRouteRegistry.autoRegister = NO;
    [self registerServiceRouter];
    [self registerServiceModuleRouter];
    [self registerViewRouter];
    [self registerViewModuleRouter];
    [self registerSubViewRouter];
    [self registerSubviewModuleRouter];
    [ZIKRouteRegistry notifyRegistrationFinished];
}

+ (void)registerServiceRouter {
    [AServiceRouter registerRoutableDestination];
    
    ZIKDestinationServiceRoute(id<AServiceInput>) *route;
    route = [ZIKDestinationServiceRoute(id<AServiceInput>)
             makeRouteWithDestination:[AService class]
             makeDestination:^id<AServiceInput> _Nullable(ZIKPerformRouteConfig * _Nonnull config, ZIKRouter * _Nonnull router) {
                 if (TestConfig.routeShouldFail) {
                     return nil;
                 }
                 return [[AService alloc] init];
             }];
    route.name = @"Route for AService<AServiceInput>";
    route
#if TEST_BLOCK_ROUTE
    .registerDestinationProtocol(ZIKRoutable(AServiceInput))
#endif
    .prepareDestination(^(id<AServiceInput> destination, ZIKPerformRouteConfig *config, ZIKServiceRouter *router) {
        
    })
    .didFinishPrepareDestination(^(id<AServiceInput> destination, ZIKPerformRouteConfig *config, ZIKServiceRouter *router) {
        
    });
}

+ (void)registerServiceModuleRouter {
    [AServiceModuleRouter registerRoutableDestination];
    
    ZIKModuleServiceRoute(AServiceModuleInput) *route;
    route = [ZIKModuleServiceRoute(AServiceModuleInput)
             makeRouteWithDestination:[AService class]
             makeDestination:^id _Nullable(ZIKPerformRouteConfig<AServiceModuleInput> * _Nonnull config, ZIKRouter * _Nonnull router) {
                 if (TestConfig.routeShouldFail) {
                     return nil;
                 }
                 AService *destination = [[AService alloc] init];
                 destination.title = config.title;
                 return destination;
             }];
    route.name = @"Route for AServiceModuleInput module (AService)";
    route
#if TEST_BLOCK_ROUTE
    .registerModuleProtocol(ZIKRoutable(AServiceModuleInput))
#endif
    .makeDefaultConfiguration(^ZIKPerformRouteConfig<AServiceModuleInput> * _Nonnull{
        return [[AServiceModuleConfiguration alloc] init];
    })
    .prepareDestination(^(id<AServiceInput> destination, ZIKPerformRouteConfig *config, ZIKServiceRouter *router) {
        
    })
    .didFinishPrepareDestination(^(id<AServiceInput> destination, ZIKPerformRouteConfig *config, ZIKServiceRouter *router) {
        
    });
}

+ (void)registerViewRouter {
    [AViewRouter registerRoutableDestination];
    
    ZIKDestinationViewRoute(id<AViewInput>) *route;
    route = [ZIKDestinationViewRoute(id<AViewInput>)
             makeRouteWithDestination:[AViewController class]
             makeDestination:^id<AViewInput> _Nullable(ZIKViewRouteConfig * _Nonnull config, ZIKRouter * _Nonnull router) {
                 if (TestConfig.routeShouldFail) {
                     return nil;
                 }
                 return [[AViewController alloc] init];
             }];
    route.name = @"Route for AViewController<AViewInput>";
    route
#if TEST_BLOCK_ROUTE
    .registerDestinationProtocol(ZIKRoutable(AViewInput))
#endif
    .makeSupportedRouteTypes(^ZIKBlockViewRouteTypeMask{
        return ZIKBlockViewRouteTypeMaskViewControllerDefault | ZIKBlockViewRouteTypeMaskCustom;
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
    })
    .prepareDestination(^(id<AViewInput> destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    })
    .didFinishPrepareDestination(^(id<AViewInput> destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    });
}

+ (void)registerViewModuleRouter {
    [AViewModuleRouter registerRoutableDestination];
    
    ZIKModuleViewRoute(AViewModuleInput) *route;
    route = [ZIKModuleViewRoute(AViewModuleInput)
             makeRouteWithDestination:[AViewController class]
             makeDestination:^id _Nullable(ZIKViewRouteConfig<AViewModuleInput> * _Nonnull config, ZIKRouter * _Nonnull router) {
                 if (TestConfig.routeShouldFail) {
                     return nil;
                 }
                 AViewController *destination = [[AViewController alloc] init];
                 destination.title = config.title;
                 return destination;
             }];
    route.name = @"Route for AViewModuleInput module (AViewController)";
    route
#if TEST_BLOCK_ROUTE
    .registerModuleProtocol(ZIKRoutable(AViewModuleInput))
#endif
    .makeDefaultConfiguration(^ZIKViewRouteConfig<AViewModuleInput> * _Nonnull{
        return [[AViewModuleConfiguration alloc] init];
    })
    .makeSupportedRouteTypes(^ZIKBlockViewRouteTypeMask{
        return ZIKBlockViewRouteTypeMaskViewControllerDefault | ZIKBlockViewRouteTypeMaskCustom;
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
    })
    .prepareDestination(^(id destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    })
    .didFinishPrepareDestination(^(id destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    });
}

+ (void)registerSubViewRouter {
    [BSubviewRouter registerRoutableDestination];
    
    ZIKDestinationViewRoute(id<BSubviewInput>) *route;
    route = [ZIKDestinationViewRoute(id<BSubviewInput>)
             makeRouteWithDestination:[BSubview class]
             makeDestination:^id<BSubviewInput> _Nullable(ZIKViewRouteConfig * _Nonnull config, ZIKRouter * _Nonnull router) {
                 if (TestConfig.routeShouldFail) {
                     return nil;
                 }
                 return [[BSubview alloc] init];
             }];
    route.name = @"Route for BSubview<BSubviewInput>";
    route
#if TEST_BLOCK_ROUTE
    .registerDestinationProtocol(ZIKRoutable(BSubviewInput))
#endif
    .makeSupportedRouteTypes(^ZIKBlockViewRouteTypeMask{
        return ZIKBlockViewRouteTypeMaskViewDefault | ZIKBlockViewRouteTypeMaskCustom;
    })
    .canPerformCustomRoute(^BOOL(ZIKViewRouter * _Nonnull router) {
        return YES;
    })
    .performCustomRoute(^(BSubview *destination, UIView *_Nullable source, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        [router beginPerformRoute];
        if ([source isKindOfClass:[UIView class]] == NO) {
            [router endPerformRouteWithError:[ZIKViewRouter viewRouteErrorWithCode:ZIKViewRouteErrorInvalidSource localizedDescriptionFormat:@"Invalid source: %@", source]];
            return;
        }
        [source addSubview:destination];
        [router endPerformRouteWithSuccess];
    })
    .canRemoveCustomRoute(^BOOL(ZIKViewRouter * _Nonnull router) {
        return [router _canRemoveFromSuperview];
    })
    .removeCustomRoute(^(BSubview *destination, UIView *_Nullable source, ZIKViewRemoveConfiguration *removeConfig, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        [router beginRemoveRouteFromSource:source];
        if ([source isKindOfClass:[UIView class]] == NO) {
            [router endRemoveRouteWithError:[ZIKViewRouter viewRouteErrorWithCode:ZIKViewRouteErrorInvalidSource localizedDescriptionFormat:@"Invalid source: %@", source]];
            return;
        }
        [destination removeFromSuperview];
        [router endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
    })
    .prepareDestination(^(id<BSubviewInput> destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    })
    .didFinishPrepareDestination(^(id<BSubviewInput> destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    });
}

+ (void)registerSubviewModuleRouter {
    [BSubviewModuleRouter registerRoutableDestination];
    
    ZIKModuleViewRoute(BSubviewModuleInput) *route;
    route = [ZIKModuleViewRoute(BSubviewModuleInput)
             makeRouteWithDestination:[BSubview class]
             makeDestination:^id _Nullable(ZIKViewRouteConfig<BSubviewModuleInput> * _Nonnull config, ZIKRouter * _Nonnull router) {
                 if (TestConfig.routeShouldFail) {
                     return nil;
                 }
                 BSubview *destination = [[BSubview alloc] init];
                 destination.title = config.title;
                 return destination;
             }];
    route.name = @"Route for BSubviewModuleInput module (BSubview)";
    route
#if TEST_BLOCK_ROUTE
    .registerModuleProtocol(ZIKRoutable(BSubviewModuleInput))
#endif
    .makeDefaultConfiguration(^ZIKViewRouteConfig<BSubviewModuleInput> * _Nonnull{
        return [[BSubviewModuleConfiguration alloc] init];
    })
    .makeSupportedRouteTypes(^ZIKBlockViewRouteTypeMask{
        return ZIKBlockViewRouteTypeMaskViewDefault | ZIKBlockViewRouteTypeMaskCustom;
    })
    .canPerformCustomRoute(^BOOL(ZIKViewRouter * _Nonnull router) {
        return YES;
    })
    .performCustomRoute(^(BSubview *destination, UIView *_Nullable source, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        [router beginPerformRoute];
        if ([source isKindOfClass:[UIView class]] == NO) {
            [router endPerformRouteWithError:[ZIKViewRouter viewRouteErrorWithCode:ZIKViewRouteErrorInvalidSource localizedDescriptionFormat:@"Invalid source: %@", source]];
            return;
        }
        [source addSubview:destination];
        [router endPerformRouteWithSuccess];
    })
    .canRemoveCustomRoute(^BOOL(ZIKViewRouter * _Nonnull router) {
        return [router _canRemoveFromSuperview];
    })
    .removeCustomRoute(^(BSubview *destination, UIView *_Nullable source, ZIKViewRemoveConfiguration *removeConfig, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        [router beginRemoveRouteFromSource:source];
        if ([source isKindOfClass:[UIView class]] == NO) {
            [router endRemoveRouteWithError:[ZIKViewRouter viewRouteErrorWithCode:ZIKViewRouteErrorInvalidSource localizedDescriptionFormat:@"Invalid source: %@", source]];
            return;
        }
        [destination removeFromSuperview];
        [router endRemoveRouteWithSuccessOnDestination:destination fromSource:source];
    })
    .prepareDestination(^(id destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    })
    .didFinishPrepareDestination(^(id destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    });
}

@end
