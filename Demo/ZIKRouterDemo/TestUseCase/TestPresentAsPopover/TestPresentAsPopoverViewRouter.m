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
    [self registerIdentifier:@"testPresentAsPopover"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestPresentAsPopoverViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testPresentAsPopover"];
    destination.title = @"Test PresentAsPopover";
    return destination;
}

@end
