//
//  TestMakeDestinationViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestMakeDestinationViewRouter.h"
#import "TestMakeDestinationViewController.h"

@interface TestMakeDestinationViewController (TestMakeDestinationViewRouter) <ZIKRoutableView>
@end
@implementation TestMakeDestinationViewController (TestMakeDestinationViewRouter)
@end

@implementation TestMakeDestinationViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestMakeDestinationViewController class]];
    [self registerIdentifier:@"testMakeDestination"];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestMakeDestinationViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testMakeDestination"];
    destination.title = @"Test MakeDestination";
    return destination;
}

@end
