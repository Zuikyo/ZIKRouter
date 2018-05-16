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
@import ZIKRouter.Internal;
#import "TestConfig.h"

DeclareRoutableView(BSubview, BSubviewRouter)
@implementation BSubviewRouter

+ (void)registerRoutableDestination {
    [self registerView:[BSubview class]];
#if !TEST_BLOCK_ROUTE
    [self registerViewProtocol:ZIKRoutable(BSubviewInput)];
#endif
}

- (BOOL)destinationFromExternalPrepared:(BSubview *)destination {
    if (destination.title == nil) {
        return NO;
    }
    return YES;
}

- (id)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    BSubview *destination = [[BSubview alloc] init];
    destination.backgroundColor = [UIColor yellowColor];
    return destination;
}

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskViewDefault;
}

@end
