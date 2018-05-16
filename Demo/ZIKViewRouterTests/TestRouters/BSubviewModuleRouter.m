//
//  BSubviewModuleRouter.m
//  ZIKRouterTests
//
//  Created by zuik on 2018/4/20.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "BSubviewModuleRouter.h"
@import ZIKRouter.Internal;
#import "BSubview.h"
#import "TestConfig.h"

@interface BSubviewModuleConfiguration()
@property (nonatomic, copy, nullable) void(^makeDestinationCompletion)(id<BSubviewInput>);
@end


@implementation BSubviewModuleConfiguration

- (id)copyWithZone:(NSZone *)zone {
    BSubviewModuleConfiguration *config = [super copyWithZone:zone];
    config.title = self.title;
    self.makeDestinationCompletion = self.makeDestinationCompletion;
    return config;
}

- (void)makeDestinationCompletion:(void(^)(id<BSubviewInput> destination))block; {
    self.makeDestinationCompletion = block;
}

@end

DeclareRoutableView(BSubview, BSubviewModuleRouter)
@implementation BSubviewModuleRouter

+ (void)registerRoutableDestination {
    [self registerView:[BSubview class]];
#if !TEST_BLOCK_ROUTE
    [self registerModuleProtocol:ZIKRoutable(BSubviewModuleInput)];
#endif
}

- (BOOL)destinationFromExternalPrepared:(BSubview *)destination {
    if (destination.title == nil) {
        return NO;
    }
    return YES;
}

- (BSubview *)destinationWithConfiguration:(BSubviewModuleConfiguration *)configuration {
    BSubview *destination = [[BSubview alloc] init];
    destination.title = configuration.title;
    return destination;
}

- (void)didFinishPrepareDestination:(BSubview *)destination configuration:(BSubviewModuleConfiguration *)configuration {
    if (configuration.makeDestinationCompletion) {
        configuration.makeDestinationCompletion(destination);
        configuration.makeDestinationCompletion = nil;
    }
}

+ (ZIKViewRouteTypeMask)supportedRouteTypes {
    return ZIKViewRouteTypeMaskViewDefault;
}

+ (BSubviewModuleConfiguration *)defaultRouteConfiguration {
    return [[BSubviewModuleConfiguration alloc] init];
}

@end
