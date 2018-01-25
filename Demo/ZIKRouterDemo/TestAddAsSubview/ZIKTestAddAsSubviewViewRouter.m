//
//  ZIKTestAddAsSubviewViewRouter.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestAddAsSubviewViewRouter.h"
#import "TestAddAsSubviewViewController.h"

@interface TestAddAsSubviewViewController (ZIKTestAddAsSubviewViewRouter) <ZIKRoutableView>
@end
@implementation TestAddAsSubviewViewController (ZIKTestAddAsSubviewViewRouter)
@end

@implementation ZIKTestAddAsSubviewViewRouter

+ (void)registerRoutableDestination {
    [self registerView:[TestAddAsSubviewViewController class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TestAddAsSubviewViewController *destination = [sb instantiateViewControllerWithIdentifier:@"testAddAsSubview"];;
    destination.title = @"Test AddAsSubview";
    return destination;
}

@end
