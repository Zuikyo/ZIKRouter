//
//  ZIKTestGetDestinationViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestGetDestinationViewRouter.h"
#import "TestGetDestinationViewController.h"

@interface TestGetDestinationViewController (ZIKTestGetDestinationViewRouter) <ZIKRoutableView>
@end
@implementation TestGetDestinationViewController (ZIKTestGetDestinationViewRouter)
@end

@implementation ZIKTestGetDestinationViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestGetDestinationViewController class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestGetDestinationViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testGetDestination"];;
    destination.title = @"Test GetDestination";
    return destination;
}

@end
