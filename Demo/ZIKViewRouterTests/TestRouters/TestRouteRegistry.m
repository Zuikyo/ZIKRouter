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
    
    //View router
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
    .prepareDestination(^(id<AViewInput> destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    })
    .didFinishPrepareDestination(^(id<AViewInput> destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
        
    });
    
    //View module router
    [AViewModuleRouter registerRoutableDestination];
    {
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
        .makeDefaultConfiguration(^ZIKViewRouteConfig<AViewModuleInput> * _Nonnull{
            return [[AViewModuleConfiguration alloc] init];
        })
        .prepareDestination(^(id destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
            
        })
        .didFinishPrepareDestination(^(id destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
            
        });
    }
    
    //Subview router
    [BSubviewRouter registerRoutableDestination];
    {
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
        .prepareDestination(^(id<BSubviewInput> destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
            
        })
        .didFinishPrepareDestination(^(id<BSubviewInput> destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
            
        });
    }
    
    //Subview module router
    [BSubviewModuleRouter registerRoutableDestination];
    {
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
        .makeDefaultConfiguration(^ZIKViewRouteConfig<BSubviewModuleInput> * _Nonnull{
            return [[BSubviewModuleConfiguration alloc] init];
        })
        .prepareDestination(^(id destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
            
        })
        .didFinishPrepareDestination(^(id destination, ZIKViewRouteConfig *config, ZIKViewRouter *router) {
            
        });
    }
}

@end
