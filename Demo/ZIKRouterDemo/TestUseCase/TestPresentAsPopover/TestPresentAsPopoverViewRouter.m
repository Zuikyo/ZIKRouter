//
//  TestPresentAsPopoverViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestPresentAsPopoverViewRouter.h"
#import "TestPresentAsPopoverViewController.h"

@interface TestPresentAsPopoverViewController (TestPresentAsPopoverViewRouter) <ZIKRoutableView>
@end
@implementation TestPresentAsPopoverViewController (TestPresentAsPopoverViewRouter)
@end

@implementation TestPresentAsPopoverViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestPresentAsPopoverViewController class]];
    [self registerIdentifier:@"com.zuik.viewController.testPresentAsPopover"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestPresentAsPopoverViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testPresentAsPopover"];
    NSString *title = @"Test PresentAsPopover";
    if ([configuration.userInfo objectForKey:@"url"]) {
        title = [title stringByAppendingString:@"-fromURL"];
    }
    destination.title = title;
    return destination;
}

@end
