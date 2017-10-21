//
//  ZIKRouteConfiguration.m
//  ZIKRouter
//
//  Created by zuik on 2017/10/13.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKRouteConfiguration.h"
#import <objc/runtime.h>

@implementation ZIKRouteConfiguration

- (instancetype)init {
    if (self = [super init]) {
        NSAssert(class_conformsToProtocol([self class], @protocol(NSCopying)) || [NSStringFromClass([self class]) containsString:@"."], @"configuration must conforms to NSCopying, because it will be deep copied when router is initialized.");
        
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    ZIKRouteConfiguration *config = [[self class] new];
    config.providerErrorHandler = self.providerErrorHandler;
    config.providerSuccessHandler = self.providerSuccessHandler;
    config.performerErrorHandler = self.performerErrorHandler;
    config.performerSuccessHandler = self.performerSuccessHandler;
    config.stateNotifier = [self.stateNotifier copy];
    return config;
}

@end
