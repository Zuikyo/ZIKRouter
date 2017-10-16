//
//  ZIKTestGetDestinationViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestGetDestinationViewRouter.h"
#import "ZIKTestGetDestinationViewController.h"

@interface ZIKTestGetDestinationViewController (ZIKTestGetDestinationViewRouter) <ZIKRoutableView>
@end
@implementation ZIKTestGetDestinationViewController (ZIKTestGetDestinationViewRouter)
@end

@implementation ZIKTestGetDestinationViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[ZIKTestGetDestinationViewController class]];
}

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ZIKTestGetDestinationViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testGetDestination"];;
    destination.title = @"Test GetDestination";
    return destination;
}

@end
