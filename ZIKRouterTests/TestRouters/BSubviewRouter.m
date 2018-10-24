//
//  BSubviewRouter.m
//  ZIKViewRouterTests
//
//  Created by zuik on 2018/4/18.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "BSubviewRouter.h"
#import "BSubviewInput.h"
#import "BSubview.h"
#import "TestConfig.h"
@import ZIKRouter.Internal;

DeclareRoutableView(BSubview, BSubviewRouter)
@implementation BSubviewRouter

+ (void)registerRoutableDestination {
    [self registerView:[BSubview class]];
#if !TEST_BLOCK_ROUTE
    [self registerViewProtocol:ZIKRoutable(BSubviewInput)];
#endif
}

- (id)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    if (TestConfig.routeShouldFail) {
        return nil;
    }
    BSubview *destination = [[BSubview alloc] init];
    destination.backgroundColor = [UIColor yellowColor];
    destination.router = self;
    return destination;
}

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskViewDefault;
}

@end
