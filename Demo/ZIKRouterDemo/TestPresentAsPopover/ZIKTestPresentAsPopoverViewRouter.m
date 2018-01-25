//
//  ZIKTestPresentAsPopoverViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestPresentAsPopoverViewRouter.h"
#import "TestPresentAsPopoverViewController.h"

@interface TestPresentAsPopoverViewController (ZIKTestPresentAsPopoverViewRouter) <ZIKRoutableView>
@end
@implementation TestPresentAsPopoverViewController (ZIKTestPresentAsPopoverViewRouter)
@end

@implementation ZIKTestPresentAsPopoverViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestPresentAsPopoverViewController class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestPresentAsPopoverViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testPresentAsPopover"];;
    destination.title = @"Test PresentAsPopover";
    return destination;
}

@end
