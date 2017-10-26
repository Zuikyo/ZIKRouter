//
//  ZIKRouteConfiguration.m
//  ZIKRouter
//
//  Created by zuik on 2017/10/13.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKRouteConfiguration.h"
#import <objc/runtime.h>

@interface ZIKRouteConfiguration ()
@property (nonatomic, copy, nullable) ZIKRouteErrorHandler performerErrorHandler;
@property (nonatomic, copy, nullable) void(^performerSuccessHandler)(void);
@end

@implementation ZIKRouteConfiguration

- (instancetype)init {
    if (self = [super init]) {
        NSAssert(class_conformsToProtocol([self class], @protocol(NSCopying)) || [NSStringFromClass([self class]) containsString:@"."], @"configuration must conforms to NSCopying, because it will be deep copied when router is initialized.");
        
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
