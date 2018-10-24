//
//  AServiceRouter.m
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/18.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "AServiceRouter.h"
#import "AServiceInput.h"
#import "AService.h"
@import ZIKRouter.Internal;
#import "TestConfig.h"

DeclareRoutableService(AService, AServiceRouter)
@implementation AServiceRouter

+ (void)registerRoutableDestination {
    [self registerService:[AService class]];
#if !TEST_BLOCK_ROUTE
    [self registerServiceProtocol:ZIKRoutable(AServiceInput)];
#endif
}

- (AService *)destinationWithConfiguration:(ZIKPerformRouteConfiguration *)configuration {
    if (TestConfig.routeShouldFail) {
        return nil;
    }
    AService *destination = [[AService alloc] init];
    destination.router = self;
    return destination;
}

@end
