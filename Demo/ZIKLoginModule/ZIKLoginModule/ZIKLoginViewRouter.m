
//
//  ZIKLoginViewRouter.m
//  ZIKLoginModule
//
//  Created by zuik on 2018/5/25.
//Copyright © 2018 duoyi. All rights reserved.
//

#import "ZIKLoginViewRouter.h"
@import ZIKRouter.Internal;
#import "ZIKLoginViewController.h"
#import "ZIKLoginViewControllerInternal.h"
#import "ZIKLoginViewInput.h"

DeclareRoutableView(ZIKLoginViewController, ZIKLoginViewRouter)

@interface ZIKLoginViewRouter ()

@end

@implementation ZIKLoginViewRouter

+ (void)registerRoutableDestination {
    [self registerExclusiveView:[ZIKLoginViewController class]];
    [self registerViewProtocol:ZIKRoutable(ZIKLoginViewInput)];
    [self registerIdentifier:@"loginView"];
}

- (nullable ZIKLoginViewController *)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    // Instantiate destination with configuration. Return nil if configuration is invalid.
    ZIKLoginViewController *destination = [[ZIKLoginViewController alloc] init];
    return destination;
}

- (void)prepareDestination:(ZIKLoginViewController *)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    // Prepare destination
    destination.router = self;
}

@end
