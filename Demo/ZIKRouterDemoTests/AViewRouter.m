//
//  AViewRouter.m
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/11.
//  Copyright © 2018年 zuik. All rights reserved.
//

#import "AViewRouter.h"
@import ZIKRouter.Internal;

DeclareRoutableView(AViewController, TestAViewRouter)

@implementation AViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[AViewController class]];
    [self registerViewProtocol:ZIKRoutableProtocol(AViewInput)];
}

- (id)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    AViewController *destination = [[AViewController alloc] init];
    return destination;
}

@end
