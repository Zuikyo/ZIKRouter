//
//  AServiceModuleRouter.m
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/19.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "AServiceModuleRouter.h"
@import ZIKRouter.Internal;
#import "AService.h"
#import "TestConfig.h"

@interface AServiceModuleConfiguration()
@property (nonatomic, copy, nullable) void(^makeDestinationCompletion)(id<AServiceInput>);
@end

@implementation AServiceModuleConfiguration

- (id)copyWithZone:(NSZone *)zone {
    AServiceModuleConfiguration *config = [super copyWithZone:zone];
    config.title = self.title;
    self.makeDestinationCompletion = self.makeDestinationCompletion;
    return config;
}

- (void)makeDestinationCompletion:(void(^)(id<AServiceInput> destination))block; {
    self.makeDestinationCompletion = block;
}

@end

DeclareRoutableService(AService, AServiceModuleRouter)
@implementation AServiceModuleRouter

+ (void)registerRoutableDestination {
    [self registerService:[AService class]];
#if !TEST_BLOCK_ROUTE
    [self registerModuleProtocol:ZIKRoutable(AServiceModuleInput)];
#endif
}

- (AService *)destinationWithConfiguration:(AServiceModuleConfiguration *)configuration {
    if (TestConfig.routeShouldFail) {
        return nil;
    }
    AService *destination = [[AService alloc] init];
    destination.title = configuration.title;
    destination.router = self;
    return destination;
}

- (void)didFinishPrepareDestination:(AService *)destination configuration:(AServiceModuleConfiguration *)configuration {
    if (configuration.makeDestinationCompletion) {
        configuration.makeDestinationCompletion(destination);
        configuration.makeDestinationCompletion = nil;
    }
}

+ (AServiceModuleConfiguration *)defaultRouteConfiguration {
    return [[AServiceModuleConfiguration alloc] init];
}

@end
