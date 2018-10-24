//
//  AViewModuleRouter.m
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/20.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "AViewModuleRouter.h"
#import "AViewController.h"
@import ZIKRouter.Internal;
#import "TestConfig.h"

@interface AViewModuleConfiguration()
@property (nonatomic, copy, nullable) void(^makeDestinationCompletion)(id<AViewInput>);
@end


@implementation AViewModuleConfiguration

- (id)copyWithZone:(NSZone *)zone {
    AViewModuleConfiguration *config = [super copyWithZone:zone];
    config.title = self.title;
    self.makeDestinationCompletion = self.makeDestinationCompletion;
    return config;
}

- (void)makeDestinationCompletion:(void(^)(id<AViewInput> destination))block; {
    self.makeDestinationCompletion = block;
}

@end

DeclareRoutableView(AViewController, AViewModuleRouter)
@implementation AViewModuleRouter

+ (void)registerRoutableDestination {
    [self registerView:[AViewController class]];
#if !TEST_BLOCK_ROUTE
    [self registerModuleProtocol:ZIKRoutable(AViewModuleInput)];
#endif
}

- (AViewController *)destinationWithConfiguration:(AViewModuleConfiguration *)configuration {
    if (TestConfig.routeShouldFail) {
        return nil;
    }
    AViewController *destination = [[AViewController alloc] init];
    destination.title = configuration.title;
    destination.router = self;
    return destination;
}

- (void)didFinishPrepareDestination:(AViewController *)destination configuration:(AViewModuleConfiguration *)configuration {
    if (configuration.makeDestinationCompletion) {
        configuration.makeDestinationCompletion(destination);
        configuration.makeDestinationCompletion = nil;
    }
}

+ (AViewModuleConfiguration *)defaultRouteConfiguration {
    return [[AViewModuleConfiguration alloc] init];
}

@end
