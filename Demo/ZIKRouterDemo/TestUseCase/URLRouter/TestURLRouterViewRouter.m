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
    [self registerIdentifier:@"com.zuik.viewController.testURLRouter"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    TestURLRouterViewController *destination = [[TestURLRouterViewController alloc] init];
    NSString *title = @"Test URL Router";
    if ([configuration.userInfo objectForKey:@"url"]) {
        title = [title stringByAppendingString:@"-fromURL"];
    }
    destination.title = title;
    return destination;
}

@end
