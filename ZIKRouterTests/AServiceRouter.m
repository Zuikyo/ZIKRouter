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
    [self registerServiceProtocol:ZIKRoutableProtocol(AServiceInput)];
}

- (AService *)destinationWithConfiguration:(ZIKPerformRouteConfiguration *)configuration {
    if (TestConfig.routeShouldFail) {
        return nil;
    }
    AService *destination = [[AService alloc] init];
    return destination;
}

@end
