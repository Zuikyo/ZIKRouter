//
//  TestCustomViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestCustomViewRouter.h"
#import "TestCustomViewController.h"

@interface TestCustomViewController (TestCustomViewRouter) <ZIKRoutableView>
@end
@implementation TestCustomViewController (TestCustomViewRouter)
@end

@implementation TestCustomViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestCustomViewController class]];
    [self registerIdentifier:@"com.zuik.viewController.testCustom"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestCustomViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testCustom"];
    NSString *title = @"Test Custom";
    if ([configuration.userInfo objectForKey:@"url"]) {
        title = [title stringByAppendingString:@"-fromURL"];
    }
    destination.title = title;
    return destination;
}

@end
