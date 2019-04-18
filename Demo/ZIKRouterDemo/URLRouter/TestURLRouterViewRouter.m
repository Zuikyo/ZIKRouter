//
//  TestURLRouterViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2018/5/3.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "TestURLRouterViewRouter.h"
#import "TestURLRouterViewController.h"

DeclareRoutableView(TestURLRouterViewController, TestURLRouterViewRouter)

@implementation TestURLRouterViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestURLRouterViewController class]];
    [self registerIdentifier:@"testURLRouter"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    TestURLRouterViewController *destination = [[TestURLRouterViewController alloc] init];
    destination.title = @"Test URL Router";
    return destination;
}

@end
