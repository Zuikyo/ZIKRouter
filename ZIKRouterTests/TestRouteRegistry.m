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
@import ZIKRouter.Internal;

@implementation TestRouteRegistry

#if !AUTO_REGISTER_ROUTERS

+ (void)load {
    [AServiceRouter registerRoutableDestination];
}

#endif

@end
