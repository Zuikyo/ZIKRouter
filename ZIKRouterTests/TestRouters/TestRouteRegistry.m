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

#import "AViewRouter.h"
#import "AViewInput.h"
#import "AViewController.h"
#import "BSubviewRouter.h"
#import "BSubviewInput.h"
#import "BSubview.h"
@import ZIKRouter.Internal;

@implementation TestRouteRegistry

#if !AUTO_REGISTER_ROUTERS

+ (void)load {
    ZIKRouteRegistry.autoRegister = NO;
    [AServiceRouter registerRoutableDestination];
    
    {
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
        .registerDestinationProtocol(ZIKRoutableProtocol(AServiceInput))
#endif
        .prepareDestination(^(id<AServiceInput> destination, ZIKPerformRouteConfig *config, ZIKServiceRouter *router) {
            
        })
        .didFinishPrepareDestination(^(id<AServiceInput> destination, ZIKPerformRouteConfig *config, ZIKServiceRouter *router) {
            
        });
    }
    
    [AViewRouter registerRoutableDestination];
    {
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
        .registerDestinationProtocol(ZIKRoutableProtocol(AViewInput))
#endif
        .prepareDestination(^(id<AViewInput> destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
            
        })
        .didFinishPrepareDestination(^(id<AViewInput> destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
            
        });
    }
    
    [BSubviewRouter registerRoutableDestination];
    {
        ZIKDestinationViewRoute(id<BSubviewInput>) *route;
        route = [ZIKDestinationViewRoute(id<BSubviewInput>)
                 makeRouteWithDestination:[BSubview class]
                 makeDestination:^id<BSubviewInput> _Nullable(ZIKViewRouteConfig * _Nonnull config, ZIKRouter * _Nonnull router) {
                     if (TestConfig.routeShouldFail) {
                         return nil;
                     }
                     return [[BSubview alloc] init];
                 }];
        route.name = @"Route for AViewController<AViewInput>";
        route
#if TEST_BLOCK_ROUTE
        .registerDestinationProtocol(ZIKRoutableProtocol(BSubviewInput))
#endif
        .prepareDestination(^(id<BSubviewInput> destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
            
        })
        .didFinishPrepareDestination(^(id<BSubviewInput> destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
            
        });
    }
    
    [ZIKRouteRegistry registrationFinished];
}

#endif

@end
