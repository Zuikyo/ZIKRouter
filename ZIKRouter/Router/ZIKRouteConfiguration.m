//
//  ZIKRouteConfiguration.m
//  ZIKRouter
//
//  Created by zuik on 2017/10/13.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouteConfiguration.h"
#import <objc/runtime.h>
#import "ZIKRouterRuntime.h"

@interface ZIKRouteConfiguration ()
@property (nonatomic, copy, nullable) ZIKRouteErrorHandler performerErrorHandler;
@property (nonatomic, copy, nullable) void(^performerSuccessHandler)(void);
@end

@implementation ZIKRouteConfiguration

- (instancetype)init {
    if (self = [super init]) {
        NSAssert1(ZIKRouter_classSelfImplementingMethod([self class], @selector(copyWithZone:), false), @"configuration (%@) must override -copyWithZone:, because it will be deep copied when router is initialized.",[self class]);
        
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    ZIKRouteConfiguration *config = [[self class] new];
    config.errorHandler = self.errorHandler;
    config.successHandler = self.successHandler;
    config.performerErrorHandler = self.performerErrorHandler;
    config.performerSuccessHandler = self.performerSuccessHandler;
    config.stateNotifier = [self.stateNotifier copy];
    return config;
}

@end

@implementation ZIKPerformRouteConfiguration

- (id)copyWithZone:(nullable NSZone *)zone {
    ZIKPerformRouteConfiguration *config = [super copyWithZone:zone];
    config.prepareDestination = self.prepareDestination;
    config.routeCompletion = self.routeCompletion;
    return config;
}

@end

@implementation ZIKRemoveRouteConfiguration

- (id)copyWithZone:(nullable NSZone *)zone {
    ZIKRemoveRouteConfiguration *config = [super copyWithZone:zone];
    config.prepareDestination = self.prepareDestination;
    return config;
}

@end
