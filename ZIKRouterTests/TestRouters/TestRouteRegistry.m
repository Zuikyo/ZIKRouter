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
@import ZIKRouter.Internal;

@implementation TestRouteRegistry

#if !AUTO_REGISTER_ROUTERS

+ (void)load {
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
    .registerDestinationProtocol(ZIKRoutableProtocol(AServiceInput))
#endif
    .prepareDestination(^(id<AServiceInput> destination, ZIKPerformRouteConfig *config, ZIKServiceRouter *router) {
        
    })
    .didFinishPrepareDestination(^(id<AServiceInput> destination, ZIKPerformRouteConfig *config, ZIKServiceRouter *router) {
        
    });
}

#endif

@end
