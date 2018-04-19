//
//  TestRouteRegistry.m
//  ZIKViewRouterTests
//
//  Created by zuik on 2018/4/18.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "TestRouteRegistry.h"
#import "SourceViewRouter.h"
#import "AViewRouter.h"
#import "AViewInput.h"
#import "BSubviewRouter.h"
@import ZIKRouter.Internal;
#import "TestConfig.h"

@implementation TestRouteRegistry

#if !AUTO_REGISTER_ROUTERS

+ (void)load {
    [self registerRoutes];
}

#endif

+ (void)registerRoutes {
    ZIKRouteRegistry.autoRegister = NO;
    
    [AViewRouter registerRoutableDestination];
    [BSubviewRouter registerRoutableDestination];
    [SourceViewRouter registerRoutableDestination];
    
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
}

@end
