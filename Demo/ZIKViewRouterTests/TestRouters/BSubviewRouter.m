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

DeclareRoutableView(BSubview, BSubviewRouter)
@implementation BSubviewRouter

+ (void)registerRoutableDestination {
    [self registerView:[BSubview class]];
    [self registerViewProtocol:ZIKRoutableProtocol(BSubviewInput)];
}

- (id)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    BSubview *destination = [[BSubview alloc] init];
    destination.backgroundColor = [UIColor yellowColor];
    return destination;
}

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskUIViewDefault;
}

@end
